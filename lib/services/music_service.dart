import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Background music: `assets/music/loop.m4a`, looped quietly.
abstract class MusicService {
  bool get enabled;

  /// Turns music on or off (the player's setting); persisted by the implementation.
  Future<void> setEnabled(bool value);

  /// The app wants music now (plays if [enabled] and the app is in the foreground).
  Future<void> start();

  /// The app no longer wants music.
  Future<void> stop();
}

/// Music plays only when the app asked for it, the player enabled it and the app is visible.
bool musicShouldPlay({required bool started, required bool enabled, required bool foreground}) =>
    started && enabled && foreground;

class NoMusic implements MusicService {
  NoMusic({this.enabled = true});

  @override
  bool enabled;

  bool started = false;

  bool get playing => musicShouldPlay(started: started, enabled: enabled, foreground: true);

  @override
  Future<void> setEnabled(bool value) async => enabled = value;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => started = false;
}

/// Loops the track with audioplayers, at low volume, paused while the app is in the background.
class AudioMusicService implements MusicService {
  AudioMusicService({required bool enabled, required Future<void> Function(bool) persist})
      : _enabled = enabled, // ignore: prefer_initializing_formals
        _persist = persist; // ignore: prefer_initializing_formals

  static const asset = 'music/loop.m4a';
  static const volume = 0.35;

  bool _enabled;
  final Future<void> Function(bool) _persist;
  bool _started = false;
  bool _foreground = true;
  AudioPlayer? _player;
  bool _loaded = false;
  AppLifecycleListener? _lifecycle;
  Future<void> _pending = Future.value();

  @override
  bool get enabled => _enabled;

  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _persist(value);
    await _sync();
  }

  @override
  Future<void> start() {
    _started = true;
    _lifecycle ??= AppLifecycleListener(
      onHide: () {
        _foreground = false;
        unawaited(_sync());
      },
      onShow: () {
        _foreground = true;
        unawaited(_sync());
      },
    );
    return _sync();
  }

  @override
  Future<void> stop() {
    _started = false;
    return _sync();
  }

  /// Applies the wanted state; calls are queued so play/pause never overlap.
  Future<void> _sync() => _pending = _pending.then((_) async {
        final play = musicShouldPlay(started: _started, enabled: _enabled, foreground: _foreground);
        try {
          if (play) {
            final player = _player ??= AudioPlayer(playerId: 'music');
            if (_loaded) {
              await player.resume();
            } else {
              await player.setReleaseMode(ReleaseMode.loop);
              await player.setVolume(volume);
              await player.play(AssetSource(asset));
              _loaded = true;
            }
          } else if (_player != null && _loaded) {
            await _player!.pause();
          }
        } catch (_) {
          // Browsers refuse audio before the first user gesture; music simply stays off.
          _loaded = false;
        }
      });
}
