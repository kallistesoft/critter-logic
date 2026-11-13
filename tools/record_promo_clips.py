"""Records the gameplay clips for the promo videos on the emulator (setup: tools/promo_device.py).

    python3 tools/record_promo_clips.py en [clip ...]

Writes build/promo/clips/<lang>_<clip>.mp4 (adb screenrecord, 1080 x 2424, 20 Mb/s) and <lang>_events.json: when
things happen in each recording (a solve, the egg cracking, a capsule reveal...), found from the frames themselves, for
tools/make_promo_video.py. Clips: nests, nests_neon, pairs, trail, level_pairs, lucky, capsule, album and home_<world>
for the five Worlds. The dailies are played with their real solutions (from assets/dailies), after a pause so the
ranked time looks human.
"""
import json
import os
import subprocess
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from promo_device import *  # noqa: E402,F403

CLIPS = os.path.join(OUT, 'clips')
FFMPEG = os.environ.get('FFMPEG', 'ffmpeg')
WORLDS = ['meadow', 'lodge', 'neon', 'winter', 'pro']
# Clean Pro lays the home out differently.
PLAY_PRO = {'nests': (196, 1350)}


def clip_path(lang, name):
    return os.path.join(CLIPS, f'{lang}_{name}.mp4')


def diffs(path, fps=10):
    """Mean frame-to-frame change (0–255) at [fps], index i = change into frame i+1."""
    w, h = 90, 202
    raw = subprocess.run([FFMPEG, '-v', 'error', '-i', path, '-vf', f'fps={fps},scale={w}:{h}', '-f', 'rawvideo',
                          '-pix_fmt', 'gray', '-'], capture_output=True).stdout
    a = np.frombuffer(raw, np.uint8).reshape(-1, h, w).astype(np.float32)
    return np.abs(np.diff(a, axis=0)).mean(axis=(1, 2))


def spikes(path, threshold, after=0.0):
    d = diffs(path)
    return [round((i + 1) / 10, 2) for i, v in enumerate(d) if v >= threshold and (i + 1) / 10 > after]


def first_spike(path, threshold, after=0.0):
    s = spikes(path, threshold, after)
    if not s:
        raise SystemExit(f'no event found in {path}')
    return s[0]


def daily_game(lang, game, world='world.meadow', name=None):
    name = name or game
    d = daily()
    p = d[game]
    launch(lang, world)
    tap(*PLAY[game], 1.0)
    if game == 'nests':
        g = grid(NESTS_BOX, 8)
        cells = nests_cells(p)
        taps([g(cells[0]), g(cells[0])], 0.15)
        taps([g(cells[3]), g(cells[3])], 0.15)
        time.sleep(28)
        rec_start(clip_path(lang, name))
        time.sleep(0.8)
        taps([g(cells[1] + 1)])
        time.sleep(0.5)
        for c in [cells[1], cells[2], cells[4], cells[5], cells[6], cells[7]]:
            taps([g(c), g(c)], 0.12)
            time.sleep(0.45)
    elif game == 'pairs':
        todo = [i for i in range(64) if p['g'][i] == '.']
        for c in todo[:20]:
            taps(pairs_taps(p, c), 0.05)
        time.sleep(20)
        rec_start(clip_path(lang, name))
        time.sleep(0.5)
        for c in todo[20:]:
            taps(pairs_taps(p, c), 0.05)
    else:
        time.sleep(30)
        rec_start(clip_path(lang, name))
        time.sleep(0.5)
        drag(trail_drag_points(p), hold=0.2, step=0.035)
    time.sleep(7)
    swipe(540, 1900, 540, 1100, 900)
    time.sleep(3)
    path = rec_stop()
    result = first_spike(path, 10, 1.0)  # the result screen slides in ~1.8 s after the last move
    ev = {'solve': round(result - 1.8, 2), 'result': result, 'lead': 4.0}
    if name == 'nests_neon':
        ev['place'] = round(ev['solve'] - 2.3, 2)  # a critter popping in, two moves before the solve
    return ev


def level_pairs(lang):
    p = level_puzzles()['pairs']
    launch(lang)
    rec_start(clip_path(lang, 'level_pairs'))
    tap(*LEVELS['pairs'], 1.6)
    tap(*NODE['pairs'], 1.4)
    for c in range(36):
        if p['g'][c] == '.':
            taps(pairs_taps(p, c), 0.05)
    time.sleep(7)
    path = rec_stop()
    dialog = spikes(path, 20)[-1]  # the "Level solved" card
    return {'solve': round(dialog - 0.5, 2)}


def lucky(lang):
    launch(lang, seed=1)  # seed 1: the free egg holds coins
    rec_start(clip_path(lang, 'lucky'))
    tap(*LUCKY_NEST, 2.0)
    tap(540, 1585, 1.2)  # "Free egg"
    tap(540, 1150, 6.0)
    path = rec_stop()
    opened = first_spike(path, 10)
    return {'open': opened, 'tap': round(opened + 2.9, 2), 'prize': round(opened + 4.1, 2)}


def capsule(lang):
    launch(lang)
    scroll_home()
    rec_start(clip_path(lang, 'capsule'))
    tap(*CAPSULES, 1.5)
    for _ in range(4):
        tap(540, 1200, 0.7)
    time.sleep(4)
    path = rec_stop()
    opened = first_spike(path, 10)
    reveal = first_spike(path, 8, opened + 1.5)
    return {'open': opened, 'reveal': reveal, 'tap1': round(reveal - 1.7, 2)}


def album(lang):
    launch(lang)
    scroll_home()
    rec_start(clip_path(lang, 'album'))
    tap(*ALBUM, 2.0)
    swipe(540, 1900, 540, 900, 1400)
    time.sleep(0.6)
    swipe(540, 1900, 540, 900, 1400)
    time.sleep(1.5)
    path = rec_stop()
    return {'open': first_spike(path, 10)}


def home(lang, world):
    launch(lang, 'world.' + world, wait=6)
    rec_start(clip_path(lang, 'home_' + world))
    time.sleep(2.5)
    tap(*(PLAY_PRO['nests'] if world == 'pro' else PLAY['nests']), 2.5)
    path = rec_stop()
    board = first_spike(path, 8, 1.5)
    return {'home': 1.0, 'board': round(board + 0.6, 2)}


def record(lang, names):
    os.makedirs(CLIPS, exist_ok=True)
    events_path = os.path.join(CLIPS, f'{lang}_events.json')
    events = json.load(open(events_path)) if os.path.exists(events_path) else {}
    for name in names:
        print('recording', lang, name, flush=True)
        if name in ('nests', 'pairs', 'trail'):
            ev = daily_game(lang, name)
        elif name == 'nests_neon':
            ev = daily_game(lang, 'nests', 'world.neon', 'nests_neon')
        elif name.startswith('home_'):
            ev = home(lang, name[5:])
        else:
            ev = globals()[name](lang)
        events[name] = ev
        print(' ', ev, flush=True)
        with open(events_path, 'w') as f:
            json.dump(events, f, indent=1)


ALL = ['nests_neon', 'nests', 'pairs', 'trail', 'level_pairs', 'lucky', 'capsule', 'album'] + ['home_' + w for w in WORLDS]

if __name__ == '__main__':
    lang = sys.argv[1] if len(sys.argv) > 1 else 'en'
    names = sys.argv[2:] or ALL
    old = setup()
    try:
        record(lang, names)
    finally:
        teardown(old)
