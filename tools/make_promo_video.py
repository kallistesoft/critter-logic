"""Edits the Play Store promo videos from real gameplay recordings.

    python3 tools/make_promo_video.py [en|fr ...] [--format 16x9|9x16] [--frames 0,90,450] [--draft]

Writes store/video/promo-<lang>-<16x9|9x16>.mp4 (H.264 + AAC, 1920 x 1080 or 1080 x 1920, 30 fps, 30 s).

Footage: tools/record_promo_clips.py records the promo build (tools/promo_main.dart) on the Android emulator with
`adb shell screenrecord` into build/promo/clips/<lang>_<clip>.mp4: real taps, real animations. This script cuts it to
the soundtrack (tools/make_promo_music.py, 120 BPM) as a trailer: a cold open on a glowing Night Neon board, a title
hit, the three games (each ending on its solve), the coins they earn, the Lucky Nest, capsules and the album, a
beat-cut montage of the five Worlds, and an end card. Every frame is drawn here with Pillow + numpy: the recording in a
floating device with camera moves (eased push-ins, tilts, whip pans with motion blur, speed ramps), a blurred
background in the shot's colours, kinetic captions in Fredoka, sparkles on rewards, a vignette and a grade per section.
Game sound effects (assets/sfx) are layered on the music, then the mix is levelled to about -14 LUFS.
`--frames` writes stills of those frame numbers instead (to check the look); `--draft` renders at half size.
"""
import argparse
import math
import os
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import make_promo_music as music  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
CLIPS = os.environ.get('PROMO_CLIPS', os.path.join(ROOT, 'build', 'promo', 'clips'))
WORK = os.environ.get('PROMO_WORK', os.path.join(ROOT, 'build', 'promo', 'video'))
OUT = os.path.join(ROOT, 'store', 'video')
FFMPEG = os.environ.get('FFMPEG', 'ffmpeg')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'Fredoka-Bold.ttf')
FONT_SEMI = os.path.join(ROOT, 'assets', 'fonts', 'Fredoka-SemiBold.ttf')
FPS = 30
SRC_FPS = 60
LENGTH = 30.0
SRC_W, SRC_H = 720, 1616  # recordings (1080 x 2424) are decoded at this size
GOLD = (255, 216, 74)
INK = (42, 24, 64)

# --------------------------------------------------------------------------------------------------------------------
# Text

TEXT = {
    'en': {
        'title': 'Critter *Logic*', 'tagline': 'Daily Puzzles',
        'daily': '*3 new puzzles*|every day',
        'nests': 'Nests', 'pairs': 'Pairs', 'trail': 'Trail',
        'nests_sub': 'one critter per row & zone', 'pairs_sub': 'suns & moons in balance', 'trail_sub': 'one path, stones in order',
        'coins': 'Solve puzzles,|*earn coins!*',
        'rank': 'Beat players|*worldwide*',
        'lucky': 'Crack the|*Lucky Nest*',
        'critters': 'Collect *30*|cute critters',
        'levelup': 'Level them up *⭐*',
        'worlds': '*5 Worlds*|to explore',
        'free': 'Free on Google Play',
        'end_sub': 'New puzzles every day',
    },
    'fr': {
        'title': 'Critter *Logic*', 'tagline': 'Casse-têtes du jour',
        'daily': '*3 nouveaux défis*|chaque jour',
        'nests': 'Nids', 'pairs': 'Paires', 'trail': 'Sentier',
        'nests_sub': 'une bestiole par ligne et zone', 'pairs_sub': 'soleils et lunes en équilibre', 'trail_sub': 'un seul chemin, dans l’ordre',
        'coins': 'Résous des|casse-têtes,|*gagne des pièces !*',
        'rank': 'Défie les joueurs|*du monde entier*',
        'lucky': 'Ouvre le|*Nid chanceux*',
        'critters': 'Collectionne|*30* bestioles',
        'levelup': 'Fais-les monter *⭐*',
        'worlds': '*5 univers*|à explorer',
        'free': 'Gratuit sur Google Play',
        'end_sub': 'De nouveaux défis chaque jour',
    },
    'es': {
        'title': 'Critter *Logic*', 'tagline': 'Retos diarios',
        'daily': '*3 retos nuevos*|cada día',
        'nests': 'Nidos', 'pairs': 'Parejas', 'trail': 'Sendero',
        'nests_sub': 'un animalito por fila y zona', 'pairs_sub': 'soles y lunas en equilibrio', 'trail_sub': 'un solo camino, en orden',
        'coins': '¡Resuelve retos|*y gana monedas!*',
        'rank': 'Compite con|*todo el mundo*',
        'lucky': 'Abre el|*Nido de la suerte*',
        'critters': 'Colecciona|*30* animalitos',
        'levelup': 'Súbelos de nivel *⭐*',
        'worlds': '*5 mundos*|por explorar',
        'free': 'Gratis en Google Play',
        'end_sub': 'Retos nuevos cada día',
    },
}

# --------------------------------------------------------------------------------------------------------------------
# Easing


def clamp01(x):
    return max(0.0, min(1.0, x))


def smooth(x):
    x = clamp01(x)
    return x * x * (3 - 2 * x)


def ease_out_cubic(x):
    x = clamp01(x)
    return 1 - (1 - x) ** 3


def ease_in_cubic(x):
    x = clamp01(x)
    return x ** 3


def ease_out_back(x, s=1.9):
    x = clamp01(x)
    return 1 + (s + 1) * (x - 1) ** 3 + s * (x - 1) ** 2


def keyframes(t, keys, ease=smooth):
    """Interpolates [(time, value or tuple), ...] at [t] with [ease] between keys."""
    if t <= keys[0][0]:
        return keys[0][1]
    for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
        if t <= t1:
            u = ease((t - t0) / (t1 - t0)) if t1 > t0 else 1
            if isinstance(v0, dict):
                return {k: v0[k] + (v1[k] - v0[k]) * u for k in v0}
            if isinstance(v0, tuple):
                return tuple(a + (b - a) * u for a, b in zip(v0, v1))
            return v0 + (v1 - v0) * u
    return keys[-1][1]


def linear(x):
    return clamp01(x)


# --------------------------------------------------------------------------------------------------------------------
# Footage


class Source:
    """Frames of a recording at SRC_FPS from [start], decoded on demand and read forwards only."""

    def __init__(self, clip, start, length, scale=1.0):
        path = os.path.join(CLIPS, clip + '.mp4')
        self.w, self.h = round(SRC_W * scale) // 2 * 2, round(SRC_H * scale) // 2 * 2
        self.start = start
        self.proc = subprocess.Popen(
            [FFMPEG, '-v', 'quiet', '-ss', f'{max(0, start):.3f}', '-t', f'{length + 0.5:.3f}', '-i', path,
             '-vf', f'fps={SRC_FPS},scale={self.w}:{self.h}:flags=lanczos', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'],
            stdout=subprocess.PIPE)
        self.index = -1
        self.frame = None

    def at(self, t):
        """The frame at clip time [t] (seconds, absolute in the recording)."""
        want = max(0, round((t - self.start) * SRC_FPS))
        size = self.w * self.h * 3
        while self.index < want:
            buf = self.proc.stdout.read(size)
            if len(buf) < size:
                break
            self.frame = np.frombuffer(buf, np.uint8).reshape(self.h, self.w, 3)
            self.index += 1
        return self.frame

    def close(self):
        self.proc.stdout.close()
        self.proc.kill()
        self.proc.wait()


# --------------------------------------------------------------------------------------------------------------------
# Device, background, camera


def rounded_mask(size, radius, scale=2):
    m = Image.new('L', (size[0] * scale, size[1] * scale), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, m.width - 1, m.height - 1), radius * scale, fill=255)
    return m.resize(size, Image.LANCZOS)


class Device:
    """A phone body around the recorded screen (screen at SRC_W x SRC_H)."""

    def __init__(self):
        self.bezel = 26
        self.size = (SRC_W + 2 * self.bezel, SRC_H + 2 * self.bezel)
        r = 92
        body = Image.new('RGBA', self.size, (0, 0, 0, 0))
        g = np.linspace(0, 1, self.size[0])[None, :, None]
        shell = (np.array([92, 92, 112]) * (1 - g) + np.array([24, 24, 32]) * g)
        shell = np.repeat(shell, self.size[1], 0)
        body.paste(Image.fromarray(shell.astype(np.uint8)).convert('RGBA'), (0, 0), rounded_mask(self.size, r))
        inner = rounded_mask((self.size[0] - 8, self.size[1] - 8), r - 4)
        body.paste((10, 10, 14, 255), (4, 4), inner)
        self.body = body
        self.screen_mask = rounded_mask((SRC_W, SRC_H), r - self.bezel)
        # A soft glass sheen across the top-left.
        sheen = Image.new('L', (SRC_W, SRC_H), 0)
        ImageDraw.Draw(sheen).polygon([(0, 0), (SRC_W * 0.55, 0), (0, SRC_H * 0.32)], fill=22)
        self.sheen = ImageChops.multiply(sheen.filter(ImageFilter.GaussianBlur(40)), self.screen_mask)
        self.white = Image.new('RGBA', (SRC_W, SRC_H), (255, 255, 255, 255))

    def render(self, frame):
        out = self.body.copy()
        scr = Image.fromarray(frame).resize((SRC_W, SRC_H), Image.BILINEAR) if frame.shape[1] != SRC_W else Image.fromarray(frame)
        out.paste(scr, (self.bezel, self.bezel), self.screen_mask)
        out.paste(self.white, (self.bezel, self.bezel), self.sheen)
        return out


def perspective_coeffs(dst, src):
    """Coefficients for Image.transform(PERSPECTIVE) mapping output points [dst] back to input points [src]."""
    a = []
    b = []
    for (x, y), (u, v) in zip(dst, src):
        a.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        a.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        b += [u, v]
    return np.linalg.solve(np.array(a, float), np.array(b, float)).tolist()


def project(w, h, cam, focus):
    """Output corners of a w x h image placed by camera [cam]: dict(x, y = where [focus] lands, scale, rx, ry, rz in
    degrees). [focus] is a point of the image (pixels)."""
    fx, fy = focus
    corners = [(0, 0), (w, 0), (w, h), (0, h)]
    rx, ry, rz = (math.radians(cam.get(k, 0.0)) for k in ('rx', 'ry', 'rz'))
    s = cam['scale']
    d = 2600.0  # camera distance in image pixels
    out = []
    for cx, cy in corners:
        x, y, z = cx - fx, cy - fy, 0.0
        # rz, then ry, then rx
        x, y = x * math.cos(rz) - y * math.sin(rz), x * math.sin(rz) + y * math.cos(rz)
        x, z = x * math.cos(ry) + z * math.sin(ry), -x * math.sin(ry) + z * math.cos(ry)
        y, z = y * math.cos(rx) - z * math.sin(rx), y * math.sin(rx) + z * math.cos(rx)
        p = d / (d + z)
        out.append((cam['x'] + x * p * s, cam['y'] + y * p * s))
    return out


def place(img, size, cam, focus):
    """[img] drawn into an output-sized RGBA layer by the camera."""
    dst = project(img.width, img.height, cam, focus)
    coeffs = perspective_coeffs(dst, [(0, 0), (img.width, 0), (img.width, img.height), (0, img.height)])
    return img.transform(size, Image.PERSPECTIVE, coeffs, Image.BICUBIC), dst


def blurred_backdrop(frame, size, tint, darken=0.3):
    """The screen itself, hugely blurred and tinted: a background in the shot's colours."""
    small = Image.fromarray(frame).resize((18, 40), Image.BILINEAR)
    w, h = size
    big = small.resize((max(w, h) // 8, max(w, h) // 8), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
    side = max(w, h)
    big = big.resize((side, side), Image.BICUBIC)
    big = big.crop(((side - w) // 2, (side - h) // 2, (side - w) // 2 + w, (side - h) // 2 + h))
    arr = np.asarray(big, np.float32)
    grey = arr.mean(axis=2, keepdims=True)
    arr = grey + (arr - grey) * 1.5  # more colour than the screen itself
    # A diagonal light: brighter top-left, deeper bottom-right.
    h_, w_ = arr.shape[:2]
    ramp = (np.linspace(1.12, 0.72, h_)[:, None] * np.linspace(1.05, 0.9, w_)[None, :])[..., None]
    arr = (arr * (1 - darken) + np.array(tint, np.float32) * darken) * ramp
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).convert('RGBA')


class Bokeh:
    """Soft light dots drifting upwards (precomputed sprites, positions by time)."""

    def __init__(self, size, n=26, seed=4):
        rnd = np.random.default_rng(seed)
        self.size = size
        self.dots = []
        for _ in range(n):
            r = int(rnd.uniform(10, 46) * size[1] / 1080)
            spr = Image.new('RGBA', (r * 4, r * 4), (0, 0, 0, 0))
            ImageDraw.Draw(spr).ellipse((r, r, 3 * r, 3 * r), fill=(255, 255, 255, int(rnd.uniform(18, 50))))
            spr = spr.filter(ImageFilter.GaussianBlur(r * 0.5))
            self.dots.append((spr, rnd.uniform(0, size[0]), rnd.uniform(0, size[1]), rnd.uniform(12, 50), rnd.uniform(0, 6.28)))

    def draw(self, canvas, t):
        w, h = self.size
        for spr, x, y, v, ph in self.dots:
            yy = (y - v * t) % (h + spr.height) - spr.height
            xx = x + 18 * math.sin(t * 0.7 + ph)
            canvas.alpha_composite(spr, (int(xx), int(yy)))


def vignette(size, strength=0.42):
    w, h = size
    y = np.linspace(-1, 1, h)[:, None]
    x = np.linspace(-1, 1, w)[None, :]
    r = np.sqrt((x * 0.9) ** 2 + (y * 0.9) ** 2)
    a = np.clip((r - 0.55) / 0.85, 0, 1) ** 1.6 * strength
    return Image.fromarray((a * 255).astype(np.uint8)).convert('L')


def grade(img, sat=1.0, contrast=1.0, warm=0.0):
    arr = np.asarray(img.convert('RGB'), np.float32)
    if sat != 1.0:
        grey = arr.mean(axis=2, keepdims=True)
        arr = grey + (arr - grey) * sat
    if contrast != 1.0:
        arr = (arr - 128) * contrast + 128
    if warm:
        arr[..., 0] += warm * 12
        arr[..., 2] -= warm * 12
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))


# --------------------------------------------------------------------------------------------------------------------
# Typography


class Words:
    """A caption as word sprites (white, highlighted words gold, thick ink outline and a drop shadow)."""

    def __init__(self, text, size, max_width, align='center'):
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
        while True:
            f = ImageFont.truetype(FONT, size)
            space = f.getlength(' ')
            widths = [sum(f.getlength(w) for w, _ in l) + space * (len(l) - 1) for l in lines]
            if max(widths) <= max_width or size < 30:
                break
            size -= 3
        self.size = size
        stroke = max(4, size // 13)
        self.sprites = []  # (img, x, y) relative to the block's top centre / left
        y = 0
        line_h = size * 1.1
        for line, width in zip(lines, widths):
            x = -width / 2 if align == 'center' else 0
            for word, hot in line:
                spr = self.word_sprite(word, f, stroke, GOLD if hot else (255, 255, 255))
                self.sprites.append((spr, x - stroke - 10, y - stroke - 10))
                x += f.getlength(word) + space
            y += line_h
        self.height = y
        self.width = max(widths)

    @staticmethod
    def word_sprite(word, f, stroke, colour):
        if word == '⭐':
            return star_sprite(int(f.size * 0.95), stroke)
        w = int(f.getlength(word)) + 2 * stroke + 20
        h = int(f.size * 1.35) + 2 * stroke + 20
        img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        shadow = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).text((stroke + 10, stroke + 10 + f.size * 0.08), word, font=f, fill=(0, 0, 0, 150),
                                    stroke_width=stroke, stroke_fill=(0, 0, 0, 150))
        img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)))
        ImageDraw.Draw(img).text((stroke + 10, stroke + 10), word, font=f, fill=colour, stroke_width=stroke, stroke_fill=INK)
        return img

    def draw(self, canvas, x, y, t, enter=0.0, exit_at=None, stagger=0.07, pop=True):
        """Draws the caption with its top centre at (x, y); words pop in from [enter] (seconds, caption time [t]),
        all slide out from [exit_at]."""
        for i, (spr, dx, dy) in enumerate(self.sprites):
            u = (t - enter - i * stagger) / 0.38
            if u <= 0:
                continue
            s = ease_out_back(u) if pop else ease_out_cubic(u)
            alpha = clamp01(u * 2.5)
            oy = (1 - ease_out_cubic(u)) * self.size * 0.6
            if exit_at is not None and t > exit_at:
                v = clamp01((t - exit_at) / 0.22)
                alpha *= 1 - v
                oy -= ease_in_cubic(v) * self.size * 0.8
            if alpha <= 0.01:
                continue
            scale = max(0.05, 0.55 + 0.45 * s)
            sw, sh = max(1, int(spr.width * scale)), max(1, int(spr.height * scale))
            img = spr.resize((sw, sh), Image.BILINEAR)
            if alpha < 1:
                a = img.split()[3].point(lambda p: int(p * alpha))
                img.putalpha(a)
            cx = x + dx + spr.width / 2
            cy = y + dy + spr.height / 2 + oy
            canvas.alpha_composite(img, (int(cx - sw / 2), int(cy - sh / 2)))


def star_sprite(size, stroke):
    img = Image.new('RGBA', (size + 2 * stroke + 20, size + 2 * stroke + 20), (0, 0, 0, 0))
    c = img.width / 2
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = size / 2 if i % 2 == 0 else size / 2 * 0.45
        pts.append((c + r * math.cos(a), c + r * math.sin(a)))
    d = ImageDraw.Draw(img)
    d.polygon(pts, fill=GOLD, outline=INK, width=stroke)
    return img


# --------------------------------------------------------------------------------------------------------------------
# Particles


def star_points(x, y, r, inner=0.3, n=4, rot=0.0):
    pts = []
    for i in range(2 * n):
        a = rot + i * math.pi / n
        rr = r if i % 2 == 0 else r * inner
        pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
    return pts


def paste_clipped(canvas, img, x, y):
    """alpha_composite that tolerates [img] hanging off the canvas."""
    x, y = int(x), int(y)
    l, t = max(0, -x), max(0, -y)
    r, b = min(img.width, canvas.width - x), min(img.height, canvas.height - y)
    if r > l and b > t:
        canvas.alpha_composite(img.crop((l, t, r, b)), (x + l, y + t))


class Burst:
    """Sparkles and a light flare at an output point, from time [t0]."""

    def __init__(self, t0, x, y, scale=1.0, n=22, colour=GOLD, seed=0):
        rnd = np.random.default_rng(seed)
        self.t0, self.x, self.y, self.scale, self.colour = t0, x, y, scale, colour
        self.parts = [(rnd.uniform(0, 2 * math.pi), rnd.uniform(260, 820) * scale, rnd.uniform(9, 26) * scale,
                       rnd.uniform(0.45, 0.9), rnd.uniform(0, 3)) for _ in range(n)]

    def draw(self, canvas, t):
        dt = t - self.t0
        if dt < 0 or dt > 1.0:
            return
        layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        # Flare: a bright disc that grows and fades.
        fr = (60 + 380 * ease_out_cubic(dt / 0.45)) * self.scale
        fa = int(170 * (1 - clamp01(dt / 0.45)))
        if fa > 0:
            # Drawn small, blurred, then scaled up: cheap and soft.
            q = 4
            side = int(fr * 3.2 / q) + 2
            flare = Image.new('RGBA', (side, side), (255, 248, 220, 0))
            c = side / 2
            ImageDraw.Draw(flare).ellipse((c - fr / q, c - fr / q, c + fr / q, c + fr / q), fill=(255, 248, 220, fa))
            flare = flare.filter(ImageFilter.GaussianBlur(fr * 0.35 / q)).resize((side * q, side * q), Image.BILINEAR)
            paste_clipped(canvas, flare, self.x - side * q / 2, self.y - side * q / 2)
        for ang, speed, size, life, spin in self.parts:
            if dt > life:
                continue
            u = dt / life
            dist = speed * ease_out_cubic(u) * 0.55
            px = self.x + math.cos(ang) * dist
            py = self.y + math.sin(ang) * dist + 120 * self.scale * u * u
            r = size * (1 - u) * (0.6 + 0.4 * math.sin(u * 9 + spin))
            if r < 1:
                continue
            col = self.colour if int(spin * 10) % 3 else (255, 255, 255)
            d.polygon(star_points(px, py, r, 0.28, 4, spin + u * 3), fill=col + (int(255 * (1 - u * 0.6)),))
        canvas.alpha_composite(layer)


# --------------------------------------------------------------------------------------------------------------------
# The edit


class Shot:
    def __init__(self, start, end, clip=None, src=None, cam=None, tint=(80, 120, 200), caption=None, layout='left',
                 enter='cut', grade=(1.05, 1.03, 0.0), bursts=(), sfx=(), focus=None, title=None, sub=None, bg=None,
                 tilt=True):
        self.start, self.end = start, end
        self.clip = clip
        self.src = src  # [(shot time, clip time)] speed map, linear between keys
        self.cam = cam or []  # [(shot time, dict(scale=, fx=, fy=, x=, y=, rx=, ry=, rz=))] in normalized units
        self.tint = tint
        self.caption = caption
        self.layout = layout
        self.enter = enter
        self.grade = grade
        self.bursts = bursts
        self.sfx = sfx
        self.title = title
        self.sub = sub
        self.bg = bg
        self.tilt = tilt

    def src_time(self, t):
        keys = self.src
        return keyframes(t, keys, linear)


def build_edit(lang, fmt, ev):
    """The shot list for one language and format. [ev] holds each clip's event times (seconds in the recording)."""
    T = TEXT[lang]
    wide = fmt == '16x9'
    shots = []

    def cam(scale, fx, fy, x=None, y=None, rx=0.0, ry=0.0, rz=0.0):
        # fx, fy: focus on the screen (0..1); x, y: where it lands (0..1 of the frame).
        if x is None:
            x = 0.68 if wide else 0.5
        if y is None:
            y = 0.5 if wide else 0.64
        return dict(scale=scale, fx=fx, fy=fy, x=x, y=y, rx=rx, ry=ry, rz=rz)

    side = (lambda l: dict(x=0.68 if l == 'left' else 0.32)) if wide else (lambda l: dict(x=0.5))

    # 0–2 s: cold open, Night Neon board, a critter pops in.
    e = ev['nests_neon']
    shots.append(Shot(0.0, 2.0, 'nests_neon', [(0, e['place'] - 1.55), (2.0, e['place'] + 0.45)],
                      [(0, cam(2.2, 0.6, 0.52, 0.5, 0.5 if wide else 0.6, 8, -10, -3)), (2.0, cam(3.2, 0.62, 0.54, 0.5, 0.5 if wide else 0.6, 2, -3, 0))],
                      tint=(60, 20, 120), enter='fade', grade=(1.15, 1.08, -0.2),
                      bursts=[(1.55, 0.62, 0.54)], sfx=[(1.55, 'place', 0.9)], tilt=False))
    # 2–4 s: title.
    shots.append(Shot(2.0, 4.0, None, title=True, enter='black', sfx=[]))
    # 4–6 s: home, "3 new puzzles every day".
    e = ev['home_meadow']
    shots.append(Shot(4.0, 6.0, 'home_meadow', [(0, 0.6), (2.0, 2.6)],
                      [(0, cam(1.0, 0.5, 0.42, **side('left'), ry=-14)), (2.0, cam(1.18, 0.5, 0.42, **side('left'), ry=-8))],
                      tint=(70, 150, 230), caption=T['daily'], layout='left', enter='whip'))
    # 6–12 s: the three games, each ending on its solve.
    for i, (g, layout) in enumerate([('nests', 'right'), ('pairs', 'left'), ('trail', 'right')]):
        e = ev[g]
        t0 = 6.0 + 2.0 * i
        solve = e['solve']
        # Speed ramp: fast through the moves, normal speed for the last 0.6 s before and after the solve.
        src = [(0, solve - e['lead']), (1.2, solve - 0.25), (2.0, solve + 0.55)]
        shots.append(Shot(t0, t0 + 2.0, g, src,
                          [(0, cam(1.45, 0.5, 0.52, **side(layout), ry=12 if layout == 'right' else -12)),
                           (1.25, cam(1.62, 0.5, 0.52, **side(layout), ry=6 if layout == 'right' else -6)),
                           (2.0, cam(1.4, 0.5, 0.48, **side(layout), ry=3 if layout == 'right' else -3))],
                          tint=(70, 150, 230), caption=T[g] + '|' + '#' + T[g + '_sub'], layout=layout, enter='whip',
                          bursts=[(1.5, 0.5, 0.45)],
                          sfx=[(0.25, 'tap', 0.5), (0.5, 'tap', 0.5), (0.75, 'tap', 0.5), (1.0, 'tap', 0.5), (1.45, 'solve', 0.9)]))
    # 12–14 s: coins: the level's reward card, the coins flying to the counter.
    e = ev['level_pairs']
    shots.append(Shot(12.0, 14.0, 'level_pairs', [(0, e['solve'] + 0.4), (2.0, e['solve'] + 3.9)],
                      [(0, cam(1.3, 0.5, 0.42, **side('left'), ry=-10)), (0.9, cam(1.85, 0.5, 0.55, **side('left'), ry=-6)),
                       (2.0, cam(1.6, 0.68, 0.3, **side('left'), ry=-4))],
                      tint=(240, 180, 60), caption=T['coins'], layout='left', enter='zoom', grade=(1.12, 1.05, 0.3),
                      bursts=[(1.0, 0.5, 0.565), (1.75, 0.86, 0.04)],
                      sfx=[(0.1, 'reveal', 0.6)] + [(1.0 + 0.15 * i, 'coin', 0.8) for i in range(6)]))
    # 14–15.5 s: ranking.
    e = ev['nests']
    shots.append(Shot(14.0, 15.5, 'nests', [(0, e['solve'] + 2.2), (1.5, e['solve'] + 3.7)],
                      [(0, cam(1.5, 0.5, 0.5, **side('right'), ry=10)), (1.5, cam(1.85, 0.5, 0.56, **side('right'), ry=5))],
                      tint=(230, 140, 60), caption=T['rank'], layout='right', enter='whip', bursts=[(0.3, 0.5, 0.58)],
                      sfx=[(0.3, 'chest', 0.6)]))
    # 15.5–18.5 s: Lucky Nest: the tap, slow motion on the wobble and crack, the coins.
    e = ev['lucky']
    tap, prize = e['tap'], e['prize']
    shots.append(Shot(15.5, 18.5, 'lucky', [(0, tap - 0.3), (0.4, tap + 0.1), (1.9, prize + 0.1), (3.0, prize + 1.8)],
                      [(0, cam(1.3, 0.5, 0.48, **side('left'), ry=-10)), (1.9, cam(1.9, 0.5, 0.45, **side('left'), ry=-4)),
                       (3.0, cam(1.55, 0.66, 0.3, **side('left'), ry=-6))],
                      tint=(120, 200, 250), caption=T['lucky'], layout='left', enter='whip', grade=(1.1, 1.04, 0.1),
                      bursts=[(1.85, 0.5, 0.42), (2.9, 0.86, 0.04)],
                      sfx=[(0.3, 'tap', 0.8), (0.5, 'capsule', 0.8), (1.85, 'chest', 0.9)] + [(2.35 + 0.12 * i, 'coin', 0.7) for i in range(5)]))
    # 18.5–21 s: a capsule: taps, the reveal in slow motion.
    e = ev['capsule']
    shots.append(Shot(18.5, 21.0, 'capsule', [(0, e['tap1'] - 0.2), (0.9, e['reveal'] - 0.1), (1.6, e['reveal'] + 0.25), (2.5, e['reveal'] + 1.4)],
                      [(0, cam(1.3, 0.5, 0.5, **side('right'), ry=10)), (1.1, cam(1.7, 0.5, 0.45, **side('right'), ry=6)),
                       (2.5, cam(1.5, 0.5, 0.5, **side('right'), ry=8))],
                      tint=(250, 150, 120), caption=T['critters'], layout='right', enter='whip',
                      bursts=[(1.1, 0.5, 0.4)], sfx=[(0.1, 'tap', 0.7), (0.45, 'tap', 0.7), (0.8, 'tap', 0.7), (1.1, 'reveal', 1.0)]))
    # 21–22 s: the album, critters with their stars.
    e = ev['album']
    shots.append(Shot(21.0, 22.0, 'album', [(0, e['open'] + 0.4), (1.0, e['open'] + 1.4)],
                      [(0, cam(1.45, 0.45, 0.3, **side('left'), ry=-10)), (1.0, cam(1.75, 0.45, 0.32, **side('left'), ry=-6))],
                      tint=(250, 200, 120), caption=T['levelup'], layout='left', enter='whip'))
    # 22–26 s: the Worlds montage, a cut on every beat.
    worlds = ['home_lodge', 'home_neon', 'home_winter', 'home_pro']
    montage = []
    for w in worlds:
        montage.append((w, 'home'))
    for w in ['home_meadow', 'home_lodge', 'home_neon', 'home_winter']:
        montage.append((w, 'board'))
    tints = {'home_meadow': (70, 150, 230), 'home_lodge': (200, 90, 40), 'home_neon': (150, 40, 200),
             'home_winter': (90, 140, 220), 'home_pro': (120, 120, 130)}
    for i, (w, part) in enumerate(montage):
        e = ev[w]
        t0 = 22.0 + 0.5 * i
        at = e['home'] if part == 'home' else e['board']
        rz = [-4, 3, -3, 4, -4, 3, -3, 4][i]
        shots.append(Shot(t0, t0 + 0.5, w, [(0, at), (0.5, at + 0.5)],
                          # 16:9: the whole phone on the right, the caption on the left; 9:16: closer, caption on top.
                          [(0, cam(*((0.88, 0.5, 0.5, 0.66, 0.5) if wide and part == 'home' else
                                     (1.45, 0.5, 0.45, 0.66, 0.5) if wide else
                                     (1.25 if part == 'home' else 1.35, 0.5, 0.4, 0.5, 0.6)), rz=rz, ry=0)),
                           (0.5, cam(*((0.93, 0.5, 0.5, 0.66, 0.5) if wide and part == 'home' else
                                       (1.58, 0.5, 0.45, 0.66, 0.5) if wide else
                                       (1.36 if part == 'home' else 1.48, 0.5, 0.4, 0.5, 0.6)), rz=rz * 0.5))],
                          tint=tints[w], caption=T['worlds'] if i == 0 else None, layout='montage', enter='flash' if i else 'zoom',
                          grade=(1.12, 1.06, 0.0)))
    # 26–30 s: end card.
    shots.append(Shot(26.0, LENGTH, None, title='end', enter='flash'))
    return shots


# --------------------------------------------------------------------------------------------------------------------
# Rendering


class Renderer:
    def __init__(self, lang, fmt, ev, scale=1.0):
        self.lang, self.fmt = lang, fmt
        self.W, self.H = (1920, 1080) if fmt == '16x9' else (1080, 1920)
        self.scale = scale
        self.size = (int(self.W * scale), int(self.H * scale))
        self.shots = build_edit(lang, fmt, ev)
        self.device = Device()
        self.bokeh = Bokeh(self.size)
        self.vig = vignette(self.size)
        self.sources = {}
        self.captions = {}
        self.title_words = {}
        self.T = TEXT[lang]
        self.icon = Image.open(os.path.join(ROOT, 'assets', 'icon', 'icon.png')).convert('RGBA')
        self.critters = {n: Image.open(os.path.join(ROOT, 'assets', 'critters', n + '.png')).convert('RGBA')
                         for n in ['chick', 'pig', 'frog', 'panda', 'penguin', 'owl', 'bear', 'giraffe']}

    def source(self, shot):
        key = id(shot)
        if key not in self.sources:
            t0 = min(v for _, v in shot.src)
            t1 = max(v for _, v in shot.src)
            self.sources[key] = Source(f'{self.lang}_{shot.clip}', t0 - 0.05, t1 - t0 + 0.2)
        return self.sources[key]

    def release(self, shot):
        s = self.sources.pop(id(shot), None)
        if s:
            s.close()

    # Layout -----------------------------------------------------------------------------------------------------

    def caption_box(self, shot):
        """Where the caption goes: (x centre, y top, max width, font size)."""
        W, H = self.size
        k = self.scale
        if self.fmt == '16x9':
            if shot.layout == 'top':
                return W * 0.5, H * 0.07, W * 0.8, int(96 * k)
            if shot.layout == 'montage':
                return W * 0.29, H * 0.33, W * 0.44, int(120 * k)
            x = W * 0.3 if shot.layout == 'left' else W * 0.7
            return x, H * 0.33, W * 0.44, int(112 * k)
        return W * 0.5, H * 0.075, W * 0.88, int(118 * k)

    def caption_for(self, shot):
        if shot.caption is None:
            return None
        key = id(shot)
        if key not in self.captions:
            x, y, mw, size = self.caption_box(shot)
            main, _, sub = shot.caption.partition('|#')
            words = Words(main, size, mw)
            subw = Words(sub, int(size * 0.5), mw) if sub else None
            self.captions[key] = (words, subw)
        return self.captions[key]

    # Frame ------------------------------------------------------------------------------------------------------

    def device_base(self, device_height):
        """Device scale at camera scale 1: 96% of the frame height (16:9) or 68% (9:16)."""
        return (0.96 if self.fmt == '16x9' else 0.68) * self.size[1] / device_height

    def device_layer(self, shot, t, frame):
        W, H = self.size
        k = self.scale
        cam = keyframes(t, shot.cam)
        dev = self.device.render(frame)
        base = self.device_base(dev.height)
        c = dict(cam)
        fx = self.device.bezel + c['fx'] * SRC_W
        fy = self.device.bezel + c['fy'] * SRC_H
        # Gentle float.
        wob = math.sin((shot.start + t) * 1.7) * 1.2
        c2 = dict(scale=c['scale'] * base, x=c['x'] * W, y=c['y'] * H + math.sin((shot.start + t) * 1.3) * 6 * k,
                  rx=c.get('rx', 0) + (wob if shot.tilt else 0), ry=c.get('ry', 0), rz=c.get('rz', 0))
        layer, corners = place(dev, (W, H), c2, (fx, fy))
        return layer, corners, c2, (fx, fy)

    def frame(self, n):
        t_abs = n / FPS
        shot = next(s for s in self.shots if s.start <= t_abs < s.end) if t_abs < LENGTH else self.shots[-1]
        t = t_abs - shot.start
        W, H = self.size
        if shot.title is not None:
            img = self.title_card(shot, t)
        else:
            src = self.source(shot)
            frame = src.at(shot.src_time(t))
            canvas = blurred_backdrop(frame, self.size, shot.tint)
            self.bokeh.draw(canvas, t_abs)
            layer, corners, cam2, focus = self.device_layer(shot, t, frame)
            # Soft shadow under the device.
            q = 4
            shadow = Image.new('L', (W // q, H // q), 0)
            ImageDraw.Draw(shadow).polygon([((x + 18 * self.scale) / q, (y + 34 * self.scale) / q) for x, y in corners], fill=130)
            shadow = shadow.filter(ImageFilter.GaussianBlur(28 * self.scale / q)).resize((W, H), Image.BILINEAR)
            canvas.paste((0, 0, 0), (0, 0), shadow)
            canvas.alpha_composite(layer)
            img = grade(canvas, *shot.grade).convert('RGBA')
            for bt, bx, by in shot.bursts:
                p = self.screen_point(shot, bt, bx, by, frame)
                Burst(shot.start + bt, p[0], p[1], self.scale * (1.0 if self.fmt == '16x9' else 1.2), seed=int(bt * 10)).draw(img, t_abs)
            cap = self.caption_for(shot)
            if cap:
                x, y, _, _ = self.caption_box(shot)
                words, sub = cap
                if self.fmt == '9x16' or shot.layout == 'top':
                    # A soft dark band behind the caption keeps it readable over any World.
                    band = Image.new('RGBA', self.size, (0, 0, 0, 0))
                    bh = y + words.height + (sub.height if sub else 0) + 50 * self.scale
                    ImageDraw.Draw(band).rectangle((0, 0, W, bh), fill=(10, 6, 24, 140))
                    img.alpha_composite(band.filter(ImageFilter.GaussianBlur(40 * self.scale)))
                exit_at = shot.end - shot.start - 0.2 if shot.end - shot.start > 0.8 else None
                if shot.layout in ('top', 'montage') and shot.end - shot.start <= 0.5:
                    exit_at = None
                words.draw(img, x, y, t, 0.05, exit_at)
                if sub:
                    sub.draw(img, x, y + words.height + 8 * self.scale, t, 0.3, exit_at, pop=False)
            if shot.layout == 'montage' and shot.caption is None:
                # The montage keeps its first caption on screen.
                first = next(s for s in self.shots if s.start == 22.0)
                words, sub = self.caption_for(first)
                x, y, _, _ = self.caption_box(first)
                if self.fmt == '9x16':
                    band = Image.new('RGBA', self.size, (0, 0, 0, 0))
                    ImageDraw.Draw(band).rectangle((0, 0, W, y + words.height + 50 * self.scale), fill=(10, 6, 24, 140))
                    img.alpha_composite(band.filter(ImageFilter.GaussianBlur(40 * self.scale)))
                words.draw(img, x, y, t_abs - 22.0, 0.05, 25.75 - 22.0)
        img = self.transition(shot, t, img)
        img = img.convert('RGB')
        # Vignette.
        img.paste((0, 0, 0), (0, 0), self.vig)
        return img

    def screen_point(self, shot, t, sx, sy, frame):
        cam = keyframes(t, shot.cam)
        W, H = self.size
        dev = self.device
        base = self.device_base(dev.size[1])
        fx = dev.bezel + cam['fx'] * SRC_W
        fy = dev.bezel + cam['fy'] * SRC_H
        px = dev.bezel + sx * SRC_W
        py = dev.bezel + sy * SRC_H
        return cam['x'] * W + (px - fx) * cam['scale'] * base, cam['y'] * H + (py - fy) * cam['scale'] * base

    def transition(self, shot, t, img):
        W, H = self.size
        dur = 0.22
        if shot.enter == 'whip' and t < dur:
            u = 1 - ease_out_cubic(t / dur)
            img = motion_blur(img, int(-W * 0.35 * u), int(u * 60 * self.scale))
        elif shot.enter == 'zoom' and t < dur:
            u = 1 - ease_out_cubic(t / dur)
            img = zoom_blur(img, 1 + 0.35 * u)
        elif shot.enter == 'flash' and t < 0.16:
            white = Image.new('RGBA', img.size, (255, 255, 255, int(200 * (1 - t / 0.16))))
            img = img.convert('RGBA')
            img.alpha_composite(white)
        elif shot.enter == 'fade' and t < 0.35:
            black = Image.new('RGBA', img.size, (0, 0, 0, int(255 * (1 - t / 0.35))))
            img = img.convert('RGBA')
            img.alpha_composite(black)
        # Exit whip into the next shot.
        nxt = next((s for s in self.shots if abs(s.start - shot.end) < 1e-6), None)
        left = shot.end - shot.start - t
        if nxt is not None and nxt.enter == 'whip' and left < 0.12:
            u = ease_in_cubic(1 - left / 0.12)
            img = motion_blur(img, int(W * 0.35 * u), int(u * 60 * self.scale))
        if nxt is not None and nxt.enter == 'zoom' and left < 0.12:
            u = ease_in_cubic(1 - left / 0.12)
            img = zoom_blur(img, 1 + 0.3 * u)
        return img

    # Title cards ------------------------------------------------------------------------------------------------

    def card_background(self, t, top=(40, 150, 235), bottom=(70, 180, 80)):
        W, H = self.size
        y = np.linspace(0, 1, H)[:, None, None]
        arr = np.array(top, np.float32) * (1 - y) + np.array(bottom, np.float32) * y
        arr = np.repeat(arr, W, 1)
        img = Image.fromarray(arr.astype(np.uint8)).convert('RGBA')
        # Rotating light rays from the centre.
        rays = Image.new('L', (W, H), 0)
        d = ImageDraw.Draw(rays)
        cx, cy = W / 2, H * (0.42 if self.fmt == '16x9' else 0.4)
        R = max(W, H)
        for i in range(14):
            a0 = t * 0.25 + i * 2 * math.pi / 14
            d.polygon([(cx, cy), (cx + R * math.cos(a0), cy + R * math.sin(a0)),
                       (cx + R * math.cos(a0 + 0.12), cy + R * math.sin(a0 + 0.12))], fill=34)
        img.paste((255, 255, 255), (0, 0), rays.filter(ImageFilter.GaussianBlur(8)))
        self.bokeh.draw(img, t)
        return img

    def logo(self, img, t, cx, cy, size_icon, size_title, sub=None, t_hit=0.0):
        k = self.scale
        u = (t - t_hit) / 0.45
        if u <= 0:
            return
        s = ease_out_back(u, 2.4)
        ic = int(size_icon * max(0.05, s))
        icon = self.icon.resize((ic, ic), Image.LANCZOS)
        icon.putalpha(ImageChops.multiply(icon.split()[3], rounded_mask((ic, ic), int(ic * 0.22))))
        sh = Image.new('RGBA', img.size, (0, 0, 0, 0))
        sh.paste((0, 0, 0, 120), (int(cx - ic / 2), int(cy - ic / 2 + 18 * k)), icon.split()[3])
        img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(16 * k)))
        img.alpha_composite(icon, (int(cx - ic / 2), int(cy - ic / 2)))
        title = self.title_words.get(size_title)
        if title is None:
            title = self.title_words[size_title] = Words(self.T['title'], size_title, self.W * self.scale * 0.9)
        title.draw(img, cx, cy + size_icon * 0.58, t, t_hit + 0.12, None, 0.06)
        if sub:
            key = ('sub', size_title)
            w = self.title_words.get(key)
            if w is None:
                w = self.title_words[key] = Words(sub, int(size_title * 0.48), self.W * self.scale * 0.9)
            w.draw(img, cx, cy + size_icon * 0.58 + title.height + 6 * k, t, t_hit + 0.35, None, 0.05, pop=False)

    def title_card(self, shot, t):
        W, H = self.size
        k = self.scale
        wide = self.fmt == '16x9'
        if shot.title is True:
            # 2–4 s: black beat, then the title hits.
            if t < 0.1:
                return Image.new('RGBA', self.size, (0, 0, 0, 255))
            img = self.card_background(t, (24, 40, 120), (120, 40, 160))
            cy = H * (0.36 if wide else 0.38)
            self.logo(img, t, W / 2, cy, int((330 if wide else 420) * k), int((150 if wide else 140) * k), self.T['tagline'], 0.1)
            Burst(shot.start + 0.15, W / 2, cy, k * 1.4, n=34, seed=3).draw(img, shot.start + t)
            if t < 0.28:
                white = Image.new('RGBA', img.size, (255, 255, 255, int(230 * (1 - (t - 0.1) / 0.18))))
                img.alpha_composite(white)
            # Push-in.
            z = 1 + 0.04 * smooth(t / 2)
            img = img.resize((int(W * z), int(H * z)), Image.BILINEAR).crop(
                (int((W * z - W) / 2), int((H * z - H) / 2), int((W * z - W) / 2) + W, int((H * z - H) / 2) + H))
            return img
        # End card.
        img = self.card_background(t)
        cy = H * (0.22 if wide else 0.3)
        self.logo(img, t, W / 2, cy, int((240 if wide else 400) * k), int((140 if wide else 136) * k), self.T['end_sub'], 0.05)
        Burst(shot.start + 0.1, W / 2, cy, k * 1.3, n=30, seed=8).draw(img, shot.start + t)
        # "Free on Google Play" pill.
        f = ImageFont.truetype(FONT, int((62 if wide else 66) * k))
        text = self.T['free']
        tw = f.getlength(text)
        pw, ph = int(tw + 110 * k), int(118 * k)
        u = (t - 0.75) / 0.4
        if u > 0:
            s = ease_out_back(u)
            pill = Image.new('RGBA', (pw, ph), (0, 0, 0, 0))
            d = ImageDraw.Draw(pill)
            d.rounded_rectangle((0, 0, pw - 1, ph - 1), ph // 2, fill=(255, 255, 255, 255), outline=INK, width=int(6 * k))
            d.text(((pw - tw) / 2, ph * 0.13), text, font=f, fill=(46, 125, 50))
            sw, sh = max(1, int(pw * s)), max(1, int(ph * s))
            pill = pill.resize((sw, sh), Image.BILINEAR)
            py = H * (0.73 if wide else 0.68)
            img.alpha_composite(pill, (int(W / 2 - sw / 2), int(py - sh / 2)))
        # Critters bouncing in along the bottom.
        names = ['chick', 'pig', 'frog', 'panda', 'penguin'] if wide else ['chick', 'frog', 'panda', 'penguin']
        n = len(names)
        cs = int((150 if wide else 200) * k)
        for i, name in enumerate(names):
            u = (t - 0.45 - i * 0.09) / 0.5
            if u <= 0:
                continue
            x = W * (0.12 + 0.76 * i / (n - 1)) if wide else W * (0.14 + 0.72 * i / (n - 1))
            base_y = H * (0.95 if wide else 0.9)
            hop = abs(math.sin((t - 0.45 - i * 0.09) * 4.2)) * 26 * k if u > 1 else 0
            y = base_y - cs - hop + (1 - ease_out_back(u)) * cs * 1.5
            c = self.critters[name].resize((cs, cs), Image.LANCZOS)
            if i % 2:
                c = c.transpose(Image.FLIP_LEFT_RIGHT)
            img.alpha_composite(c, (int(x - cs / 2), int(y)))
        return img


def motion_blur(img, dx, strength):
    """Shifts [img] by [dx] with horizontal motion blur of [strength] px."""
    arr = np.asarray(img.convert('RGB'), np.float32)
    if strength < 2:
        return Image.fromarray(np.roll(arr, dx, 1).astype(np.uint8)).convert('RGBA')
    acc = np.zeros_like(arr)
    n = 8
    for i in range(n):
        acc += np.roll(arr, dx + int(strength * (i / (n - 1) - 0.5) * 2), 1)
    return Image.fromarray((acc / n).astype(np.uint8)).convert('RGBA')


def zoom_blur(img, z):
    W, H = img.size
    acc = np.zeros((H, W, 3), np.float32)
    n = 6
    base = img.convert('RGB')
    for i in range(n):
        zz = 1 + (z - 1) * (0.6 + 0.4 * i / (n - 1))
        w, h = int(W * zz), int(H * zz)
        im = base.resize((w, h), Image.BILINEAR).crop(((w - W) // 2, (h - H) // 2, (w - W) // 2 + W, (h - H) // 2 + H))
        acc += np.asarray(im, np.float32)
    return Image.fromarray((acc / n).astype(np.uint8)).convert('RGBA')


# --------------------------------------------------------------------------------------------------------------------
# Audio


def load_wav(path):
    with wave.open(path) as w:
        rate, ch, width = w.getframerate(), w.getnchannels(), w.getsampwidth()
        data = np.frombuffer(w.readframes(w.getnframes()), {1: np.uint8, 2: np.int16}[width]).astype(np.float32)
    data = (data - 128) / 128 if width == 1 else data / 32768
    if ch == 2:
        data = data.reshape(-1, 2).mean(1)
    if rate != music.RATE:
        x = np.arange(0, len(data), rate / music.RATE)
        data = np.interp(x, np.arange(len(data)), data)
    return data


def soundtrack(shots, path):
    mix = music.render()
    sfx_dir = os.path.join(ROOT, 'assets', 'sfx')
    cache = {}
    for s in shots:
        for at, name, gain in s.sfx:
            if name not in cache:
                cache[name] = load_wav(os.path.join(sfx_dir, name + '.wav'))
            i = int((s.start + at) * music.RATE)
            snd = cache[name][: len(mix) - i]
            mix[i:i + len(snd)] += (snd * gain * 0.55)[:, None]
        if s.enter == 'whip':
            w = music.whoosh(0.3)
            i = int((s.start - 0.15) * music.RATE)
            mix[i:i + len(w)] += (w * 0.8)[:, None]
    # Level to about -14 LUFS (ffmpeg loudnorm, two passes, true peak under -1 dB).
    raw = path + '.raw.wav'
    music.write_wav(raw, mix / max(1.0, np.max(np.abs(mix))) * 0.9)
    probe = subprocess.run([FFMPEG, '-hide_banner', '-i', raw, '-af', 'loudnorm=I=-14:TP=-1.5:LRA=11:print_format=json',
                            '-f', 'null', '-'], capture_output=True, text=True).stderr
    import json
    stats = json.loads(probe[probe.rindex('{'):probe.rindex('}') + 1])
    subprocess.run([FFMPEG, '-v', 'error', '-y', '-i', raw, '-af',
                    'loudnorm=I=-14:TP=-1.5:LRA=11:linear=true:measured_I={input_i}:measured_TP={input_tp}:'
                    'measured_LRA={input_lra}:measured_thresh={input_thresh}:offset={target_offset},aresample=48000'.format(**stats),
                    '-ar', '48000', path], check=True)
    os.remove(raw)


# --------------------------------------------------------------------------------------------------------------------
# Events (seconds in each recording), measured on the clips recorded by tools/record_promo_clips.py.

EVENTS = {}


def load_events(lang):
    import json
    with open(os.path.join(CLIPS, f'{lang}_events.json')) as f:
        return json.load(f)


def render(lang, fmt, frames=None, draft=False):
    ev = load_events(lang)
    r = Renderer(lang, fmt, ev, 0.5 if draft else 1.0)
    os.makedirs(WORK, exist_ok=True)
    if frames:
        for n in frames:
            r2 = Renderer(lang, fmt, ev, 0.5 if draft else 1.0)
            r2.frame(n).save(os.path.join(WORK, f'{lang}-{fmt}-{n:04d}.png'))
            for s in list(r2.sources):
                r2.sources[s].close()
        return
    os.makedirs(OUT, exist_ok=True)
    audio = os.path.join(WORK, f'{lang}-{fmt}.wav')
    soundtrack(r.shots, audio)
    out = os.path.join(OUT, f'promo-{lang}-{fmt}.mp4')
    W, H = r.size
    enc = subprocess.Popen([FFMPEG, '-v', 'error', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-s', f'{W}x{H}', '-r', str(FPS),
                            '-i', '-', '-i', audio, '-c:v', 'libx264', '-preset', 'slow', '-crf', '20', '-pix_fmt', 'yuv420p',
                            '-profile:v', 'high', '-movflags', '+faststart', '-c:a', 'aac', '-b:a', '192k', '-shortest', out],
                           stdin=subprocess.PIPE)
    total = int(LENGTH * FPS)
    current = None
    for n in range(total):
        t = n / FPS
        shot = next((s for s in r.shots if s.start <= t < s.end), r.shots[-1])
        if current is not None and current is not shot:
            r.release(current)
        current = shot
        enc.stdin.write(r.frame(n).tobytes())
        if n % 60 == 0:
            print(f'{lang} {fmt}: {n}/{total}', flush=True)
    enc.stdin.close()
    enc.wait()
    print('wrote', out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('langs', nargs='*', default=['en', 'fr', 'es'])
    p.add_argument('--format', choices=['16x9', '9x16'])
    p.add_argument('--frames')
    p.add_argument('--draft', action='store_true')
    a = p.parse_args()
    fmts = [a.format] if a.format else ['16x9', '9x16']
    frames = [int(x) for x in a.frames.split(',')] if a.frames else None
    for lang in a.langs:
        for fmt in fmts:
            render(lang, fmt, frames, a.draft)


if __name__ == '__main__':
    main()
