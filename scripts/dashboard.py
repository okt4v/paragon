#!/usr/bin/env python3
"""
Paragon Dashboard — static PNG snapshot generator.

Generates a dashboard PNG snapshot. The live desktop dashboard is handled
by eww. This script is kept for manual exports/screenshots. Shows:
  - Clock & date
  - Weather (wttr.in, no API key)
  - Market prices (Yahoo Finance, no API key)
  - News headlines (RSS)
  - Todo list (~/.config/paragon/todos.txt)

Config: ~/.config/paragon/dashboard.json
Run:    python3 dashboard.py
Auto:   systemctl --user start paragon-dashboard.timer
"""

import json
import os
import subprocess
import sys
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow not installed. Run: sudo pacman -S python-pillow", file=sys.stderr)
    sys.exit(1)

# ── Paths ─────────────────────────────────────────────────────────────────────

WALLPAPER_OUT = Path.home() / ".cache" / "paragon" / "dashboard.png"
TODO_PATH     = Path.home() / ".config" / "paragon" / "todos.txt"
CONFIG_PATH   = Path.home() / ".config" / "paragon" / "dashboard.json"

# ── Default config (overridden by dashboard.json) ─────────────────────────────

DEFAULTS = {
    "weather_location": "",
    "market_symbols":   ["BTC-USD", "ETH-USD", "SPY", "QQQ", "NVDA"],
    "news_feeds": [
        "https://feeds.bbci.co.uk/news/rss.xml",
        "https://feeds.reuters.com/reuters/topNews",
    ],
    "news_count":  8,
    "resolution": "auto",
}

# ── Palette ───────────────────────────────────────────────────────────────────

BG     = (13,  20,  36)
CARD   = (22,  33,  55)
CARD2  = (18,  27,  46)
BORDER = (44,  59,  80)
TEXT   = (226, 232, 240)
MUTED  = (90, 105, 125)
ACCENT = (94, 234, 212)
GREEN  = (74, 222, 128)
RED    = (248, 113, 133)
YELLOW = (250, 204,  21)
BLUE   = (56,  189, 248)

# ── Fonts ─────────────────────────────────────────────────────────────────────

_FONT_REGULAR = [
    "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf",
    "/usr/share/fonts/OTF/JetBrainsMonoNerdFont-Regular.otf",
    "/usr/share/fonts/jetbrains-mono/JetBrainsMono-Regular.ttf",
    "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
    "/usr/share/fonts/liberation/LiberationMono-Regular.ttf",
]
_FONT_BOLD = [
    "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf",
    "/usr/share/fonts/OTF/JetBrainsMonoNerdFont-Bold.otf",
    "/usr/share/fonts/TTF/JetBrainsMono-Bold.ttf",
    "/usr/share/fonts/TTF/DejaVuSansMono-Bold.ttf",
    "/usr/share/fonts/liberation/LiberationMono-Bold.ttf",
]

def _find(paths):
    for p in paths:
        if Path(p).exists():
            return p
    return None

def load_fonts():
    r = _find(_FONT_REGULAR)
    b = _find(_FONT_BOLD) or r

    def f(path, size):
        try:
            return ImageFont.truetype(path, size) if path else ImageFont.load_default()
        except Exception:
            return ImageFont.load_default()

    return {
        "clock":   f(b, 80),
        "date":    f(r, 22),
        "heading": f(b, 17),
        "body":    f(r, 14),
        "small":   f(r, 12),
        "label":   f(b, 12),
        "tag":     f(b, 11),
    }

# ── Helpers ───────────────────────────────────────────────────────────────────

def fetch_json(url, timeout=7):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read())

def get_resolution():
    try:
        r = subprocess.run(["hyprctl", "monitors", "-j"],
                           capture_output=True, text=True, timeout=3)
        monitors = json.loads(r.stdout)
        if monitors:
            m = monitors[0]
            return m["width"], m["height"]
    except Exception:
        pass
    return 1920, 1080

def load_config():
    cfg = DEFAULTS.copy()
    if CONFIG_PATH.exists():
        try:
            cfg.update(json.loads(CONFIG_PATH.read_text()))
        except Exception:
            pass
    return cfg

def rr(draw, box, radius, fill, outline=None, width=1):
    """Rounded rectangle shorthand."""
    draw.rounded_rectangle(list(box), radius=radius, fill=fill,
                           outline=outline, width=width)

def text_w(draw, text, font):
    return draw.textlength(text, font=font)

def truncate(draw, text, font, max_w):
    if text_w(draw, text, font) <= max_w:
        return text
    while len(text) > 1:
        cand = text[:-1] + "…"
        if text_w(draw, cand, font) <= max_w:
            return cand
        text = text[:-1]
    return "…"

def wrap(draw, text, font, max_w, max_lines=2):
    """Word-wrap text, return list of lines up to max_lines."""
    words = text.split()
    lines, line = [], ""
    for word in words:
        test = (line + " " + word).strip()
        if text_w(draw, test, font) <= max_w:
            line = test
        else:
            if line:
                lines.append(line)
            if len(lines) >= max_lines:
                return lines
            line = word
    if line:
        lines.append(line)
    return lines[:max_lines]

# ── Data fetchers ─────────────────────────────────────────────────────────────

def fetch_weather(location=""):
    url = f"https://wttr.in/{location}?format=j1"
    try:
        d = fetch_json(url)
        cur  = d["current_condition"][0]
        area = d["nearest_area"][0]
        city = area["areaName"][0]["value"]
        country = area["country"][0]["value"]
        forecast_today = d["weather"][0]
        return {
            "ok":       True,
            "city":     city,
            "country":  country,
            "temp":     cur["temp_C"],
            "feels":    cur["FeelsLikeC"],
            "desc":     cur["weatherDesc"][0]["value"],
            "humidity": cur["humidity"],
            "wind":     cur["windspeedKmph"],
            "high":     forecast_today["maxtempC"],
            "low":      forecast_today["mintempC"],
        }
    except Exception as e:
        return {"ok": False, "error": str(e)}

def weather_icon(desc):
    d = desc.lower()
    if "thunder"           in d: return "⚡"
    if "snow"              in d: return "❄ "
    if "rain" in d or "drizzle" in d: return "🌧"
    if "cloud" in d and "part" in d: return "⛅"
    if "overcast" in d or "cloud" in d: return "☁ "
    if "fog"  in d or "mist" in d: return "🌫"
    if "sunny" in d or "clear" in d or "sun" in d: return "☀ "
    return "🌡"

def fetch_market(symbol):
    url = (f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}"
           f"?interval=1d&range=1d")
    try:
        d    = fetch_json(url)
        meta = d["chart"]["result"][0]["meta"]
        price = meta["regularMarketPrice"]
        prev  = meta["chartPreviousClose"]
        pct   = (price - prev) / prev * 100
        return {"symbol": symbol, "price": price, "pct": pct, "ok": True}
    except Exception:
        return {"symbol": symbol, "ok": False}

def fetch_news(feeds, count=8):
    headlines = []
    for url in feeds:
        if len(headlines) >= count:
            break
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=7) as r:
                root = ET.fromstring(r.read())
            for item in root.findall(".//item"):
                title = (item.findtext("title") or "").strip()
                if title and len(title) > 10:
                    headlines.append(title)
                if len(headlines) >= count:
                    break
        except Exception:
            continue
    return headlines[:count]

def load_todos():
    if not TODO_PATH.exists():
        return []
    return [l.rstrip() for l in TODO_PATH.read_text().splitlines() if l.strip()]

def fmt_price(symbol, price):
    crypto = ("BTC", "ETH", "BNB", "SOL", "XRP", "ADA", "DOGE")
    if any(c in symbol for c in crypto):
        return f"${price:>10,.0f}" if price >= 1000 else f"${price:>10.2f}"
    return f"${price:>10.4f}" if price < 1 else f"${price:>10.2f}"

# ── Drawing ───────────────────────────────────────────────────────────────────

def draw_dashboard(W, H, data, fonts):
    img  = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    PAD = 28
    GAP = 14
    R   = 10

    # Subtle dot-grid texture
    for x in range(0, W, 36):
        for y in range(0, H, 36):
            draw.point((x, y), fill=(22, 33, 55))

    now = data["now"]

    # ── Top bar ───────────────────────────────────────────────────────────────
    BAR_H = 44
    rr(draw, (PAD, PAD, W-PAD, PAD+BAR_H), R, CARD, BORDER, 1)

    draw.text((PAD+16, PAD+14), "PARAGON", font=fonts["label"], fill=ACCENT)

    updated = f"Updated {now:%H:%M:%S}"
    uw = text_w(draw, updated, fonts["small"])
    draw.text((W-PAD-16-uw, PAD+16), updated, font=fonts["small"], fill=MUTED)

    date_full = now.strftime("%A, %d %B %Y")
    dw = text_w(draw, date_full, fonts["small"])
    draw.text((W-PAD-16-uw-dw-24, PAD+16), date_full, font=fonts["small"], fill=MUTED)

    # ── Column layout ─────────────────────────────────────────────────────────
    Y0     = PAD + BAR_H + GAP
    Y1     = H - PAD
    col_w  = (W - 2*PAD - 2*GAP) // 3
    C1     = PAD
    C2     = C1 + col_w + GAP
    C3     = C2 + col_w + GAP

    def col_card(x, y0, y1, inner=False):
        rr(draw, (x, y0, x+col_w, y1), R,
           CARD2 if inner else CARD, BORDER, 1)
        return x+16, y0+12

    # ── Col 1: Clock / Weather / Todos ────────────────────────────────────────

    # Clock
    clock_h = 115
    cx, cy = col_card(C1, Y0, Y0+clock_h)
    time_str = now.strftime("%H:%M")
    tw = text_w(draw, time_str, fonts["clock"])
    draw.text((C1 + (col_w - tw)//2, Y0+10), time_str, font=fonts["clock"], fill=TEXT)
    date_str = now.strftime("%a  %d %b  %Y")
    dw = text_w(draw, date_str, fonts["date"])
    draw.text((C1 + (col_w - dw)//2, Y0+88), date_str, font=fonts["date"], fill=MUTED)

    # Weather
    wy0 = Y0 + clock_h + GAP
    weather_h = 170
    wx, wy = col_card(C1, wy0, wy0+weather_h)
    draw.text((wx, wy), "WEATHER", font=fonts["label"], fill=ACCENT)
    wy += 22

    w = data.get("weather", {})
    if w.get("ok"):
        icon = weather_icon(w["desc"])
        temp = f"{icon}{w['temp']}°C"
        draw.text((wx, wy), temp, font=fonts["heading"], fill=TEXT)
        tw2 = text_w(draw, temp, fonts["heading"])
        # High/Low next to temp
        hl = f"H:{w['high']}° L:{w['low']}°"
        draw.text((wx + tw2 + 12, wy+1), hl, font=fonts["small"], fill=MUTED)
        wy += 26
        draw.text((wx, wy), w["desc"], font=fonts["body"], fill=TEXT)
        wy += 20
        draw.text((wx, wy), f"{w['city']}, {w['country']}", font=fonts["small"], fill=MUTED)
        wy += 18
        draw.text((wx, wy), f"Feels {w['feels']}°C", font=fonts["small"], fill=MUTED)
        wy += 16
        draw.text((wx, wy), f"Humidity {w['humidity']}%  ·  Wind {w['wind']} km/h",
                  font=fonts["small"], fill=MUTED)
    else:
        draw.text((wx, wy), "Weather unavailable", font=fonts["body"], fill=MUTED)

    # Todos
    ty0 = wy0 + weather_h + GAP
    if ty0 + 50 < Y1:
        tx, ty = col_card(C1, ty0, Y1)
        draw.text((tx, ty), "TODOS", font=fonts["label"], fill=ACCENT)
        ty += 22
        todos = data.get("todos", [])
        if not todos:
            draw.text((tx, ty), "Edit ~/.config/paragon/todos.txt",
                      font=fonts["small"], fill=MUTED)
        else:
            for todo in todos:
                if ty + 18 > Y1 - 10:
                    break
                done  = todo.startswith("[x]") or todo.startswith("[X]") or todo.startswith("x ")
                clean = todo.lstrip("[xX] ").lstrip("[ ] ").lstrip("- ").lstrip("x ").strip()
                label = truncate(draw, clean, fonts["body"], col_w - 36)
                mark  = "✓" if done else "☐"
                color = MUTED if done else TEXT
                draw.text((tx, ty), mark, font=fonts["body"], fill=ACCENT if not done else MUTED)
                draw.text((tx+18, ty), label, font=fonts["body"], fill=color)
                ty += 20

    # ── Col 2: Markets ────────────────────────────────────────────────────────
    mx, my = col_card(C2, Y0, Y1)
    draw.text((mx, my), "MARKETS", font=fonts["label"], fill=ACCENT)
    my += 24

    for m in data.get("markets", []):
        if my + 58 > Y1 - 10:
            break
        sym = m["symbol"].replace("-USD", "").replace("-", "/")
        if m.get("ok"):
            pct   = m["pct"]
            up    = pct >= 0
            color = GREEN if up else RED
            arrow = "▲" if up else "▼"
            price_str = fmt_price(m["symbol"], m["price"]).strip()
            pct_str   = f"{arrow} {abs(pct):.2f}%"

            draw.text((mx, my), sym, font=fonts["heading"], fill=TEXT)
            pw = text_w(draw, price_str, fonts["body"])
            draw.text((C2 + col_w - 16 - pw, my+1), price_str, font=fonts["body"], fill=TEXT)
            my += 22
            pcw = text_w(draw, pct_str, fonts["small"])
            draw.text((C2 + col_w - 16 - pcw, my), pct_str, font=fonts["small"], fill=color)
        else:
            draw.text((mx, my), f"{sym}  —", font=fonts["body"], fill=MUTED)
            my += 22

        my += 14
        draw.line([(mx, my-4), (C2+col_w-16, my-4)], fill=BORDER, width=1)

    # ── Col 3: News ───────────────────────────────────────────────────────────
    nx, ny = col_card(C3, Y0, Y1)
    draw.text((nx, ny), "NEWS", font=fonts["label"], fill=ACCENT)
    ny += 24

    for headline in data.get("news", []):
        if ny + 16 > Y1 - 10:
            break
        lines = wrap(draw, headline, fonts["small"], col_w - 30, max_lines=2)
        if not lines:
            continue
        # Bullet dot
        draw.ellipse([nx, ny+4, nx+5, ny+9], fill=ACCENT)
        draw.text((nx+14, ny), lines[0], font=fonts["small"], fill=TEXT)
        ny += 16
        if len(lines) > 1:
            draw.text((nx+14, ny), lines[1], font=fonts["small"], fill=MUTED)
            ny += 16
        ny += 8

    return img

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    cfg = load_config()

    if cfg["resolution"] == "auto":
        W, H = get_resolution()
    else:
        W, H = map(int, cfg["resolution"].split("x"))

    now = datetime.now()
    print(f"[{now:%H:%M:%S}] Generating dashboard ({W}×{H})…")

    print("  → weather")
    weather = fetch_weather(cfg["weather_location"])

    print("  → markets")
    markets = [fetch_market(s) for s in cfg["market_symbols"]]

    print("  → news")
    news = fetch_news(cfg["news_feeds"], cfg["news_count"])

    data = {
        "now":     now,
        "weather": weather,
        "markets": markets,
        "news":    news,
        "todos":   load_todos(),
    }

    fonts = load_fonts()
    img   = draw_dashboard(W, H, data, fonts)

    WALLPAPER_OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(WALLPAPER_OUT), "PNG", optimize=True)
    print(f"  → saved {WALLPAPER_OUT}")

    print(f"  → snapshot saved to {WALLPAPER_OUT}")

if __name__ == "__main__":
    main()
