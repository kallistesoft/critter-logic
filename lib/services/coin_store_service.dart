import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'stats_store.dart';

/// A coin pack sold on the store (a consumable: it can be bought again and again).
class CoinPack {
  const CoinPack(this.productId, this.coins, {this.bonusPercent = 0, this.bestValue = false});

  final String productId;
  final int coins;

  /// Extra coins compared with the smallest pack's rate, shown as "+15%".
  final int bonusPercent;
  final bool bestValue;
}

/// 0.99 / 1.99 / 4.99 CAD in Play Console; bigger packs give more coins per dollar.
const coinPacks = <CoinPack>[
  CoinPack('coins_150', 150),
  CoinPack('coins_350', 350, bonusPercent: 15),
  CoinPack('coins_1000', 1000, bonusPercent: 30, bestValue: true),
];

final coinPackById = {for (final p in coinPacks) p.productId: p};

/// Buys coin packs.
abstract class CoinStoreService extends ChangeNotifier {
  /// Packs the store returned, with their localized prices; empty when the store isn't reachable.
  List<(CoinPack, String price)> get packs;

  Future<void> buy(CoinPack pack);

  /// Dev builds without a store show the packs with sample prices; buying does nothing.
  bool get preview => false;
}

/// Web and tests: nothing to buy.
class NoCoinStore extends CoinStoreService {
  @override
  List<(CoinPack, String)> get packs => const [];

  @override
  Future<void> buy(CoinPack pack) async {}
}

/// Google Play / App Store coin packs. Each purchase is credited once (its purchase id is remembered, so a purchase
/// the store delivers again after a restart doesn't pay twice), then consumed so it can be bought again.
class StoreCoinService extends CoinStoreService {
  StoreCoinService(this._stats, this._prefs, {InAppPurchase? store, AnalyticsService? analytics})
      : _injectedStore = store,
        _analytics = analytics ?? NoAnalytics();

  final StatsStore _stats;
  final SharedPreferences _prefs;
  final InAppPurchase? _injectedStore;

  /// Looked up lazily, so crediting works without the store plugin (tests).
  InAppPurchase get _store => _injectedStore ?? InAppPurchase.instance;
  final AnalyticsService _analytics;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _products = <String, ProductDetails>{};

  static const _creditedKey = 'coinPurchasesCredited';

  /// Sample prices for the dev-build preview (the CAD prices set in Play Console).
  static const _samplePrices = {'coins_150': 'CA\$0.99', 'coins_350': 'CA\$1.99', 'coins_1000': 'CA\$4.99'};

  /// Dev builds (another app id, never sold anything by Play) preview the Coins tab when the store has no packs.
  @override
  bool get preview => !kReleaseMode && _products.isEmpty;

  @override
  List<(CoinPack, String)> get packs => preview
      ? [for (final p in coinPacks) (p, _samplePrices[p.productId]!)]
      : [
          for (final p in coinPacks)
            if (_products[p.productId] != null) (p, _products[p.productId]!.price),
        ];

  Future<void> init() async {
    _sub = _store.purchaseStream.listen(_onPurchases, onError: (_) {});
    try {
      if (!await _store.isAvailable()) return;
      final response = await _store.queryProductDetails(coinPackById.keys.toSet());
      for (final d in response.productDetails) {
        _products[d.id] = d;
      }
      notifyListeners();
    } catch (_) {
      // No store (emulator without Play, offline): packs just aren't offered.
    }
  }

  @override
  Future<void> buy(CoinPack pack) async {
    final product = _products[pack.productId];
    if (product == null) return; // preview: nothing to buy
    await _store.buyConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  /// Credits [p] if it's a coin pack not credited before; returns the coins added.
  @visibleForTesting
  Future<int> credit(String productId, String? purchaseId) async {
    final pack = coinPackById[productId];
    if (pack == null) return 0;
    final credited = _prefs.getStringList(_creditedKey) ?? const [];
    final id = purchaseId ?? '';
    if (id.isNotEmpty && credited.contains(id)) return 0;
    await _stats.addCoins(pack.coins);
    if (id.isNotEmpty) await _prefs.setStringList(_creditedKey, [...credited, id]);
    await _analytics.log('coin_pack_bought', {'pack': productId, 'coins': pack.coins});
    notifyListeners();
    return pack.coins;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (!coinPackById.containsKey(p.productID)) continue; // Remove Ads is handled by StorePremiumService
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        await credit(p.productID, p.purchaseID);
      }
      if (p.pendingCompletePurchase) await _store.completePurchase(p);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
