"""Draws the Play Store graphics from real app screens.

Writes, under store/:
- screenshots/<locale>/phone/NN_<name>.png: 8 phone screenshots, 1080 x 1920;
- screenshots/<locale>/tablet7/NN_<name>.png and tablet10/: 4 each, 1200 x 1920 and 1600 x 2560;
- feature-graphic-en.png / -fr.png: 1024 x 500;
- icon-512.png: from assets/icon/icon.png.
Locales: en-US and fr-CA (Play's fr-FR listing reuses fr-CA's images).

Each screenshot is a real screen of the app, captured on the emulator by tools/capture_store_shots.py (the promo build
on a staged save, so no ads, no debug banner and a clean status bar) into build/promo/shots/<lang>/<device>/, framed in
a device on a background in the screen's World colours, under a caption in the game's font (Fredoka).
Run: python3 tools/make_store_graphics.py   (needs Pillow + numpy)
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SHOTS = os.environ.get('PROMO_SHOTS', os.path.join(ROOT, 'build', 'promo', 'shots'))
STORE = os.path.join(ROOT, 'store')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Fredoka-Bold.ttf')
FONT_SEMI = os.path.join(ROOT, 'assets', 'fonts', 'Fredoka-SemiBold.ttf')
CRITTERS = os.path.join(ROOT, 'assets', 'critters')
LOCALES = {'en': 'en-US', 'fr': 'fr-CA'}

# Background gradients (top, bottom) and accent per World.
THEMES = {
    'meadow': ((0x5C, 0xB8, 0xF0), (0x3F, 0xA3, 0x4D), (0xFF, 0xD8, 0x4A)),
    'lodge': ((0x2B, 0x1B, 0x3D), (0xC0, 0x5A, 0x22), (0xFF, 0xC0, 0x5A)),
    'neon': ((0x12, 0x0B, 0x33), (0x7A, 0x12, 0x8E), (0x3D, 0xF5, 0xFF)),
    'winter': ((0x14, 0x24, 0x52), (0x6E, 0x9F, 0xD6), (0xB8, 0xF0, 0xFF)),
    'pro': ((0x1A, 0x1D, 0x24), (0x3A, 0x3F, 0x4A), (0xF2, 0xC2, 0x4B)),
    'sunset': ((0xFF, 0x9A, 0x5A), (0xE8, 0x4A, 0x7A), (0xFF, 0xF0, 0x9A)),
}

# (name, world theme, critters peeking at the bottom corners); captions below.
PHONE = [
    ('daily', 'meadow', ('chick', 'pig')),
    ('play', 'lodge', ('bear', 'moose')),
    ('rank', 'sunset', ('owl', 'frog')),
    ('album', 'meadow', ('panda', 'penguin')),
    ('lucky', 'meadow', ('rabbit', 'duck')),
    ('worlds', 'neon', ('zebra', 'dog')),
    ('levels', 'winter', ('walrus', 'penguin')),
    ('gifts', 'lodge', ('horse', 'goat')),
]
TABLET = [('daily', 'meadow', ('chick', 'pig')), ('play', 'lodge', ('bear', 'moose')),
          ('album', 'meadow', ('panda', 'penguin')), ('worlds', 'neon', ('zebra', 'dog'))]
CANVAS = {'phone': (1080, 1920), 'tablet7': (1200, 1920), 'tablet10': (1600, 2560)}

# '*' marks the highlighted words; '|' forces a line break.
CAPTIONS = {
    'en': {
        'daily': '*3 new puzzles*|every day',
        'play': 'Nests, Pairs & Trail:|*clever* little grids',
        'rank': '*Climb* the|leaderboard',
        'album': 'Collect & level up|*30 cute critters*',
        'lucky': '*Lucky Nest*|surprises',
        'worlds': 'Pick your *world*',
        'levels': '*Endless levels*|with stars',
        'gifts': '*Gifts*, trophies &|weekly events',
    },
    'fr': {
        'daily': '*3 nouveaux défis*|chaque jour',
        'play': 'Nids, Paires et Sentier :|de *petites grilles* futées',
        'rank': '*Grimpe* au|classement',
        'album': 'Collectionne|*30 bestioles* trop mignonnes',
        'lucky': 'Les surprises du|*Nid chanceux*',
        'worlds': 'Choisis ton *univers*',
        'levels': '*Des niveaux à l’infini*|et des étoiles',
        'gifts': '*Cadeaux*, trophées et|événements de la semaine',
    },
}
FEATURE = {
    'en': ('Critter Logic', 'Daily Puzzles', '3 new logic puzzles every day'),
    'fr': ('Critter Logic', 'Casse-têtes du jour', '3 nouveaux casse-têtes chaque jour'),
}


def font(size, path=FONT):
    return ImageFont.truetype(path, size)


def gradient(size, top, bottom, angle_mix=0.0):
    w, h = size
    y = np.linspace(0, 1, h)[:, None]
    x = np.linspace(0, 1, w)[None, :]
    t = np.clip(y * (1 - angle_mix) + x * angle_mix, 0, 1)
    t = t * t * (3 - 2 * t)
    arr = np.array(top, float)[None, None, :] * (1 - t[..., None]) + np.array(bottom, float)[None, None, :] * t[..., None]
    return Image.fromarray(arr.astype(np.uint8)).convert('RGBA')


def glow(canvas, center, radius, colour, alpha):
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x, y = center
    d.ellipse((x - radius, y - radius, x + radius, y + radius), fill=colour + (alpha,))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(radius * 0.45)))


def sparkle(draw, x, y, r, colour):
    """A four-point star."""
    pts = []
    for i in range(8):
        a = math.pi / 4 * i
        rr = r if i % 2 == 0 else r * 0.28
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    draw.polygon(pts, fill=colour)


def background(size, theme, seed=0):
    top, bottom, accent = THEMES[theme]
    canvas = gradient(size, top, bottom, 0.15)
    w, h = size
    rnd = np.random.default_rng(seed)
    for _ in range(7):
        glow(canvas, (rnd.uniform(0, w), rnd.uniform(0, h)), rnd.uniform(0.12, 0.3) * w, (255, 255, 255), int(rnd.uniform(14, 34)))
    glow(canvas, (w * 0.5, h * 0.12), w * 0.45, accent, 40)
    d = ImageDraw.Draw(canvas)
    for _ in range(14):
        sparkle(d, rnd.uniform(0, w), rnd.uniform(0, h * 0.95), rnd.uniform(5, 13) * w / 1080, (255, 255, 255, int(rnd.uniform(70, 160))))
    return canvas


def parse_caption(text):
    """Lines of (word, highlighted) from '*marked* words|next line'."""
    lines = []
    for line in text.split('|'):
        words, hot = [], False
        for raw in line.split(' '):
            if not raw:
                continue
            if raw.startswith('*'):
                hot = True
            words.append((raw.replace('*', ''), hot))
            if '*' in raw[1:]:
                hot = False
        lines.append(words)
    return lines


def text_with_shadow(canvas, xy, text, typeface, fill, shadow=(0, 0, 0, 110), offset=6, blur=8, stroke=0, stroke_fill=None):
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((xy[0], xy[1] + offset), text, font=typeface, fill=shadow, stroke_width=stroke,
                               stroke_fill=shadow)
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))
    ImageDraw.Draw(canvas).text(xy, text, font=typeface, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)


def caption(canvas, text, accent, top, max_width, max_size, max_lines_height):
    """Centred caption; highlighted words in [accent]. Shrinks to fit; returns the bottom y."""
    lines = parse_caption(text)
    size = max_size
    while True:
        typeface = font(size)
        space = typeface.getlength(' ')
        widths = [sum(typeface.getlength(w) for w, _ in line) + space * (len(line) - 1) for line in lines]
        height = size * 1.12 * len(lines)
        if max(widths) <= max_width and height <= max_lines_height:
            break
        size -= 2
    y = top + (max_lines_height - height) / 2
    for line, width in zip(lines, widths):
        x = (canvas.width - width) / 2
        for word, hot in line:
            text_with_shadow(canvas, (x, y), word, typeface, accent if hot else (255, 255, 255),
                             stroke=max(2, size // 22), stroke_fill=(40, 30, 60, 255) if hot else (30, 30, 50, 255))
            x += typeface.getlength(word) + space
        y += size * 1.12
    return y


def rounded_mask(size, radius, scale=3):
    m = Image.new('L', (size[0] * scale, size[1] * scale), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, m.width - 1, m.height - 1), radius * scale, fill=255)
    return m.resize(size, Image.LANCZOS)


def device(screen, width, tablet=False):
    """[screen] inside a dark device body [width] px wide (bezel, rounded corners, a side highlight)."""
    bezel = round(width * (0.035 if tablet else 0.04))
    sw = width - 2 * bezel
    sh = round(screen.height * sw / screen.width)
    body = (width, sh + 2 * bezel)
    out = Image.new('RGBA', body, (0, 0, 0, 0))
    radius = round(width * (0.07 if tablet else 0.13))
    shell = Image.new('RGBA', body, (22, 22, 30, 255))
    # A soft rim light on the shell.
    rim = gradient(body, (90, 90, 110), (20, 20, 28), 0.6)
    shell = Image.blend(shell, rim, 0.55)
    out.paste(shell, (0, 0), rounded_mask(body, radius))
    inner = rounded_mask((body[0] - 6, body[1] - 6), radius - 3)
    dark = Image.new('RGBA', (body[0] - 6, body[1] - 6), (8, 8, 12, 255))
    out.paste(dark, (3, 3), inner)
    scr = screen.convert('RGBA').resize((sw, sh), Image.LANCZOS)
    out.paste(scr, (bezel, bezel), rounded_mask((sw, sh), radius - bezel))
    return out


def shadowed(canvas, image, pos, blur=40, alpha=120, dy=24):
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    a = image.split()[3].point(lambda v: v * alpha // 255)
    sh.paste((0, 0, 0, 255), (pos[0], pos[1] + dy), a)
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(image, pos)


def critter(name, size):
    img = Image.open(os.path.join(CRITTERS, name + '.png')).convert('RGBA')
    return img.resize((size, size), Image.LANCZOS)


def compose(lang, kind, index, name, theme, peekers):
    size = CANVAS[kind]
    w, h = size
    s = w / 1080
    tablet = kind != 'phone'
    canvas = background(size, theme, seed=index * 7 + len(kind))
    accent = THEMES[theme][2]
    cap_top = round(70 * s if not tablet else 80 * (h / 1920))
    cap_h = round((300 if not tablet else 300) * (h / 1920))
    bottom = caption(canvas, CAPTIONS[lang][name], accent, cap_top, w - 120 * s, round(104 * h / 1920), cap_h)
    src = Image.open(os.path.join(SHOTS, lang, kind, name + '.png')).convert('RGB')
    top = cap_top + cap_h + round(30 * h / 1920)
    room_h = h - top - round(50 * h / 1920)
    width = min(round(w * (0.74 if tablet else 0.68)), round(room_h * src.width / src.height / 1.02))
    dev = device(src, width, tablet)
    if dev.height > room_h:
        dev = device(src, round(width * room_h / dev.height), tablet)
    x = (w - dev.width) // 2
    # Critters peeking from behind the device's lower corners.
    cs = round(230 * s if not tablet else 200 * s)
    left, right = critter(peekers[0], cs), critter(peekers[1], cs).transpose(Image.FLIP_LEFT_RIGHT)
    ly = top + dev.height - round(cs * 0.95)
    shadowed(canvas, left.rotate(10, resample=Image.BICUBIC, expand=False), (x - round(cs * 0.62), ly), blur=14, alpha=90, dy=8)
    shadowed(canvas, right.rotate(-10, resample=Image.BICUBIC, expand=False), (x + dev.width - round(cs * 0.38), ly - round(cs * 0.35)), blur=14, alpha=90, dy=8)
    shadowed(canvas, dev, (x, top), blur=round(36 * s), alpha=150, dy=round(22 * s))
    folder = os.path.join(STORE, 'screenshots', LOCALES[lang], kind)
    os.makedirs(folder, exist_ok=True)
    canvas.convert('RGB').save(os.path.join(folder, f'{index:02d}_{name}.png'), optimize=True)


def board_crop(lang, name, box):
    img = Image.open(os.path.join(SHOTS, lang, 'phone', name + '.png')).convert('RGBA')
    return img.crop(box)


def feature_graphic(lang):
    w, h = 1024, 500
    canvas = background((w, h), 'meadow', seed=5)
    # Lighter sky at the top, grass hill at the bottom.
    hill = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(hill).ellipse((-200, 380, 1224, 900), fill=(0x4F, 0xB0, 0x4C, 255))
    canvas.alpha_composite(hill)
    title, sub, line = FEATURE[lang]
    # Three boards fanned on the right.
    boards = [('board_pairs', -9, (615, 150)), ('board_trail', 8, (800, 150)), ('board_nests', 0, (705, 85))]
    for name, angle, (bx, by) in boards:
        src = Image.open(os.path.join(SHOTS, lang, 'phone', name + '.png')).convert('RGBA')
        side = 225 if name == 'board_nests' else 180
        b = src.resize((side, side), Image.LANCZOS)
        framed = Image.new('RGBA', (side + 16, side + 16), (0, 0, 0, 0))
        ImageDraw.Draw(framed).rounded_rectangle((0, 0, side + 15, side + 15), 26, fill=(0x8A, 0x5A, 0x2E, 255))
        framed.paste(b, (8, 8), rounded_mask((side, side), 20))
        framed = framed.rotate(angle, resample=Image.BICUBIC, expand=True)
        shadowed(canvas, framed, (bx - framed.width // 2 + side // 2, by), blur=16, alpha=110, dy=10)
    # Icon + title on the left.
    icon = Image.open(os.path.join(ROOT, 'assets', 'icon', 'icon.png')).convert('RGBA').resize((150, 150), Image.LANCZOS)
    iconr = Image.new('RGBA', icon.size, (0, 0, 0, 0))
    iconr.paste(icon, (0, 0), rounded_mask(icon.size, 34))
    shadowed(canvas, iconr, (70, 70), blur=12, alpha=110, dy=8)
    t = font(64)
    text_with_shadow(canvas, (240, 86), title, t, (255, 255, 255), stroke=4, stroke_fill=(60, 40, 20, 255))
    text_with_shadow(canvas, (244, 165), sub, font(40), THEMES['meadow'][2], stroke=3, stroke_fill=(60, 40, 20, 255))
    lf = font(30, FONT_SEMI)
    pill_w = lf.getlength(line) + 48
    pill = Image.new('RGBA', (round(pill_w), 58), (0, 0, 0, 0))
    ImageDraw.Draw(pill).rounded_rectangle((0, 0, pill.width - 1, 57), 29, fill=(255, 255, 255, 235))
    ImageDraw.Draw(pill).text((24, 10), line, font=lf, fill=(0x5B, 0x3A, 0x1A))
    shadowed(canvas, pill, (72, 262), blur=8, alpha=80, dy=5)
    # Critters on the grass.
    for name, size, x, y, flip in [('chick', 110, 70, 360, False), ('pig', 120, 180, 350, False), ('frog', 110, 300, 362, False),
                                   ('panda', 118, 420, 352, True), ('penguin', 104, 545, 370, True)]:
        c = critter(name, size)
        if flip:
            c = c.transpose(Image.FLIP_LEFT_RIGHT)
        shadowed(canvas, c, (x, y), blur=8, alpha=70, dy=6)
    canvas.convert('RGB').save(os.path.join(STORE, f'feature-graphic-{lang}.png'), optimize=True)


def icon_512():
    Image.open(os.path.join(ROOT, 'assets', 'icon', 'icon.png')).convert('RGB').resize((512, 512), Image.LANCZOS).save(
        os.path.join(STORE, 'icon-512.png'), optimize=True)


def main():
    icon_512()
    for lang in LOCALES:
        for i, (name, theme, peek) in enumerate(PHONE, 1):
            compose(lang, 'phone', i, name, theme, peek)
        for kind in ('tablet7', 'tablet10'):
            for i, (name, theme, peek) in enumerate(TABLET, 1):
                compose(lang, kind, i, name, theme, peek)
        feature_graphic(lang)
    print('done')


if __name__ == '__main__':
    main()
