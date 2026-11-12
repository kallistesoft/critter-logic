"""Builds assets/critters/<id>.png from Kenney's "Animal Pack Remastered" (CC0, kenney.nl).

Style: "Round (outline)" for every critter; all 30 pack names match our ids (lib/meta/album.dart).
The sprites are rendered from the pack's vector sheet (Vector/roundOutline.svg) so they stay crisp:
each animal's paths are copied (only d/fill/fill-opacity, nothing else) into a small SVG of its own
and rendered by headless Chrome with a transparent background. The pack PNGs (PNG/Round (outline))
are used to name each vector group and to find the head.

Every sprite is a round head (136 px circle at pack scale) plus ears/horns/antlers. Each one is
scaled by the same factor and its head is placed at the same spot, so all critters look the same
size; only a sprite too wide for the canvas at that scale (the moose's antlers) is shrunk.

Run: python3 -I tools/make_critters.py <unzipped pack root>   (needs Pillow + numpy, Google Chrome;
set CHROME to its binary if it isn't in /Applications). tools/make_icon.py reuses render_critter().
"""
import os
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import quoteattr

import numpy as np
from PIL import Image

IDS = ('chick chicken duck pig goat cow dog rabbit frog horse owl panda zebra buffalo hippo rhino giraffe '
       'elephant snake crocodile parrot gorilla monkey sloth moose bear walrus whale penguin narwhal').split()
OUT = Path(__file__).resolve().parents[1] / 'assets' / 'critters'
CHROME = os.environ.get('CHROME', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
SIZE = 256
HEAD = 136  # head circle diameter at pack scale, outline included
SCALE = 1.14  # head ~155 px on the 256 canvas
CENTER = (128, 136)  # head center on the canvas, a little low: ears and horns go up
MARGIN = 4
RENDER = 4  # vector render scale before the final downsample


def read_paths(svg):
    """[(fill, opacity, d, bbox)] from the vector sheet, validated as plain absolute M/L/Q paths."""
    paths = []
    for e in ET.parse(svg).getroot().iter():
        if not e.tag.endswith('path'):
            continue
        d, fill, op = e.get('d', ''), e.get('fill', ''), e.get('fill-opacity')
        if not re.fullmatch(r'[MLQ0-9.\s-]*', d) or not re.fullmatch(r'#[0-9A-Fa-f]{6}', fill):
            raise ValueError(f'unexpected path: {fill} {d[:40]}')
        nums = [float(v) for v in re.findall(r'-?[\d.]+', d)]
        xs, ys = nums[0::2], nums[1::2]
        paths.append((fill, float(op) if op else None, d, (min(xs), min(ys), max(xs), max(ys))))
    return paths


def group_paths(paths):
    """Union paths whose boxes touch: one group per animal."""
    parent = list(range(len(paths)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for i, (*_, a) in enumerate(paths):
        for j in range(i):
            b = paths[j][3]
            if a[0] <= b[2] and b[0] <= a[2] and a[1] <= b[3] and b[1] <= a[3]:
                parent[find(i)] = find(j)
    groups = {}
    for i in range(len(paths)):
        groups.setdefault(find(i), []).append(paths[i])
    return list(groups.values())


def bbox(group):
    return (min(p[3][0] for p in group), min(p[3][1] for p in group), max(p[3][2] for p in group), max(p[3][3] for p in group))


def name_groups(groups, png_dir):
    """Matches each vector group to a pack PNG: same size, and the PNG holds the group's flat colors."""
    named = {}
    for cid in IDS:
        im = Image.open(png_dir / f'{cid}.png').convert('RGBA')
        px = np.array(im).reshape(-1, 4)
        colors = {'#%02X%02X%02X' % tuple(p[:3]) for p in px[px[:, 3] == 255]}

        def score(g):
            x0, y0, x1, y1 = bbox(g)
            size = abs((x1 - x0) - im.width) + abs((y1 - y0) - im.height)
            fills = {p[0].upper() for p in g}
            return size - 40 * len(fills & colors) / len(fills)

        named[cid] = min(groups, key=score)
    if len({id(g) for g in named.values()}) != len(IDS):
        raise ValueError('two critters matched the same vector group')
    return named


def render(group, scale, workdir):
    """Renders one animal's paths (its bbox, plus 1 unit of air) at `scale` px per unit, RGBA."""
    x0, y0, x1, y1 = bbox(group)
    x0, y0, x1, y1 = x0 - 1, y0 - 1, x1 + 1, y1 + 1
    w, h = round((x1 - x0) * scale), round((y1 - y0) * scale)
    body = '\n'.join(
        f'<path fill="{fill}"' + (f' fill-opacity="{op}"' if op is not None else '') + f' d={quoteattr(d)}/>'
        for fill, op, d, _ in group)
    svg = Path(workdir) / 'critter.svg'
    png = Path(workdir) / 'critter.png'
    svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{x0} {y0} {x1 - x0} {y1 - y0}" '
                   f'width="{w}" height="{h}" style="position:absolute;left:0;top:0">\n{body}\n</svg>')
    subprocess.run([CHROME, '--headless', '--disable-gpu', '--hide-scrollbars', '--default-background-color=00000000',
                    f'--window-size={w},{h}', f'--screenshot={png}', svg.as_uri()], check=True, capture_output=True)
    return Image.open(png).convert('RGBA').crop((0, 0, w, h))


def head_center(alpha):
    """Center of the fully opaque head circle (pack scale), by sliding a circle mask over the sprite."""
    yy, xx = np.mgrid[0:HEAD, 0:HEAD]
    mask = ((xx - (HEAD - 1) / 2) ** 2 + (yy - (HEAD - 1) / 2) ** 2) <= (HEAD / 2 - 1) ** 2
    h, w = alpha.shape
    best, pos = -1, []
    for y in range(h - HEAD + 1):
        for x in range(w - HEAD + 1):
            s = alpha[y:y + HEAD, x:x + HEAD][mask].sum()
            if s > best:
                best, pos = s, [(x, y)]
            elif s == best:
                pos.append((x, y))
    return np.mean([p[0] for p in pos]) + HEAD / 2, np.mean([p[1] for p in pos]) + HEAD / 2


def load(pack):
    pack = Path(pack)
    groups = name_groups(group_paths(read_paths(pack / 'Vector' / 'roundOutline.svg')), pack / 'PNG' / 'Round (outline)')
    return groups


def render_critter(pack, cid, scale):
    """One critter at `scale` px per pack unit, plus its head center in that image (used by make_icon.py)."""
    group = load(pack)[cid]
    with tempfile.TemporaryDirectory() as tmp:
        im = render(group, scale, tmp)
    small = im.resize((round(im.width / scale), round(im.height / scale)), Image.LANCZOS)
    cx, cy = head_center(np.array(small)[:, :, 3] > 128)
    return im, (cx * scale, cy * scale)


def build(group, cid, workdir):
    big = render(group, RENDER, workdir)
    w, h = big.width / RENDER, big.height / RENDER
    cx, cy = head_center(np.array(big.resize((round(w), round(h)), Image.LANCZOS))[:, :, 3] > 128)
    # Largest scale (up to SCALE) that keeps the whole sprite inside the margin.
    room_x, room_top, room_bottom = CENTER[0] - MARGIN, CENTER[1] - MARGIN, SIZE - CENTER[1] - MARGIN
    s = min(SCALE, room_x / max(cx, w - cx), room_top / cy, room_bottom / (h - cy))
    sprite = big.resize((round(big.width * s / RENDER), round(big.height * s / RENDER)), Image.LANCZOS)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(sprite, (round(CENTER[0] - cx * s), round(CENTER[1] - cy * s)))
    # Palette PNG with alpha: flat cartoon art keeps its look at a fraction of the size.
    canvas.quantize(colors=256, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE).save(OUT / f'{cid}.png', optimize=True)
    return s


def main():
    groups = load(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for cid in IDS:
            print(f'{cid:10s} scale {build(groups[cid], cid, tmp):.3f}')


if __name__ == '__main__':
    main()
