import 'package:critter_logic/services/music_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('music plays only when started, enabled and in the foreground', () {
    expect(musicShouldPlay(started: true, enabled: true, foreground: true), isTrue);
    expect(musicShouldPlay(started: false, enabled: true, foreground: true), isFalse);
    expect(musicShouldPlay(started: true, enabled: false, foreground: true), isFalse);
    expect(musicShouldPlay(started: true, enabled: true, foreground: false), isFalse);
  });

  test('NoMusic follows start, stop and the enabled setting', () async {
    final music = NoMusic();
    expect(music.playing, isFalse);
    await music.start();
    expect(music.playing, isTrue);
    await music.setEnabled(false);
    expect(music.enabled, isFalse);
    expect(music.playing, isFalse);
    await music.setEnabled(true);
    expect(music.playing, isTrue);
    await music.stop();
    expect(music.playing, isFalse);
  });

  test('NoMusic can start disabled', () async {
    final music = NoMusic(enabled: false);
    await music.start();
    expect(music.playing, isFalse);
  });
}
