"""Builds assets/sfx/<name>.wav (one per Sfx in lib/services/sound_service.dart) from Kenney sound packs.

All sources are CC0 (kenney.nl, see assets/CREDITS.md). Download and unzip the packs, then run:
  python3 -I tools/import_sfx.py <Interface Sounds dir> <RPG Audio dir> <Casino Audio dir>
Each dir is the pack's unzipped root (the one holding Audio/). Needs ffmpeg on PATH; stdlib only.

Every effect is one or more pack sounds mixed at time offsets (seconds) and gains (dB), softened
with a low-pass so nothing is shrill, trimmed of silence, faded, peak-normalized to -3 dBFS and
written as 16-bit mono 44.1 kHz WAV.
"""
import array
import math
import subprocess
import sys
import wave
from pathlib import Path

RATE = 44100
PEAK_DB = -3.0
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'sfx'

# name -> [(pack, file, start_s, gain_db, max_len_s or None)]
# Packs: 'ui' = Interface Sounds, 'rpg' = RPG Audio, 'casino' = Casino Audio.
EFFECTS = {
    # Soft, low click.
    'tap': [('ui', 'click_002.ogg', 0, 0, None)],
    # Round bubbly "drop" pop.
    'place': [('ui', 'drop_002.ogg', 0, 0, None)],
    # Tiny tick.
    'cross': [('ui', 'tick_004.ogg', 0, 0, None)],
    # Soft falling swoosh, the reverse of the "maximize" sounds.
    'erase': [('ui', 'minimize_008.ogg', 0, 0, None)],
    # Low, short, gentle bong.
    'conflict': [('ui', 'bong_001.ogg', 0, 0, None)],
    # Two rising confirmations, then a glassy ping.
    'solve': [
        ('ui', 'confirmation_001.ogg', 0.0, 0, None),
        ('ui', 'confirmation_004.ogg', 0.24, -1, None),
        ('ui', 'glass_001.ogg', 0.70, -4, None),
    ],
    # Two glass pings a fifth apart (~1450 Hz then ~2190 Hz) over a quiet jingle of coins.
    'coin': [
        ('ui', 'glass_006.ogg', 0.0, 0, None),
        ('ui', 'glass_005.ogg', 0.07, 0, None),
        ('rpg', 'handleCoins2.ogg', 0.0, -12, None),
    ],
    # Capsule rattled for half a second, then pops open.
    'capsule': [
        ('casino', 'dice-shake-1.ogg', 0.0, -6, 0.5),
        ('ui', 'drop_004.ogg', 0.5, 0, None),
    ],
    # Rising swoosh with two sparkles.
    'reveal': [
        ('ui', 'maximize_009.ogg', 0.0, 0, None),
        ('ui', 'glass_001.ogg', 0.12, -3, None),
        ('ui', 'glass_003.ogg', 0.26, -5, None),
    ],
    # Lid creak, little fanfare, sparkle.
    'chest': [
        ('rpg', 'creak3.ogg', 0.0, -6, None),
        ('ui', 'confirmation_002.ogg', 0.22, 0, None),
        ('ui', 'glass_001.ogg', 0.62, -4, None),
    ],
}


def decode(path, max_len):
    """Mono float samples at RATE, low-passed at 9 kHz."""
    af, extra = 'lowpass=f=9000', []
    if max_len:
        # Short fade-out so the cut isn't a click.
        af += f',afade=t=out:st={max_len - 0.08}:d=0.08'
        extra = ['-t', str(max_len)]
    cmd = ['ffmpeg', '-v', 'error', '-i', str(path), '-af', af, '-ac', '1', '-ar', str(RATE)] + extra
    raw = subprocess.run(cmd + ['-f', 'f32le', '-'], capture_output=True, check=True).stdout
    return array.array('f', raw)


def trim(x, thresh_db=-50.0):
    thr = max(abs(v) for v in x) * 10 ** (thresh_db / 20)
    start = next(i for i, v in enumerate(x) if abs(v) > thr)
    end = len(x) - next(i for i, v in enumerate(reversed(x)) if abs(v) > thr)
    return x[start:end]


def build(parts, packs):
    tracks = []
    for pack, name, start, gain, max_len in parts:
        x = trim(decode(packs[pack] / 'Audio' / name, max_len))
        g = 10 ** (gain / 20)
        tracks.append((int(start * RATE), [v * g for v in x]))
    buf = [0.0] * max(o + len(x) for o, x in tracks)
    for o, x in tracks:
        for i, v in enumerate(x):
            buf[o + i] += v
    buf = trim(buf)
    # 2 ms fade-in and 15 ms fade-out: no clicks at either end.
    fin, fout = int(0.002 * RATE), int(0.015 * RATE)
    for i in range(min(fin, len(buf))):
        buf[i] *= i / fin
    for i in range(min(fout, len(buf))):
        buf[-1 - i] *= i / fout
    scale = 10 ** (PEAK_DB / 20) / max(abs(v) for v in buf)
    return [v * scale for v in buf]


def save(name, samples):
    pcm = array.array('h', (max(-32768, min(32767, round(v * 32767))) for v in samples))
    if sys.byteorder == 'big':
        pcm.byteswap()
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def main():
    ui, rpg, casino = (Path(p) for p in sys.argv[1:4])
    packs = {'ui': ui, 'rpg': rpg, 'casino': casino}
    OUT.mkdir(parents=True, exist_ok=True)
    for name, parts in EFFECTS.items():
        s = build(parts, packs)
        save(name, s)
        peak = 20 * math.log10(max(abs(v) for v in s))
        print(f'{name:9s} {len(s) / RATE:.2f} s  peak {peak:.1f} dBFS')


if __name__ == '__main__':
    main()
