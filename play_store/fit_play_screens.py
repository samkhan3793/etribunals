from pathlib import Path
from shutil import copy2
from PIL import Image, ImageDraw, ImageFont

ASSETS = Path(r'C:\Users\HP\.cursor\projects\d-FlutterProjects-eTribunals-etribunals\assets')
OUT = Path(__file__).resolve().parent
RAW = OUT / 'raw'
PHONE = OUT / 'phone_screenshots'
EXTRA = OUT / 'extra_screenshots'
PHONE.mkdir(exist_ok=True)
EXTRA.mkdir(exist_ok=True)
RAW.mkdir(exist_ok=True)

# Play phone: JPEG/24-bit PNG, 320–3840px, longest/shortest ≤ 2. 1080×1920 is 9:16.
TARGET = (1080, 1920)
CREAM = (246, 243, 238)


def by_token(token: str) -> Path:
    hits = [p for p in ASSETS.glob('*.jpg') if token in p.name]
    if len(hits) != 1:
        raise SystemExit(f'expected 1 file for {token}, got {len(hits)}')
    return hits[0]


def to_play_phone(src: Image.Image) -> Image.Image:
    im = src.convert('RGB')
    w, h = im.size
    need_h = int(round(w * 16 / 9))
    if h > need_h:
        extra = h - need_h
        top = int(extra * 0.12)
        im = im.crop((0, top, w, top + need_h))
    elif h < need_h:
        canvas = Image.new('RGB', (w, need_h), CREAM)
        canvas.paste(im, (0, 0))
        im = canvas
    return im.resize(TARGET, Image.Resampling.LANCZOS)


def save_phone(src: Path, dest: Path):
    copy2(src, RAW / dest.name.replace('.png', '.jpg'))
    img = to_play_phone(Image.open(src))
    img.save(dest, 'PNG', optimize=True)
    w, h = img.size
    assert img.mode == 'RGB'
    assert 320 <= w <= 3840 and 320 <= h <= 3840
    assert max(w, h) / min(w, h) <= 2.0
    print(dest.name, w, h, round(max(w, h) / min(w, h), 3), dest.stat().st_size)


phone = [
    ('01_home.png', '16.27.40__1_'),
    ('02_tribunals.png', '16.27.40-cc50'),
    ('03_nclt_tools.png', '16.27.38__1_'),
    ('04_nclat_tools.png', '16.27.38-c847'),
    ('05_case_search.png', '16.27.39-031c'),
    ('06_case_results.png', '16.27.39__1_'),
    ('07_case_record.png', '16.27.37-e751'),
    ('08_ai_summarize.png', '16.27.27-a2d9'),
]
extra = [
    ('09_my_cases.png', '16.27.36-10a6'),
    ('10_order_pdf.png', '16.27.28-c0d3'),
    ('11_full_case.png', '16.27.34-aa1f'),
    ('12_proceedings.png', '16.27.29-991d'),
    ('13_application.png', '16.27.30-9842'),
]

for old in PHONE.glob('*.png'):
    old.unlink()

for name, token in phone:
    save_phone(by_token(token), PHONE / name)
for name, token in extra:
    save_phone(by_token(token), EXTRA / name)

home = to_play_phone(Image.open(by_token('16.27.40__1_')))
# Feature graphic 1024×500 from the home header area.
feat = home.crop((0, 80, 1080, 80 + int(1080 * 500 / 1024))).resize((1024, 500), Image.Resampling.LANCZOS)
feat = feat.convert('RGB')
d = ImageDraw.Draw(feat)
try:
    font = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 28)
except OSError:
    font = ImageFont.load_default()
d.rectangle((0, 430, 1024, 500), fill=(20, 56, 74))
d.text((28, 448), 'eTribunals  ·  Indian tribunal records on your phone', fill=(255, 255, 255), font=font)
feat.save(OUT / 'feature_graphic_1024x500.png', 'PNG', optimize=True)
print('feature', feat.size, feat.mode)

# Keep existing 512 icon; rewrite if missing.
icon = OUT / 'hi_res_icon_512.png'
if icon.exists():
    im = Image.open(icon).convert('RGBA').resize((512, 512), Image.Resampling.LANCZOS)
    im.save(icon, 'PNG')
    print('icon', im.size, im.mode)
