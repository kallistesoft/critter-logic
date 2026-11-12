import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Short effects in `assets/sfx/<name>.wav`.
enum Sfx { tap, place, cross, erase, conflict, solve, coin, capsule, reveal, chest }

abstract class SoundService {
  bool get muted;
  Future<void> setMuted(bool value);
  void play(Sfx sfx);
}

class NoSound implements SoundService {
  @override
  bool muted = false;

  final played = <Sfx>[];

  @override
  Future<void> setMuted(bool value) async => muted = value;

  @override
  void play(Sfx sfx) {
    if (!muted) played.add(sfx);
  }
}

/// Short effects from assets/sfx: two players per effect, used in turn so a quick repeat can overlap the last one.
///
/// On Android the players use the low-latency engine (SoundPool). The default MediaPlayer mode crashed the app
/// (IllegalStateException in MediaPlayer.prepareAsync): when an effect finished, the plugin re-prepared the player while
/// the pool was releasing it.
class AudioSoundService implements SoundService {
  AudioSoundService({required bool muted, required Future<void> Function(bool) persist})
      : _muted = muted, // ignore: prefer_initializing_formals
        _persist = persist; // ignore: prefer_initializing_formals

  static const _perEffect = 2;
  static const _volume = 0.8;

  bool _muted;
  final Future<void> Function(bool) _persist;
  final _players = <Sfx, Future<List<AudioPlayer>>>{};
  final _next = <Sfx, int>{};

  @override
  bool get muted => _muted;

  @override
  Future<void> setMuted(bool value) async {
    _muted = value;
    await _persist(value);
  }

  Future<List<AudioPlayer>> _load(Sfx sfx) async {
    final lowLatency = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return [
      for (var i = 0; i < _perEffect; i++)
        await () async {
          final player = AudioPlayer();
          if (lowLatency) await player.setPlayerMode(PlayerMode.lowLatency);
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setVolume(_volume);
          await player.setSource(AssetSource('sfx/${sfx.name}.wav'));
          return player;
        }(),
    ];
  }

  @override
  void play(Sfx sfx) {
    if (_muted) return;
    final players = _players.putIfAbsent(sfx, () => _load(sfx));
    unawaited(() async {
      try {
        final list = await players;
        final i = _next[sfx] ?? 0;
        _next[sfx] = (i + 1) % list.length;
        final player = list[i];
        await player.stop();
        await player.resume();
      } catch (_) {
        // Browsers can refuse audio before the first user gesture; a missed effect is fine.
      }
    }());
  }
}
