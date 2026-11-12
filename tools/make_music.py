"""Synthesizes the background music, assets/music/loop.m4a: a calm, cozy ~72 s seamless loop.

Original (no samples): soft electric-piano chords, a round sine bass, a plucked kalimba melody and
a gentle low "thump" pulse, 80 BPM in F major. Notes still ringing at the end of the loop are wrapped
around onto its start, so the loop point has no click or gap. Everything is low-passed (no harsh highs),
levelled to about -17 LUFS with peaks under -6 dBFS.

Run: python3 tools/make_music.py   (needs numpy; macOS afconvert for the AAC encode)
"""
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

RATE = 44100
BPM = 80
BEAT = 60 / BPM
BARS = 24  # 24 bars of 4/4 at 80 BPM = 72 s
LOOP = int(round(BARS * 4 * BEAT * RATE))
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'music' / 'loop.m4a'
RMS_DB = -13.5  # with the limiter below: about -17 LUFS (checked with ffmpeg ebur128)
PEAK_DB = -6.8


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


# F major, two chords per 4 bars, 4-chord phrase; the last phrase lands back on the first chord.
# (root, chord tones as MIDI notes)
F, Dm, Bb, C, Am, Gm = 53, 50, 46, 48, 45, 43
CHORDS = {
    'Fmaj7': (F, [65, 69, 72, 76]),
    'Dm7': (Dm, [62, 65, 69, 72]),
    'Bbmaj7': (Bb, [62, 65, 69, 70]),
    'C6': (C, [60, 64, 67, 69]),
    'Am7': (Am, [60, 64, 67, 69]),
    'Gm7': (Gm, [62, 65, 67, 70]),
}
PROGRESSION = ['Fmaj7', 'Dm7', 'Bbmaj7', 'C6',
               'Fmaj7', 'Am7', 'Gm7', 'C6',
               'Dm7', 'Bbmaj7', 'Gm7', 'C6'] * 2  # one chord per bar, 24 bars

# F major pentatonic (F G A C D) over two octaves for the kalimba.
PENTA = [65, 67, 69, 72, 74, 77, 79, 81, 84]


def env(n, attack, decay):
    t = np.arange(n) / RATE
    return np.minimum(1.0, t / attack) * np.exp(-t / decay)


def epiano(freq, dur, vol):
    n = int((dur + 2.5) * RATE)
    t = np.arange(n) / RATE
    tone = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * 2 * freq * t) * np.exp(-t / 0.4)
    # Gentle tremolo, release after `dur`.
    e = env(n, 0.03, 2.2) * (1 + 0.08 * np.sin(2 * np.pi * 4.5 * t))
    rel = np.clip(1 - (t - dur) / 1.2, 0, 1)
    return vol * tone * e * rel


def kalimba(freq, vol):
    n = int(2.0 * RATE)
    t = np.arange(n) / RATE
    tone = (np.sin(2 * np.pi * freq * t) * np.exp(-t / 0.7)
            + 0.18 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t / 0.06)  # tine "tink"
            + 0.12 * np.sin(2 * np.pi * freq * 2 * t) * np.exp(-t / 0.3))
    return vol * tone * np.minimum(1.0, t / 0.004)


def bass(freq, dur, vol):
    n = int((dur + 0.3) * RATE)
    t = np.arange(n) / RATE
    tone = np.sin(2 * np.pi * freq * t) + 0.15 * np.sin(2 * np.pi * 2 * freq * t)
    rel = np.clip(1 - (t - dur) / 0.3, 0, 1)
    return vol * tone * env(n, 0.02, 1.6) * rel


def thump(vol):
    n = int(0.25 * RATE)
    t = np.arange(n) / RATE
    f = 55 + 45 * np.exp(-t / 0.03)  # soft pitch drop
    return vol * np.sin(2 * np.pi * np.cumsum(f) / RATE) * env(n, 0.003, 0.08)


def lowpass(x, cutoff):
    """One-pole low-pass, run twice (12 dB/octave), wrapped so the loop stays seamless."""
    a = np.exp(-2 * np.pi * cutoff / RATE)
    for _ in range(2):
        y = np.empty_like(x)
        prev = 0.0
        # Warm the filter on the loop's tail so sample 0 continues from the end.
        for v in x[-RATE:]:
            prev = (1 - a) * v + a * prev
        for i, v in enumerate(x):
            prev = (1 - a) * v + a * prev
            y[i] = prev
        x = y
    return x


def melody(rng):
    """One kalimba note list per bar: (beat offset, midi). Calm: 2-4 notes a bar, small steps, rests."""
    bars, idx = [], 3
    for bar, name in enumerate(PROGRESSION):
        tones = CHORDS[name][1]
        notes = []
        rhythm = [[0, 1.5, 3], [0, 2], [0.5, 1.5, 2.5], [0, 1, 2, 3], [1, 2.5], [0, 1.5, 2, 3]][rng.integers(6)]
        if bar % 4 == 3:
            rhythm = [0, 2]  # breathe at phrase ends
        for beat in rhythm:
            idx = int(np.clip(idx + rng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(PENTA) - 1))
            note = PENTA[idx]
            if beat == 0 and note % 12 not in {m % 12 for m in tones}:
                # Downbeats sit on a chord tone: nearest one in the scale.
                idx = min(range(len(PENTA)), key=lambda k: (PENTA[k] % 12 not in {m % 12 for m in tones}, abs(k - idx)))
                note = PENTA[idx]
            notes.append((beat, note))
        bars.append(notes)
    return bars


def render():
    rng = np.random.default_rng(7)
    buf = np.zeros(LOOP + 4 * RATE)
    bar_len = 4 * BEAT

    def add(at_s, x):
        i = int(round(at_s * RATE))
        buf[i:i + len(x)] += x[:len(buf) - i]

    for bar, name in enumerate(PROGRESSION):
        root, tones = CHORDS[name]
        t0 = bar * bar_len
        # Chord: slightly strummed, held most of the bar.
        for k, m in enumerate(tones):
            add(t0 + 0.012 * k, epiano(hz(m), bar_len * 0.92, 0.055))
        # Bass: root on beat 1, fifth on beat 3 (lightly swung pickup on 4.5 in every other bar).
        add(t0, bass(hz(root - 12 if root > 47 else root), 1.8 * BEAT, 0.22))
        add(t0 + 2 * BEAT, bass(hz(root + 7 - 12 if root > 47 else root + 7), 1.6 * BEAT, 0.16))
        # Soft pulse on 1 and 3.
        add(t0, thump(0.18))
        add(t0 + 2 * BEAT, thump(0.12))
    swing = 0.06 * BEAT
    for bar, notes in enumerate(melody(rng)):
        for beat, m in notes:
            at = bar * bar_len + beat * BEAT + (swing if beat % 1 else 0)
            add(at, kalimba(hz(m), 0.16 + 0.04 * rng.random()))
    # Wrap the ringing tail onto the start: seamless loop.
    loop = buf[:LOOP].copy()
    loop[:len(buf) - LOOP] += buf[LOOP:]
    loop = lowpass(loop, 5000.0)
    loop -= loop.mean()
    rms = np.sqrt(np.mean(loop ** 2))
    loop *= 10 ** (RMS_DB / 20) / rms
    loop = limit(loop, 10 ** (PEAK_DB / 20))
    peak = np.abs(loop).max()
    if peak > 10 ** (PEAK_DB / 20):
        loop *= 10 ** (PEAK_DB / 20) / peak
    return loop


def limit(x, ceiling, block=64, release_s=0.25):
    """Gentle look-ahead peak limiter (the kalimba and pulse transients), circular so the loop stays seamless."""
    n = len(x) // block * block
    peaks = np.abs(x[:n]).reshape(-1, block).max(axis=1)
    peaks = np.append(peaks, np.abs(x[n:]).max() if n < len(x) else 0)
    need = np.minimum(1.0, ceiling / np.maximum(peaks, 1e-9))
    # Look ahead one block each side so the gain is already down when the peak arrives.
    need = np.minimum(need, np.minimum(np.roll(need, 1), np.roll(need, -1)))
    rel = np.exp(-block / (release_s * RATE))
    g, gains = 1.0, np.empty_like(need)
    for _ in range(2):  # second pass starts from the end state: circular
        for i, v in enumerate(need):
            g = v if v < g else v + (g - v) * rel
            gains[i] = g
    centers = np.arange(len(gains)) * block + block / 2
    return x * np.interp(np.arange(len(x)), centers, gains, period=len(x))


def main():
    loop = render()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / 'loop.wav'
        with wave.open(str(wav), 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes((np.clip(loop, -1, 1) * 32767).round().astype('<i2').tobytes())
        subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '96000', str(wav), str(OUT)], check=True)
    edge = abs(loop[0] - loop[-1])
    print(f'{len(loop) / RATE:.1f} s, peak {20 * np.log10(np.abs(loop).max()):.1f} dBFS, '
          f'rms {20 * np.log10(np.sqrt(np.mean(loop ** 2))):.1f} dBFS, loop-edge jump {edge:.5f}, '
          f'{OUT.stat().st_size // 1024} KB')


if __name__ == '__main__':
    main()
