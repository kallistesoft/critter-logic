"""Drives the store-promo build (tools/promo_main.dart) on an Android emulator: launch with a staged save, taps, drags,
screenshots and screen recordings. Shared by tools/capture_store_shots.py and tools/record_promo_clips.py.

The emulator must run the profile build of the promo entry point (package ca.kallistesoft.critterlogic.dev):
    flutter build apk --profile -t tools/promo_main.dart
    adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-profile.apk
Set PROMO_SERIAL to use another emulator (never a phone: the promo build replaces the dev app's data).

Coordinates are for a 1080 x 2424 phone screen (Pixel 9 emulator, density 420).
"""
import json
import os
import subprocess
import time

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SERIAL = os.environ.get('PROMO_SERIAL', 'emulator-5554')
if not SERIAL.startswith('emulator-'):
    raise SystemExit('PROMO_SERIAL must be an emulator')
ADB = [os.path.expanduser('~/Library/Android/sdk/platform-tools/adb'), '-s', SERIAL]
PKG = 'ca.kallistesoft.critterlogic.dev'
OUT = os.environ.get('PROMO_OUT', os.path.join(ROOT, 'build', 'promo'))

# Board boxes (left, top, right, bottom) on the phone screen; the same for every board size.
NESTS_BOX = (63, 785, 1018, 1741)
PAIRS_BOX = (72, 815, 1008, 1751)
TRAIL_BOX = (64, 786, 1016, 1744)
# Home screen (not scrolled).
PLAY = {'nests': (196, 1470), 'pairs': (540, 1470), 'trail': (884, 1470)}
LEVELS = {'nests': (196, 1860), 'pairs': (540, 1860), 'trail': (884, 1860)}
# Home scrolled to the end (see scroll_home).
ALBUM, CAPSULES = (280, 1900), (800, 1900)
SHOP, LUCKY_NEST, CALENDAR, TROPHIES = (140, 2270), (950, 2260), (666, 230), (797, 230)
# The current level's node on each level path (levels 38 / 26 / 21 of the staged save).
NODE = {'nests': (249, 1987), 'pairs': (424, 1988), 'trail': (786, 1990)}
SHOP_TABS = {'capsules': (160, 386), 'hats': (412, 386), 'worlds': (663, 386), 'coins': (920, 386)}


def adb(*args):
    return subprocess.run(ADB + list(args), capture_output=True, text=True).stdout


def sh(script):
    """Runs one shell script on the device (many input commands in one adb call)."""
    return subprocess.run(ADB + ['shell', script], capture_output=True, text=True).stdout


DEMO = ['settings put global sysui_demo_allowed 1',
        'am broadcast -a com.android.systemui.demo -e command enter',
        'am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941',
        'am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false',
        # One SIM, no mobile data icon, full Wi-Fi; no other status icons.
        'am broadcast -a com.android.systemui.demo -e command network -e sims 1',
        'am broadcast -a com.android.systemui.demo -e command network -e mobile hide',
        'am broadcast -a com.android.systemui.demo -e command network -e nosim hide',
        'am broadcast -a com.android.systemui.demo -e command network -e airplane hide',
        'am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 -e fully true',
        'am broadcast -a com.android.systemui.demo -e command status -e volume hide -e bluetooth hide '
        '-e location hide -e alarm hide -e zen hide -e sync hide -e tty hide -e eri hide -e mute hide '
        '-e speakerphone hide -e managed_profile hide',
        'am broadcast -a com.android.systemui.demo -e command notifications -e visible false']


def demo_mode():
    """System UI demo mode: 9:41, full battery, Wi-Fi only, no notifications. Re-entered from scratch, so a display
    change doesn't leave stale icons behind."""
    sh('am broadcast -a com.android.systemui.demo -e command exit')
    time.sleep(0.5)
    for cmd in DEMO:
        sh(cmd)


def display(size=None, density=None):
    """A tablet-sized display override (None: back to the phone), then a fresh demo mode."""
    sh(f'wm size {size}; wm density {density}' if size else 'wm size reset; wm density reset')
    time.sleep(2.5)
    demo_mode()
    time.sleep(0.5)


def setup():
    """Clean status bar (System UI demo mode) and animations on; returns the previous animation scales."""
    old = [sh(f'settings get global {k}').strip() for k in ANIM_KEYS]
    for k in ANIM_KEYS:
        sh(f'settings put global {k} 1')
    demo_mode()
    return old


ANIM_KEYS = ['animator_duration_scale', 'transition_animation_scale', 'window_animation_scale']


def teardown(old):
    """Leaves demo mode and puts the animation scales back."""
    sh('am broadcast -a com.android.systemui.demo -e command exit')
    sh('settings put global sysui_demo_allowed 0')
    for k, v in zip(ANIM_KEYS, old):
        if v and v != 'null':
            sh(f'settings put global {k} {v}')
    sh('wm size reset; wm density reset')


def launch(lang='en', world='world.meadow', reset=True, wait=5.0, seed=1, **extra):
    """Restarts the app on a fresh staged save (see tools/promo_main.dart)."""
    cfg = dict(lang=lang, world=world, reset=str(reset).lower(), seed=seed, **extra)
    arg = ','.join(f'{k}={v}' for k, v in cfg.items())
    adb('shell', 'am', 'force-stop', PKG)
    adb('shell', 'am', 'start', '-n', f'{PKG}/ca.kallistesoft.critterlogic.MainActivity',
        '--esal', 'dart_entrypoint_args', arg)
    time.sleep(wait)


def tap(x, y, wait=0.0):
    sh(f'input tap {int(x)} {int(y)}')
    time.sleep(wait)


def taps(points, gap=0.0):
    parts = []
    for x, y in points:
        parts.append(f'input tap {int(x)} {int(y)}')
        if gap:
            parts.append(f'sleep {gap}')
    sh('; '.join(parts))


def drag(points, hold=0.0, step=0.0):
    """One finger along [points] (a Trail path)."""
    parts = [f'input motionevent DOWN {int(points[0][0])} {int(points[0][1])}']
    if hold:
        parts.append(f'sleep {hold}')
    for x, y in points[1:]:
        parts.append(f'input motionevent MOVE {int(x)} {int(y)}')
        if step:
            parts.append(f'sleep {step}')
    parts.append(f'input motionevent UP {int(points[-1][0])} {int(points[-1][1])}')
    sh('; '.join(parts))


def swipe(x1, y1, x2, y2, ms=400):
    sh(f'input swipe {x1} {y1} {x2} {y2} {ms}')


def scroll_home():
    """Scrolls the home screen to its end, slowly (no fling), so ALBUM and CAPSULES are where expected."""
    swipe(540, 1700, 540, 1100, 1500)
    time.sleep(0.8)


def back(wait=0.8):
    sh('input keyevent 4')
    time.sleep(wait)


def shot(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(subprocess.run(ADB + ['exec-out', 'screencap', '-p'], capture_output=True).stdout)


_rec = None


def rec_start(path):
    global _rec
    adb('shell', 'rm', '-f', '/sdcard/promo_clip.mp4')
    _rec = (path, subprocess.Popen(ADB + ['shell', 'screenrecord', '--bit-rate', '20000000', '/sdcard/promo_clip.mp4']))
    time.sleep(1.0)


def rec_stop():
    global _rec
    path, p = _rec
    time.sleep(0.6)
    sh('pkill -INT screenrecord')
    p.wait(timeout=20)
    time.sleep(1.0)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    adb('pull', '/sdcard/promo_clip.mp4', path)
    adb('shell', 'rm', '-f', '/sdcard/promo_clip.mp4')
    _rec = None
    return path


def grid(box, n):
    """Cell centre of cell i on an n x n board inside [box]."""
    x0, y0, x1, y1 = box
    cw, ch = (x1 - x0) / n, (y1 - y0) / n
    return lambda i: (x0 + (i % n + 0.5) * cw, y0 + (i // n + 0.5) * ch)


def daily(n=13):
    """Daily #n's puzzles with their solutions, from the bundle."""
    out = {}
    for g in ['nests', 'pairs', 'trail']:
        with open(os.path.join(ROOT, 'assets', 'dailies', g + '.json')) as f:
            d = json.load(f)
        out[g] = d['puzzles'][n - d['first']]
    return out


def level_puzzles(nests=38, pairs=26, trail=21):
    """The staged save's current levels, generated by the app's own code (dart)."""
    script = os.path.join(OUT, 'levels_dump.dart')
    os.makedirs(OUT, exist_ok=True)
    with open(script, 'w') as f:
        f.write("import 'dart:convert';\nimport 'package:critter_logic/puzzles/levels.dart';\n"
                "void main(List<String> a) => print(jsonEncode({'nests': generateNestsLevel(int.parse(a[0])).toJson(),"
                " 'pairs': generatePairsLevel(int.parse(a[1])).toJson(), 'trail': generateTrailLevel(int.parse(a[2])).toJson()}));\n")
    out = subprocess.run(['dart', '--packages=' + os.path.join(ROOT, '.dart_tool', 'package_config.json'), script,
                          str(nests), str(pairs), str(trail)], capture_output=True, text=True, check=True, cwd=ROOT).stdout
    return json.loads(out)


def trail_path(p):
    size = p['s']
    path = [p['n'][0]]
    for m in p['x']:
        path.append(path[-1] + {'R': 1, 'L': -1, 'D': size, 'U': -size}[m])
    return path


def nests_cells(p):
    return [r * p['s'] + int(c) for r, c in enumerate(p['x'])]


def pairs_taps(p, cell, box=PAIRS_BOX):
    """The taps that fill [cell] with its solution (one tap = sun, two = moon)."""
    at = grid(box, p['s'])(cell)
    return [at] * (1 if p['x'][cell] == '0' else 2)


def trail_drag_points(p, box=TRAIL_BOX, upto=None):
    path = trail_path(p)[:upto]
    g = grid(box, p['s'])
    pts = [g(path[0])]
    for a, b in zip(path, path[1:]):
        (x0, y0), (x1, y1) = g(a), g(b)
        pts += [((x0 * 2 + x1) / 3, (y0 * 2 + y1) / 3), ((x0 + x1 * 2) / 3, (y0 + y1 * 2) / 3)]
    pts.append(g(path[-1]))
    return pts
