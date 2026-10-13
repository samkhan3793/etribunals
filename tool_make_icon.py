from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

root = Path(__file__).resolve().parent
navy = (20, 56, 74, 255)
cream = (246, 243, 238, 255)
gold = (196, 162, 101, 255)
teal = (28, 122, 104, 255)

def rounded_square(size, fill, radius_ratio=0.22):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    r = int(size * radius_ratio)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=r, fill=fill)
    return img

def make_mark(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = size
    cx, cy = m / 2, m / 2 + m * 0.04
    # pillar
    pw = max(3, int(m * 0.07))
    d.rectangle([cx - pw / 2, m * 0.28, cx + pw / 2, m * 0.72], fill=cream)
    d.rectangle([m * 0.28, m * 0.70, m * 0.72, m * 0.76], fill=gold)
    # beam
    d.rectangle([m * 0.22, m * 0.26, m * 0.78, m * 0.32], fill=cream)
    # pans
    for x in (m * 0.30, m * 0.70):
        d.line([(cx, m * 0.29), (x, m * 0.48)], fill=gold, width=max(2, int(m * 0.025)))
        box = [x - m * 0.12, m * 0.46, x + m * 0.12, m * 0.58]
        d.ellipse(box, outline=cream, width=max(2, int(m * 0.03)))
        d.arc(box, 0, 180, fill=gold, width=max(3, int(m * 0.04)))
    return img

def compose(size, pad=0.18):
    bg = rounded_square(size, navy)
    inner = int(size * (1 - pad * 2))
    mark = make_mark(inner)
    ox = (size - inner) // 2
    bg.alpha_composite(mark, (ox, ox))
    return bg

def compose_fg(size):
    """Adaptive icon foreground: transparent, content in safe 66%."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    inner = int(size * 0.62)
    mark = make_mark(inner)
    ox = (size - inner) // 2
    img.alpha_composite(mark, (ox, ox))
    return img

android = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}
res = root / 'android' / 'app' / 'src' / 'main' / 'res'
for folder, sz in android.items():
    dest = res / folder
    dest.mkdir(parents=True, exist_ok=True)
    compose(sz).save(dest / 'ic_launcher.png')
    compose_fg(sz * 2).resize((sz * 2, sz * 2), Image.Resampling.LANCZOS).save(dest / 'ic_launcher_foreground.png')

anydpi = res / 'mipmap-anydpi-v26'
anydpi.mkdir(parents=True, exist_ok=True)
(anydpi / 'ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
''', encoding='utf-8')
values = res / 'values'
values.mkdir(parents=True, exist_ok=True)
colors = values / 'colors.xml'
if colors.exists():
    text = colors.read_text(encoding='utf-8')
    if 'ic_launcher_background' not in text:
        text = text.replace('</resources>', '    <color name="ic_launcher_background">#14384A</color>\n</resources>')
        colors.write_text(text, encoding='utf-8')
else:
    colors.write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#14384A</color>
</resources>
''', encoding='utf-8')

web = root / 'web' / 'icons'
web.mkdir(parents=True, exist_ok=True)
for sz in (192, 512):
    compose(sz).save(web / f'Icon-{sz}.png')
    compose(sz).save(web / f'Icon-maskable-{sz}.png')

ios_dir = root / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
sizes = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-50x50@1x.png': 50,
    'Icon-App-50x50@2x.png': 100,
    'Icon-App-57x57@1x.png': 57,
    'Icon-App-57x57@2x.png': 114,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-72x72@1x.png': 72,
    'Icon-App-72x72@2x.png': 144,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}
for name, sz in sizes.items():
    compose(sz).convert('RGB').save(ios_dir / name, 'PNG')

print('icons written')
