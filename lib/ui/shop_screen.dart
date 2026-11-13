import 'dart:math';

import 'package:flutter/material.dart';
import '../services/premium_service.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../meta/game_flow.dart';
import '../meta/shop.dart';
import '../services/coin_store_service.dart';
import '../services/sound_service.dart';
import 'capsule_screen.dart';
import 'cosmetics.dart';
import 'critter_actor.dart';
import 'critter_image.dart';
import 'meadow.dart';
import 'navigation.dart';
import 'palette.dart';
import 'remove_ads.dart';
import 'retention_ui.dart';
import 'services.dart';
import 'widgets.dart';
import 'worlds/world.dart';
import 'worlds/world_preview.dart';

enum ShopTab { capsules, hats, worlds, coins }

/// The market stall: capsules and streak repairs, hats, Worlds, and coin packs (behind the grown-up check).
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.random, this.initialTab = ShopTab.capsules});

  /// Parental gate numbers (tests).
  final Random? random;
  final ShopTab initialTab;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late ShopTab _tab = widget.initialTab;

  Future<void> _buy(ShopOffer offer) async {
    final services = Services.of(context);
    final l10n = AppLocalizations.of(context);
    final today = todayNumber(services.today());
    final result = await services.retention.shop.buy(offer.item.id, today);
    if (!mounted) return;
    switch (result) {
      case PurchaseResult.bought:
        services.sound.play(offer.item.category == ShopCategory.capsule ? Sfx.chest : Sfx.coin);
        HapticFeedback.mediumImpact();
        setState(() {});
        if (offer.item.category == ShopCategory.world) {
          // Bought Worlds are equipped right away: the whole app changes.
          _applyWorld(offer.item.id);
        } else if (offer.item.category == ShopCategory.capsule) {
          showToast(context, [l10n.shopBought, l10n.rewardCapsule], icon: const CapsuleEgg(size: 28));
        } else if (offer.item.category == ShopCategory.streakRepair) {
          showToast(context, [l10n.streakRepaired], icon: const FlameIcon(size: 26));
        } else {
          showToast(context, [
            l10n.shopBought,
            cosmeticName(l10n, offer.item.id),
          ], icon: const Text('🎉', style: TextStyle(fontSize: 22)));
        }
      case PurchaseResult.notEnoughCoins:
        await showSoftDialog<void>(
          context,
          emoji: '🪙',
          title: l10n.hintNoCoinsTitle,
          body: l10n.shopNotEnough(offer.price - services.stats.coins),
          actions: [
            if (_coinsTabShown(services))
              ChunkyButton(
                label: l10n.shopCoins,
                expand: true,
                color: gold,
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _tab = ShopTab.coins);
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel, style: chunky(15, color: inkSoft)),
            ),
          ],
        );
      case PurchaseResult.alreadyOwned || PurchaseResult.unavailable:
        setState(() {});
    }
  }

  Future<void> _equip(String id) async {
    final shop = Services.of(context).retention.shop;
    await shop.equip(id);
    if (!mounted) return;
    setState(() {});
    if (shopItemById[id]?.category == ShopCategory.world) _applyWorld(id);
  }

  void _applyWorld(String id) {
    final l10n = AppLocalizations.of(context);
    final world = worldById(id);
    WorldHost.maybeOf(context)?.switchTo(world);
    showToast(context, [l10n.worldEquipped(world.name(l10n))], icon: const Icon(Icons.public_rounded, size: 24));
  }

  Future<void> _buyPack(CoinPack pack) async {
    final store = Services.of(context).coinStore;
    if (store.preview) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).coinsPreview)));
      return;
    }
    if (await askParent(context, widget.random ?? Random())) await store.buy(pack);
  }

  bool _coinsTabShown(Services s) => s.coinStore.packs.isNotEmpty || s.premium.available || s.premium.isPremium;

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([services.coinStore, services.premium]),
      builder: (context, _) => _build(context, services),
    );
  }

  Widget _build(BuildContext context, Services services) {
    final l10n = AppLocalizations.of(context);
    final shop = services.retention.shop;
    final today = todayNumber(services.today());
    final offers = shop.offers(today);
    final coinsTab = _coinsTabShown(services);
    if (_tab == ShopTab.coins && !coinsTab) _tab = ShopTab.capsules;
    final tabs = [ShopTab.capsules, ShopTab.hats, ShopTab.worlds, if (coinsTab) ShopTab.coins];
    final deal = offers.where((o) => o.deal).firstOrNull;
    return MeadowScaffold(
      child: Column(
        children: [
          MeadowTopBar(
            title: l10n.shop,
            backTooltip: l10n.back,
            trailing: [CoinCounter(key: const Key('shopCoinsCounter'), value: services.stats.coins)],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final (i, t) in tabs.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _TabChip(
                      key: Key('tab-${t.name}'),
                      label: switch (t) {
                        ShopTab.capsules => l10n.shopCapsules,
                        ShopTab.hats => l10n.shopHats,
                        ShopTab.worlds => l10n.shopWorlds,
                        ShopTab.coins => l10n.shopCoins,
                      },
                      selected: _tab == t,
                      onTap: () => setState(() => _tab = t),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(_tab),
              padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + MediaQuery.viewPaddingOf(context).bottom),
              children: switch (_tab) {
                ShopTab.capsules => [
                  if (deal != null && deal.item.category != ShopCategory.capsule) ...[
                    _DealCard(
                      offer: deal,
                      onBuy: () => _buy(deal),
                      onTap: () => setState(
                        () => _tab = deal.item.category == ShopCategory.world ? ShopTab.worlds : ShopTab.hats,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  for (final o in offers.where((o) => !o.item.cosmetic)) ...[
                    _ItemRow(offer: o, onBuy: () => _buy(o)),
                    const SizedBox(height: 12),
                  ],
                ],
                ShopTab.hats => [
                  // Rows of two cards of equal height, so names, notes and buttons line up.
                  for (final row in _pairs(offers.where((o) => o.item.category == ShopCategory.hat).toList()))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: IntrinsicHeight(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          for (final (i, o) in row.indexed) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: _HatCard(offer: o, onBuy: () => _buy(o), onEquip: () => _equip(o.item.id))),
                          ],
                          if (row.length == 1) ...[const SizedBox(width: 12), const Expanded(child: SizedBox())],
                        ]),
                      ),
                    ),
                ],
                ShopTab.worlds => [
                  for (final o in offers.where((o) => o.item.category == ShopCategory.world)) ...[
                    _WorldCard(offer: o, onBuy: () => _buy(o), onEquip: () => _equip(o.item.id)),
                    const SizedBox(height: 14),
                  ],
                ],
                ShopTab.coins => [
                  Text(
                    l10n.shopCoinsNote,
                    textAlign: TextAlign.center,
                    style: outlinedText(15, stroke: woodEdge, width: 1.4),
                  ),
                  const SizedBox(height: 12),
                  if (services.premium.available || services.premium.isPremium) ...[
                    _NoAdsRow(premium: services.premium, random: widget.random),
                    const SizedBox(height: 28),
                  ],
                  for (final (pack, price) in services.coinStore.packs) ...[
                    _PackRow(pack: pack, price: price, onBuy: () => _buyPack(pack)),
                    // Room for the next card's ribbon, which sticks out above it.
                    const SizedBox(height: 28),
                  ],
                ],
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 42,
      decoration: BoxDecoration(
        color: selected ? woodButton : paper,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: selected ? woodEdge : paperEdge, width: 2.5),
        boxShadow: [BoxShadow(color: selected ? woodEdge : paperEdge, offset: const Offset(0, 3))],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          label,
          maxLines: 1,
          style: selected ? outlinedText(16, stroke: woodEdge, width: 1.4) : chunky(16, color: woodDark),
        ),
      ),
    ),
  );
}

/// A coin price on a candy button; a deal shows the old price struck through above it.
class PriceButton extends StatelessWidget {
  const PriceButton({super.key, required this.price, this.oldPrice, required this.onPressed, this.color});

  final int price;
  final int? oldPrice;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (oldPrice != null)
        Text(
          '$oldPrice',
          style: chunky(
            14,
            color: inkSoft,
          ).copyWith(decoration: TextDecoration.lineThrough, decorationColor: bad, decorationThickness: 2.5),
        ),
      ChunkyButton(label: '$price', small: true, color: color, icon: const CoinIcon(size: 22), onPressed: onPressed),
    ],
  );
}

/// A ribbon across a card's corner ("Daily deal", "Best value").
class Ribbon extends StatelessWidget {
  const Ribbon({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? bad;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 3, 12, 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(12),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: edgeOf(color), width: 2),
        boxShadow: [BoxShadow(color: edgeOf(color), offset: const Offset(0, 2))],
      ),
      child: Text(text, style: outlinedText(13, stroke: edgeOf(color), width: 1.2)),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.offer, required this.onBuy, required this.onTap});

  final ShopOffer offer;
  final VoidCallback onBuy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final base = services.retention.settings.shop.priceOf(offer.item);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SoftCard(
          key: const Key('dealCard'),
          color: goldSoft,
          border: gold,
          padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
          onTap: onTap,
          child: Row(
            children: [
              if (offer.item.category == ShopCategory.world)
                SizedBox(width: 62, height: 84, child: WorldMiniPreview(world: worldById(offer.item.id), borderRadius: 10))
              else
                _HatShowcase(hat: offer.item.id, size: 70),
              const SizedBox(width: 12),
              Expanded(child: Text(cosmeticName(l10n, offer.item.id), style: chunky(19))),
              PriceButton(price: offer.price, oldPrice: base, onPressed: offer.available ? onBuy : null, color: coral),
            ],
          ),
        ),
        Positioned(
          left: -4,
          top: -10,
          child: Ribbon(text: '${l10n.shopDeal} −${services.retention.settings.shop.dealPercent}%'),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.offer, required this.onBuy});

  final ShopOffer offer;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final repair = offer.item.category == ShopCategory.streakRepair;
    final base = services.retention.settings.shop.priceOf(offer.item);
    final card = SoftCard(
      key: Key('item-${offer.item.id}'),
      color: offer.deal ? goldSoft : paper,
      border: offer.deal ? gold : null,
      padding: EdgeInsets.fromLTRB(12, offer.deal ? 22 : 12, 12, 12),
      child: Row(
        children: [
          SizedBox(width: 60, child: Center(child: repair ? const FlameIcon(size: 48) : const CapsuleEgg(size: 56))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(repair ? l10n.shopStreakRepair : l10n.capsuleWord, style: chunky(19)),
                Text(
                  repair
                      ? (offer.available ? l10n.shopStreakRepairBody : l10n.shopStreakRepairNone)
                      : l10n.shopCapsuleBody,
                  style: chunky(14, color: inkSoft, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PriceButton(
            key: Key('buy-${offer.item.id}'),
            price: offer.price,
            oldPrice: offer.deal ? base : null,
            onPressed: offer.available ? onBuy : null,
          ),
        ],
      ),
    );
    if (!offer.deal) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: -4,
          top: -10,
          child: Ribbon(text: '${l10n.shopDeal} −${services.retention.settings.shop.dealPercent}%'),
        ),
      ],
    );
  }
}

/// A critter on a little grass mound wearing [hat].
class _HatShowcase extends StatelessWidget {
  const _HatShowcase({required this.hat, this.size = 90});

  final String hat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final critter = buddyCritters(Services.of(context).stats, 1, seed: hat.hashCode).first;
    return SizedBox(
      width: size,
      height: size * 1.05,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.9,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: grass,
                borderRadius: BorderRadius.all(Radius.elliptical(size * 0.45, size * 0.13)),
                border: Border.all(color: grassDark, width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.06,
            child: Hatted(
              hat: hat,
              size: size * 0.82,
              child: CritterImage(critter, size: size * 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _HatCard extends StatelessWidget {
  const _HatCard({required this.offer, required this.onBuy, required this.onEquip});

  final ShopOffer offer;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final base = services.retention.settings.shop.priceOf(offer.item);
    final set = unlockSetOf(offer.item.id);
    final Widget action;
    if (offer.equipped) {
      action = ChunkyButton(
        key: Key('equip-${offer.item.id}'),
        label: l10n.shopTakeOff,
        small: true,
        expand: true,
        color: woodButton,
        onPressed: onEquip,
      );
    } else if (offer.owned) {
      action = ChunkyButton(
        key: Key('equip-${offer.item.id}'),
        label: l10n.shopEquip,
        small: true,
        expand: true,
        color: sky,
        onPressed: onEquip,
      );
    } else {
      action = PriceButton(
        key: Key('buy-${offer.item.id}'),
        price: offer.price,
        oldPrice: offer.deal ? base : null,
        onPressed: onBuy,
      );
    }
    final card = SoftCard(
      key: Key('item-${offer.item.id}'),
      color: offer.equipped ? goodSoft : (offer.deal ? goldSoft : paper),
      border: offer.equipped ? leaf : (offer.deal ? gold : null),
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      child: Column(
        children: [
          _HatShowcase(hat: offer.item.id),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(cosmeticName(l10n, offer.item.id), maxLines: 1, style: chunky(17)),
          ),
          if (offer.equipped)
            Text(l10n.shopEquipped, style: chunky(13, color: leafEdge))
          else if (!offer.owned && set != null)
            Text(
              set == 'all' ? l10n.shopOrAlbum : l10n.shopOrSet(setName(l10n, set)),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: chunky(12, color: inkSoft, weight: FontWeight.w500),
            )
          else
            const SizedBox(height: 15),
          const SizedBox(height: 8),
          const Spacer(),
          action,
        ],
      ),
    );
    if (!offer.deal) return card;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        card,
        Positioned(left: -4, top: -10, child: Ribbon(text: l10n.shopDeal)),
      ],
    );
  }
}

/// "No ads" for good: banners and between-puzzle ads go away; reward videos stay optional.
class _NoAdsRow extends StatelessWidget {
  const _NoAdsRow({required this.premium, this.random});

  final PremiumService premium;
  final Random? random;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final owned = premium.isPremium;
    final card = SoftCard(
      key: const Key('shopNoAds'),
      color: owned ? goodSoft : paper,
      border: owned ? leaf : coral,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Row(children: [
        SizedBox(
          width: 70,
          height: 54,
          child: Center(
            child: Icon(owned ? Icons.verified_rounded : Icons.block_rounded, size: 46, color: owned ? leaf : coral),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.shopNoAdsTitle, maxLines: 1, style: chunky(20)),
            ),
            Text(owned ? l10n.shopNoAdsOwned : l10n.shopNoAdsBody,
                style: chunky(13, color: inkSoft, weight: FontWeight.w500)),
          ]),
        ),
        if (!owned)
          ChunkyButton(
            key: const Key('buyNoAds'),
            label: premium.price ?? '',
            small: true,
            color: coral,
            onPressed: () => buyNoAds(context, premium, random: random),
          ),
      ]),
    );
    return card;
  }
}

class _PackRow extends StatelessWidget {
  const _PackRow({required this.pack, required this.price, required this.onBuy});

  final CoinPack pack;
  final String price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pile = pack.coins >= 1000 ? 5 : (pack.coins >= 350 ? 3 : 1);
    final card = SoftCard(
      key: Key('pack-${pack.productId}'),
      color: pack.bestValue ? goldSoft : paper,
      border: pack.bestValue ? gold : null,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 54,
            child: Stack(
              children: [
                for (var i = 0; i < pile; i++)
                  Positioned(
                    left: pile == 1 ? 18 : 4.0 + (i % 3) * 14,
                    bottom: pile == 1 ? 10 : (i ~/ 3) * 14.0 + (i.isOdd ? 6 : 0),
                    child: const CoinIcon(size: 34),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.coinPackCoins(pack.coins), style: chunky(20)),
                if (pack.bonusPercent > 0)
                  Text(l10n.coinPackBonus(pack.bonusPercent), style: chunky(15, color: leafEdge)),
              ],
            ),
          ),
          ChunkyButton(
            key: Key('buyPack-${pack.productId}'),
            label: price,
            small: true,
            color: gold,
            textColor: ink,
            onPressed: onBuy,
          ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        if (pack.bestValue) Positioned(left: -4, top: -10, child: Ribbon(text: l10n.coinPackBest)),
      ],
    );
  }
}

/// Opens the shop on a tab.
Future<void> openShop(BuildContext context, {ShopTab tab = ShopTab.capsules}) =>
    Navigator.of(context).push(softRoute(ShopScreen(initialTab: tab)));

/// A World for sale or owned: a live mini preview (tap = full screen), its name and blurb, and Buy / Equip.
class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.offer, required this.onBuy, required this.onEquip});

  final ShopOffer offer;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final world = worldById(offer.item.id);
    final base = services.retention.settings.shop.priceOf(offer.item);
    final Widget action;
    if (offer.equipped) {
      action = Container(
        key: Key('equipped-${offer.item.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: goodSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_rounded, color: leafEdge, size: 20),
          const SizedBox(width: 4),
          Flexible(child: Text(l10n.shopEquipped, maxLines: 1, style: chunky(15, color: leafEdge))),
        ]),
      );
    } else if (offer.owned) {
      action = ChunkyButton(
        key: Key('equip-${offer.item.id}'),
        label: l10n.shopEquip,
        small: true,
        color: sky,
        onPressed: onEquip,
      );
    } else {
      action = PriceButton(
        key: Key('buy-${offer.item.id}'),
        price: offer.price,
        oldPrice: offer.deal ? base : null,
        onPressed: onBuy,
      );
    }
    final card = SoftCard(
      key: Key('item-${offer.item.id}'),
      color: offer.equipped ? goodSoft : (offer.deal ? goldSoft : paper),
      border: offer.equipped ? leaf : (offer.deal ? gold : null),
      padding: EdgeInsets.fromLTRB(10, offer.deal ? 20 : 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            button: true,
            label: l10n.worldPreview,
            child: Bouncy(
              key: Key('preview-${offer.item.id}'),
              onTap: () => showWorldPreview(context, world),
              child: Stack(children: [
                SizedBox(width: 96, height: 136, child: WorldMiniPreview(world: world, borderRadius: 12)),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Color(0x99000000), shape: BoxShape.circle),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(world.name(l10n), maxLines: 1, style: chunky(20)),
                ),
                const SizedBox(height: 2),
                Text(world.blurb(l10n), maxLines: 3, style: chunky(13.5, color: inkSoft, weight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(children: [
                  if (offer.item.price == 0 && !offer.equipped) ...[
                    Text(l10n.worldFree, style: chunky(14, color: leafEdge)),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: action),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
    if (!offer.deal) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          left: -4,
          top: -10,
          child: Ribbon(text: '${l10n.shopDeal} −${services.retention.settings.shop.dealPercent}%'),
        ),
      ],
    );
  }
}
/// [items] two by two (the last row may hold one).
List<List<T>> _pairs<T>(List<T> items) => [
      for (var i = 0; i < items.length; i += 2) items.sublist(i, i + 2 > items.length ? items.length : i + 2),
    ];
