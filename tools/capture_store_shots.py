"""Captures the raw app screens for the store screenshots on the emulator (see tools/promo_device.py for the setup).

Writes build/promo/shots/<lang>/{phone,tablet7,tablet10}/<name>.png, then run tools/make_store_graphics.py.
Tablets are the same emulator with a tablet-sized display override (wm size / density), reset at the end.
Run: python3 tools/capture_store_shots.py [en fr] [--phone-only]
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(__file__))
from promo_device import *  # noqa: E402,F403

DISPLAYS = {'phone': None, 'tablet7': ('1200x1920', 320), 'tablet10': ('1600x2560', 320)}


def path(lang, kind, name):
    return os.path.join(OUT, 'shots', lang, kind, name + '.png')


def crop_board(src, dst, box, pad=34):
    from PIL import Image
    x0, y0, x1, y1 = box
    Image.open(src).crop((x0 - pad, y0 - pad, x1 + pad, y1 + pad)).save(dst)


def phone(lang):
    d = daily()
    k = 'phone'
    launch(lang, 'world.meadow', wait=6)
    shot(path(lang, k, 'daily'))

    # Mid-solve boards (Meadow) for the feature graphic.
    tap(*PLAY['nests'], 1.5)
    cells = nests_cells(d['nests'])
    g = grid(NESTS_BOX, 8)
    for c in cells[:4]:
        taps([g(c), g(c)], 0.1)
    taps([g(cells[5] + 1), g(cells[6] - 1)], 0.1)
    time.sleep(1.5)
    shot(path(lang, k, 'board_nests_full'))
    crop_board(path(lang, k, 'board_nests_full'), path(lang, k, 'board_nests'), NESTS_BOX)
    back()
    tap(*PLAY['pairs'], 1.5)
    todo = [i for i in range(64) if d['pairs']['g'][i] == '.']
    for c in todo[:22]:
        taps(pairs_taps(d['pairs'], c), 0.05)
    time.sleep(1.5)
    shot(path(lang, k, 'board_pairs_full'))
    crop_board(path(lang, k, 'board_pairs_full'), path(lang, k, 'board_pairs'), PAIRS_BOX)
    back()
    tap(*PLAY['trail'], 1.5)
    drag(trail_drag_points(d['trail'], upto=24), hold=0.2, step=0.02)
    time.sleep(1.5)
    shot(path(lang, k, 'board_trail_full'))
    crop_board(path(lang, k, 'board_trail_full'), path(lang, k, 'board_trail'), TRAIL_BOX)
    # The rest of the trail: the result with the ranking.
    back()
    tap(*PLAY['trail'], 1.5)
    time.sleep(30)  # a believable time
    drag(trail_drag_points(d['trail']), hold=0.2, step=0.02)
    time.sleep(8)
    shot(path(lang, k, 'rank'))

    # Nests mid-solve in the Wild Lodge.
    launch(lang, 'world.lodge', wait=6)
    tap(*PLAY['nests'], 1.5)
    for c in [cells[0], cells[2], cells[3], cells[5]]:
        taps([g(c), g(c)], 0.1)
    taps([g(cells[1] + 2)], 0.1)
    time.sleep(1.5)
    shot(path(lang, k, 'play'))

    launch(lang, 'world.meadow', wait=6)
    scroll_home()
    tap(*ALBUM, 2.5)
    shot(path(lang, k, 'album'))

    launch(lang, 'world.meadow', seed=1, wait=6)
    tap(*LUCKY_NEST, 2.0)
    tap(540, 1585, 1.0)
    tap(540, 1150, 5.5)
    shot(path(lang, k, 'lucky'))

    launch(lang, 'world.neon', wait=6)
    tap(*SHOP, 1.8)
    tap(*SHOP_TABS['worlds'], 1.8)
    shot(path(lang, k, 'worlds'))

    launch(lang, 'world.winter', wait=6)
    tap(*LEVELS['nests'], 2.5)
    shot(path(lang, k, 'levels'))

    launch(lang, 'world.lodge', calendar='true', wait=7)
    shot(path(lang, k, 'gifts'))


def tablet(lang, kind):
    """Home, a board, the album and the Worlds shop on a tablet-sized display. Positions come from the layout's
    proportions on these displays (measured once from screenshots)."""
    size, density = DISPLAYS[kind]
    sh(f'wm size {size}; wm density {density}')
    time.sleep(2)
    w, h = map(int, size.split('x'))
    pos = TABLET_POS[kind]
    launch(lang, 'world.meadow', wait=7)
    shot(path(lang, kind, 'daily'))
    launch(lang, 'world.lodge', wait=7)
    tap(*pos['nests'], 2.0)
    box = pos['nests_box']
    g = grid(box, 8)
    cells = nests_cells(daily()['nests'])
    for c in [cells[0], cells[2], cells[3], cells[5]]:
        taps([g(c), g(c)], 0.1)
    taps([g(cells[1] + 2)], 0.1)
    time.sleep(1.5)
    shot(path(lang, kind, 'play'))
    launch(lang, 'world.meadow', wait=7)
    swipe(w // 2, int(h * 0.7), w // 2, int(h * 0.3), 1500)
    time.sleep(1)
    tap(*pos['album'], 2.5)
    shot(path(lang, kind, 'album'))
    launch(lang, 'world.neon', wait=7)
    tap(*pos['shop'], 2.0)
    tap(*pos['worlds_tab'], 2.0)
    shot(path(lang, kind, 'worlds'))


# Tap targets on the tablet displays (measured from screenshots of the promo build).
TABLET_POS = {
    'tablet7': dict(nests=(216, 1411), nests_box=(170, 602, 1025, 1452), album=(269, 1440), shop=(115, 1776),
                    worlds_tab=(741, 357)),
    'tablet10': dict(nests=(253, 1792), nests_box=(192, 777, 1405, 1981), album=(307, 1952), shop=(125, 2384),
                     worlds_tab=(985, 456)),
}


if __name__ == '__main__':
    langs = [a for a in sys.argv[1:] if not a.startswith('--')] or ['en', 'fr']
    old = setup()
    try:
        for lang in langs:
            phone(lang)
            if '--phone-only' not in sys.argv:
                for kind in ('tablet7', 'tablet10'):
                    tablet(lang, kind)
                sh('wm size reset; wm density reset')
    finally:
        teardown(old)
