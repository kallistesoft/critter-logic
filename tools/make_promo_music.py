"""Synthesizes the promo-video soundtrack: an upbeat, original 30 s cue at 120 BPM (one bar = 2 s), in C major.

Original (no samples): the drums, bass, plucks, pads, lead, riser and impacts are all made here with numpy. Structure,
which the edit in tools/make_promo_video.py cuts to:

    0–2 s    cold open: filtered plucks, a rising swell
    2 s      title hit (impact + crash), 2–4 s pad and sparkles
    4–12 s   the groove: kick, claps, hats, bass, pluck arpeggio (the three games)
    12–21 s  + lead melody (coins, Lucky Nest, critters); 20–22 s snare roll and riser
    22–26 s  climax: everything plus an octave lead (the Worlds montage)
    26 s     final hit, the chord rings out to 30 s (end card)

Run: python3 tools/make_promo_music.py OUT.wav   (needs numpy). make_promo_video.py calls `render()` directly.
"""
import sys
import wave

import numpy as np

RATE = 48000
BPM = 120
BEAT = 60 / BPM
BAR = 4 * BEAT
LENGTH = 30.0
N = int(LENGTH * RATE)

rng = np.random.default_rng(11)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def t_of(n):
    return np.arange(n) / RATE


def _shape(x, gain):
    """Filters [x] in the frequency domain by [gain](freqs) (Butterworth magnitudes, zero phase)."""
    n = len(x)
    if n == 0:
        return x
    size = 1 << int(np.ceil(np.log2(n + 1024)))
    f = np.fft.rfftfreq(size, 1 / RATE)
    return np.fft.irfft(np.fft.rfft(x, size) * gain(f), size)[:n]


def lowpass(x, fc, order=2):
    return _shape(x, lambda f: 1 / np.sqrt(1 + (f / fc) ** (2 * order)))


def highpass(x, fc, order=2):
    return _shape(x, lambda f: 1 / np.sqrt(1 + (fc / np.maximum(f, 1e-3)) ** (2 * order)))


def bandpass(x, lo, hi, order=2):
    return _shape(x, lambda f: 1 / np.sqrt(1 + (f / hi) ** (2 * order)) / np.sqrt(1 + (lo / np.maximum(f, 1e-3)) ** (2 * order)))


def add(buf, sig, at, gain=1.0):
    i = int(round(at * RATE))
    if i >= len(buf):
        return
    sig = sig[: len(buf) - i]
    buf[i:i + len(sig)] += gain * sig


def saw(f, t):
    # A few band-limited partials: warm, no aliasing.
    out = np.zeros_like(t)
    for k in range(1, 12):
        if f * k > RATE / 2.5:
            break
        out += ((-1) ** (k + 1)) * np.sin(2 * np.pi * f * k * t) / k
    return out * 0.6


def kick(gain=1.0):
    t = t_of(int(0.35 * RATE))
    f = 48 + 110 * np.exp(-t / 0.035)
    ph = 2 * np.pi * np.cumsum(f) / RATE
    body = np.sin(ph) * np.exp(-t / 0.16)
    click = rng.normal(size=len(t)) * np.exp(-t / 0.003) * 0.25
    return gain * (body + click)


def clap():
    t = t_of(int(0.25 * RATE))
    env = np.zeros_like(t)
    for d in (0.0, 0.011, 0.022):
        env += (t >= d) * np.exp(-np.clip(t - d, 0, None) / (0.012 if d < 0.02 else 0.09))
    return bandpass(rng.normal(size=len(t)), 900, 5000) * env * 0.55


def hat(open_=False):
    t = t_of(int((0.18 if open_ else 0.05) * RATE))
    return highpass(rng.normal(size=len(t)), 7000) * np.exp(-t / (0.06 if open_ else 0.012)) * 0.22


def snare():
    t = t_of(int(0.2 * RATE))
    tone = np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.05) * 0.5
    noise = bandpass(rng.normal(size=len(t)), 1500, 8000) * np.exp(-t / 0.07)
    return (tone + noise) * 0.5


def pluck(m, dur=0.35, bright=4000):
    t = t_of(int((dur + 0.4) * RATE))
    f = hz(m)
    x = saw(f, t) + 0.5 * np.sin(2 * np.pi * f * 2 * t)
    x = lowpass(x * np.exp(-t / dur), bright)
    return x * np.minimum(1, t / 0.003)


def bass(m, dur):
    t = t_of(int((dur + 0.05) * RATE))
    f = hz(m)
    x = np.sin(2 * np.pi * f * t) + 0.35 * saw(f, t)
    x = lowpass(x, 900)
    env = np.minimum(1, t / 0.005) * np.clip((dur + 0.05 - t) / 0.05, 0, 1)
    return x * env * 0.8


def pad(ms, dur, cutoff=2500):
    t = t_of(int((dur + 1.0) * RATE))
    x = np.zeros_like(t)
    for m in ms:
        for det in (-0.08, 0.0, 0.08):
            x += saw(hz(m + det), t + rng.uniform(0, 0.01))
    x = lowpass(x, cutoff)
    env = np.minimum(1, t / 0.25) * np.clip((dur + 1.0 - t) / 1.0, 0, 1)
    return x * env / (len(ms) * 3) * 0.9


def lead(m, dur):
    t = t_of(int((dur + 0.15) * RATE))
    f = hz(m) * (1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t / 0.15))
    ph = 2 * np.pi * np.cumsum(f) / RATE
    x = np.sign(np.sin(ph)) * 0.35 + np.sin(ph) * 0.6 + 0.2 * np.sin(2 * ph)
    x = lowpass(x, 3800)
    env = np.minimum(1, t / 0.01) * np.exp(-t / 0.9) * np.clip((dur + 0.15 - t) / 0.15, 0, 1)
    return x * env * 0.35


def bell(m, dur=0.8):
    t = t_of(int(dur * RATE))
    f = hz(m)
    return (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t) * np.exp(-t / 0.15)) * np.exp(-t / 0.35) * 0.25


def impact():
    t = t_of(int(2.5 * RATE))
    f = 38 + 70 * np.exp(-t / 0.08)
    boom = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-t / 0.7)
    crash = highpass(rng.normal(size=len(t)), 3000) * np.exp(-t / 0.9) * 0.35
    return boom * 1.1 + crash


def riser(dur):
    t = t_of(int(dur * RATE))
    x = rng.normal(size=len(t))
    out = np.zeros_like(t)
    seg = int(0.05 * RATE)
    for i in range(0, len(t), seg):
        c = 400 + 9000 * (i / len(t)) ** 2
        out[i:i + seg] = bandpass(x[max(0, i - 2000):i + seg], c * 0.7, c * 1.3)[-len(out[i:i + seg]):]
    tone = np.sin(2 * np.pi * np.cumsum(200 + 800 * (t / dur) ** 2) / RATE) * 0.15
    return (out * 0.4 + tone) * (t / dur) ** 1.5


def whoosh(dur=0.35):
    t = t_of(int(dur * RATE))
    x = bandpass(rng.normal(size=len(t)), 600, 6000)
    env = np.sin(np.pi * t / dur) ** 2
    return x * env * 0.35


def reverb(x, seconds=1.4, mix=0.18, seed=0):
    """Dry + a convolution tail; a different [seed] per channel gives a wide stereo tail."""
    n = int(seconds * RATE)
    ir = np.random.default_rng(seed).normal(size=n) * np.exp(-np.arange(n) / RATE / (seconds / 5))
    ir = lowpass(ir, 5000)
    ir /= np.sqrt(np.sum(ir ** 2))
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]
    return x + mix * wet


# C major: C G Am F, one chord per bar.
CHORDS = [(48, [60, 64, 67]), (43, [59, 62, 67]), (45, [60, 64, 69]), (41, [60, 65, 69])]
ARP = [0, 1, 2, 1, 2, 3, 2, 1]  # index into chord tones + octave
MELODY = [  # (beat offset in 4-bar phrase, midi, beats)
    (0, 76, 1), (1, 79, 1), (2, 76, 0.5), (2.5, 74, 0.5), (3, 72, 1),
    (4, 74, 1), (5, 79, 1.5), (6.5, 77, 0.5), (7, 76, 1),
    (8, 72, 1), (9, 76, 1), (10, 81, 1), (11, 79, 1),
    (12, 77, 1), (13, 76, 0.5), (13.5, 74, 0.5), (14, 72, 2),
]


def chord_at(bar):
    return CHORDS[bar % 4]


def render():
    drums = np.zeros(N)
    music = np.zeros(N)
    fx = np.zeros(N)

    # 0–2 s: cold open, filtered plucks rising + swell.
    for i in range(8):
        root, tones = chord_at(0)
        m = (tones + [tones[0] + 12])[ARP[i]]
        add(music, pluck(m + 12, 0.25, 1200 + 400 * i), i * BEAT / 2, 0.35)
    add(fx, riser(2.0), 0.0, 0.5)
    # 2 s: title hit.
    add(fx, impact(), 2.0, 0.9)
    add(music, pad([60, 64, 67, 72], 2.0, 3000), 2.0, 0.9)
    add(music, bass(36, 1.8), 2.0, 0.9)
    for i, m in enumerate([84, 88, 91, 96]):
        add(music, bell(m), 2.15 + i * 0.12, 0.6)

    # 4–26 s: groove. Bars 2..12 (4 s .. 26 s).
    for bar in range(2, 13):
        t0 = bar * BAR
        root, tones = chord_at(bar)
        climax = bar >= 11
        build = bar == 10  # 20–22 s
        for b in range(4):
            if not (build and b >= 2):
                add(drums, kick(), t0 + b * BEAT, 0.95)
            if b in (1, 3):
                add(drums, clap(), t0 + b * BEAT, 0.8)
            add(drums, hat(), t0 + b * BEAT + BEAT / 2, 0.9)
            if climax:
                add(drums, hat(), t0 + b * BEAT + BEAT / 4, 0.5)
                add(drums, hat(), t0 + b * BEAT + 3 * BEAT / 4, 0.5)
        if not build:
            add(drums, hat(True), t0 + 3.5 * BEAT, 0.8)
        # Bass: root on 8ths with an octave pop.
        for e in range(8):
            if build and e >= 4:
                break
            m = root + (12 if e in (3, 7) else 0)
            add(music, bass(m, BEAT / 2 * 0.9), t0 + e * BEAT / 2, 0.75)
        # Pluck arpeggio, 8ths.
        for e in range(8):
            m = (tones + [tones[0] + 12])[ARP[e]] + 12
            add(music, pluck(m, 0.22, 3500 if climax else 2600), t0 + e * BEAT / 2, 0.32)
        add(music, pad(tones, BAR, 1800 if not climax else 2600), t0, 0.55)
        # Lead from 12 s.
        if bar >= 6:
            phrase_bar = (bar - 6) % 4
            for off, m, beats in MELODY:
                if phrase_bar * 4 <= off < phrase_bar * 4 + 4:
                    at = t0 + (off - phrase_bar * 4) * BEAT
                    if build and at >= t0 + 2 * BEAT:
                        continue
                    add(music, lead(m, beats * BEAT * 0.95), at, 0.55)
                    if climax:
                        add(music, lead(m + 12, beats * BEAT * 0.95), at, 0.25)
    # Build: snare roll + riser into 22 s.
    t0 = 10 * BAR
    n = 16
    for i in range(n):
        at = t0 + 2 * BEAT + i * (2 * BEAT / n)
        add(drums, snare(), at, 0.25 + 0.6 * i / n)
    add(fx, riser(2.0), 20.0, 0.6)
    add(fx, impact(), 22.0, 0.75)

    # 26 s: final hit, the tonic rings out.
    add(fx, impact(), 26.0, 0.95)
    add(music, pad([48, 60, 64, 67, 72, 76], 3.0, 3200), 26.0, 1.1)
    add(music, bass(36, 3.0), 26.0, 0.9)
    for i, m in enumerate([84, 88, 91, 96, 100]):
        add(music, bell(m, 1.2), 26.1 + i * 0.1, 0.55)

    t = t_of(N)
    pump = np.ones(N)
    for k in np.arange(4.0, 26.0, BEAT):
        if 21.0 <= k < 22.0:
            continue
        idx = (t >= k) & (t < k + 0.25)
        pump[idx] = 0.78 + 0.22 * ((t[idx] - k) / 0.25)
    fade = np.clip((LENGTH - t) / 1.2, 0, 1)
    chans = []
    for seed in (1, 2):
        tonal = reverb(music, 1.6, 0.22, seed) * 0.8 + reverb(fx, 2.0, 0.15, seed + 10) * 0.8
        chans.append((tonal * pump + drums * 0.75) * fade)
    return np.stack(chans, 1)


def sfx_whoosh():
    return whoosh()


def write_wav(path, stereo, rate=RATE):
    data = np.clip(stereo, -1, 1)
    pcm = (data * 32767).astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


if __name__ == '__main__':
    st = render()
    write_wav(sys.argv[1] if len(sys.argv) > 1 else 'promo_music.wav', st / np.max(np.abs(st)) * 0.8)
