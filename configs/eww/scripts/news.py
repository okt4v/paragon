#!/usr/bin/env python3
"""Output news headlines as Pango markup for eww."""
import urllib.request
import xml.etree.ElementTree as ET

FEEDS = [
    "https://feeds.bbci.co.uk/news/rss.xml",
    "https://feeds.reuters.com/reuters/topNews",
]
COUNT = 9

def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

headlines = []
for url in FEEDS:
    if len(headlines) >= COUNT:
        break
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=7) as r:
            root = ET.fromstring(r.read())
        for item in root.findall(".//item"):
            title = (item.findtext("title") or "").strip()
            if title and len(title) > 10:
                headlines.append(title)
            if len(headlines) >= COUNT:
                break
    except Exception:
        continue

lines = []
for h in headlines:
    h = esc(h)
    if len(h) > 72:
        h = h[:69] + "…"
    lines.append(f'<span foreground="#ff6600">▸</span> <span foreground="#e0e0e0">{h}</span>')

print("\n".join(lines) if lines else '<span foreground="#555555">No headlines</span>')
