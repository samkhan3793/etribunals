from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
OUT = ROOT
SHOTS = OUT / 'phone_screenshots'
NAVY = (20, 56, 74, 255)
CREAM = (246, 243, 238, 255)
PAPER = (255, 253, 248, 255)
INK = (11, 36, 48, 255)
MUTED = (92, 110, 118, 255)
TEAL = (28, 122, 104, 255)
GOLD = (196, 162, 101, 255)
WHITE = (255, 255, 255, 255)
W, H = 1080, 1920


def font(size, bold=False):
    names = [
        'C:/Windows/Fonts/segoeui.ttf',
        'C:/Windows/Fonts/arial.ttf',
        'C:/Windows/Fonts/calibri.ttf',
    ]
    bold_names = [
        'C:/Windows/Fonts/segoeuib.ttf',
        'C:/Windows/Fonts/arialbd.ttf',
    ]
    for p in (bold_names if bold else names):
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def rr(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)


def phone_chrome(title, tab):
    img = Image.new('RGBA', (W, H), CREAM)
    d = ImageDraw.Draw(img)
    d.rectangle((0, 0, W, 168), fill=NAVY)
    d.text((48, 58), '9:41', fill=WHITE, font=font(28, True))
    d.text((48, 108), title, fill=WHITE, font=font(40, True))
    # bottom nav
    d.rectangle((0, H - 140, W, H), fill=PAPER)
    d.line((0, H - 140, W, H - 140), fill=(20, 56, 74, 40), width=2)
    labels = ['Tribunals', 'My Cases', 'Today', 'More']
    for i, lab in enumerate(labels):
        x = 80 + i * 260
        col = TEAL if lab == tab else MUTED
        d.ellipse((x + 40, H - 118, x + 78, H - 80), outline=col, width=4)
        d.text((x + 8, H - 68), lab, fill=col, font=font(22, True))
    return img, d


def card(d, y, h, title, sub):
    rr(d, (40, y, W - 40, y + h), 22, fill=PAPER, outline=(20, 56, 74, 50), width=2)
    d.text((72, y + 28), title, fill=INK, font=font(32, True))
    d.text((72, y + 78), sub, fill=MUTED, font=font(24))


def save(img, name):
    SHOTS.mkdir(parents=True, exist_ok=True)
    path = SHOTS / name
    img.convert('RGB').save(path, 'PNG')
    print(path)


def shot_tribunals():
    img, d = phone_chrome('eTribunals', 'Tribunals')
    d.text((48, 200), '16 public tribunals', fill=MUTED, font=font(28, True))
    items = [
        ('NCLAT', 'Company law appeals', NAVY),
        ('NCLT', 'Company law trials', TEAL),
        ('NCDRC', 'Consumer disputes', GOLD),
        ('ITAT', 'Income tax appeals', (45, 107, 84, 255)),
        ('DRT', 'Debts recovery', (26, 74, 107, 255)),
        ('CAT', 'Central service matters', (90, 107, 138, 255)),
    ]
    y = 260
    col_w = 480
    for i, (name, sub, col) in enumerate(items):
        c = i % 2
        r = i // 2
        x = 40 + c * 520
        yy = y + r * 280
        rr(d, (x, yy, x + col_w, yy + 250), 24, fill=col)
        d.text((x + 28, yy + 70), name, fill=WHITE, font=font(40, True))
        d.text((x + 28, yy + 140), sub, fill=(255, 255, 255, 210), font=font(24))
    save(img, '01_tribunals.png')


def shot_cases():
    img, d = phone_chrome('My Cases', 'My Cases')
    d.text((48, 196), 'Followed on this phone', fill=MUTED, font=font(26, True))
    rows = [
        ('NCLAT', 'Company Appeal (AT) 142/2024', 'Next listing  03 Oct 2026'),
        ('NCDRC', 'CC/512/2023', 'Next listing  08 Oct 2026'),
        ('ITAT', 'ITA 88/Del/2025', 'Next listing  14 Oct 2026'),
    ]
    y = 250
    for t, case, date in rows:
        rr(d, (40, y, W - 40, y + 220), 22, fill=PAPER, outline=(20, 56, 74, 50), width=2)
        d.text((72, y + 28), t, fill=TEAL, font=font(22, True))
        d.text((72, y + 72), case, fill=INK, font=font(32, True))
        d.text((72, y + 140), date, fill=MUTED, font=font(26))
        y += 248
    save(img, '02_my_cases.png')


def shot_today():
    img, d = phone_chrome('Today', 'Today')
    d.text((48, 196), 'Followed hearings  ·  28 Sep 2026', fill=MUTED, font=font(26, True))
    card(d, 250, 200, 'NCLAT  ·  10:30 AM', 'Company Appeal (AT) 142/2024\nPrincipal Bench')
    card(d, 480, 200, 'Cause lists', 'Open daily lists from the court site, in the app.')
    card(d, 710, 200, 'Reminders', '7:00 pm previous evening and 8:00 am IST.')
    save(img, '03_today.png')


def shot_pdf():
    img, d = phone_chrome('Order', 'Tribunals')
    d.rectangle((0, 168, W, 168), fill=NAVY)
    # fake extra app bar actions
    d.rectangle((0, 0, W, 168), fill=NAVY)
    d.text((48, 108), 'Order', fill=WHITE, font=font(40, True))
    d.text((430, 114), '✦  AI Summarize', fill=WHITE, font=font(28, True))
    # paper
    rr(d, (48, 200, W - 48, H - 180), 8, fill=PAPER)
    d.text((80, 240), 'BEFORE THE NATIONAL COMPANY', fill=INK, font=font(26, True))
    d.text((80, 286), 'LAW APPELLATE TRIBUNAL', fill=INK, font=font(26, True))
    d.text((80, 360), 'The appeal is dismissed. Parties shall', fill=MUTED, font=font(26))
    d.text((80, 404), 'comply with the directions in paragraphs', fill=MUTED, font=font(26))
    d.text((80, 448), '12 to 15 within four weeks.', fill=MUTED, font=font(26))
    rr(d, (80, 560, W - 80, 720), 16, fill=(230, 243, 239, 255))
    d.text((110, 600), 'Tap AI Summarize for held points,', fill=TEAL, font=font(26, True))
    d.text((110, 646), 'operative directions and a follow-up box.', fill=TEAL, font=font(26, True))
    save(img, '04_ai_summarize.png')


def shot_summary():
    img, d = phone_chrome('AI Summarize', 'Tribunals')
    rr(d, (40, 196, W - 40, 1180), 22, fill=PAPER, outline=(20, 56, 74, 50), width=2)
    d.text((72, 224), '✦  JUDGEMENT', fill=TEAL, font=font(22, True))
    d.text((72, 280), 'Appeal dismissed. Directions in', fill=INK, font=font(34, True))
    d.text((72, 330), 'paras 12–15 to be complied in 4 weeks.', fill=INK, font=font(34, True))
    d.text((72, 410), 'THIS ORDER', fill=(18, 93, 149, 255), font=font(22, True))
    d.text((72, 456), 'Result', fill=MUTED, font=font(24, True))
    d.text((320, 456), 'Dismissed', fill=INK, font=font(24, True))
    d.text((72, 508), 'Costs', fill=MUTED, font=font(24, True))
    d.text((320, 508), 'No order as to costs', fill=INK, font=font(24, True))
    d.text((72, 580), 'WHAT MATTERS', fill=(18, 93, 149, 255), font=font(22, True))
    d.text((72, 632), '•  Operative portion: comply in 4 weeks', fill=INK, font=font(26))
    d.text((72, 680), '•  Held: no interference with the order', fill=INK, font=font(26))
    d.text((72, 728), '•  Liberty to restore on default', fill=INK, font=font(26))
    d.text((48, 1220), 'Ask about this order', fill=(18, 93, 149, 255), font=font(26, True))
    rr(d, (40, 1280, 360, 1360), 20, fill=(230, 243, 239, 255))
    d.text((62, 1304), 'What was held?', fill=INK, font=font(24, True))
    rr(d, (380, 1280, 700, 1360), 20, fill=(230, 243, 239, 255))
    d.text((402, 1304), 'Next listing?', fill=INK, font=font(24, True))
    rr(d, (40, 1388, 900, 1488), 18, fill=PAPER, outline=(20, 56, 74, 40), width=2)
    d.text((64, 1420), 'Ask about this case…', fill=MUTED, font=font(26))
    save(img, '05_follow_up.png')


def shot_onboard():
    img = Image.new('RGBA', (W, H), NAVY)
    d = ImageDraw.Draw(img)
    d.text((48, 70), 'eTribunals', fill=WHITE, font=font(32, True))
    d.text((860, 70), 'Skip', fill=WHITE, font=font(28, True))
    rr(d, (390, 420, 690, 720), 40, fill=PAPER)
    d.text((470, 520), '✦', fill=TEAL, font=font(90, True))
    rr(d, (80, 820, W - 80, 1180), 28, fill=PAPER)
    d.text((160, 880), 'AI Summarize', fill=INK, font=font(44, True))
    d.text((120, 960), 'Open an order PDF and tap AI Summarize.', fill=MUTED, font=font(26))
    d.text((130, 1010), 'See held points, then ask a follow-up.', fill=MUTED, font=font(26))
    d.text((170, 1060), 'No API key to paste.', fill=MUTED, font=font(26))
    rr(d, (80, 1680, W - 80, 1820), 18, fill=TEAL)
    d.text((430, 1724), 'Next', fill=WHITE, font=font(36, True))
    save(img, '06_onboarding_ai.png')


def feature():
    img = Image.new('RGBA', (1024, 500), NAVY)
    d = ImageDraw.Draw(img)
    d.rectangle((620, 0, 1024, 500), fill=TEAL)
    d.text((48, 90), 'eTribunals', fill=WHITE, font=font(54, True))
    d.text((48, 180), 'Indian tribunal tracker', fill=(246, 243, 238, 230), font=font(32))
    d.text((48, 250), 'NCLAT · NCLT · NCDRC · ITAT · DRT', fill=GOLD, font=font(24, True))
    d.text((48, 310), 'Cause lists, orders, bookmarks', fill=WHITE, font=font(26))
    d.text((48, 360), 'AI Summarize on PDFs', fill=WHITE, font=font(26))
    d.text((680, 200), '✦', fill=WHITE, font=font(90, True))
    d.text((655, 310), 'On your phone', fill=WHITE, font=font(28, True))
    OUT.mkdir(parents=True, exist_ok=True)
    img.convert('RGB').save(OUT / 'feature_graphic_1024x500.png', 'PNG')


def hi_res_icon():
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=110, fill=NAVY)
    m = size
    cx = m / 2
    pw = 36
    d.rectangle([cx - pw / 2, 150, cx + pw / 2, 370], fill=CREAM)
    d.rectangle([150, 360, 362, 400], fill=GOLD)
    d.rectangle([110, 130, 402, 168], fill=CREAM)
    for x in (160, 352):
        d.line([(cx, 150), (x, 250)], fill=GOLD, width=10)
        d.arc([x - 55, 235, x + 55, 310], 0, 180, fill=GOLD, width=12)
    img.convert('RGB').save(OUT / 'hi_res_icon_512.png', 'PNG')


if __name__ == '__main__':
    SHOTS.mkdir(parents=True, exist_ok=True)
    shot_tribunals()
    shot_cases()
    shot_today()
    shot_pdf()
    shot_summary()
    shot_onboard()
    feature()
    hi_res_icon()
    print('done', OUT)
