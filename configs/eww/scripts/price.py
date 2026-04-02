#!/usr/bin/env python3
"""Output a single market price with Pango markup for eww."""
import json
import sys
import urllib.request

symbol = sys.argv[1] if len(sys.argv) > 1 else "SPY"

def fetch(sym):
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{sym}?interval=1d&range=1d"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=6) as r:
        d = json.loads(r.read())
    meta  = d["chart"]["result"][0]["meta"]
    price = meta["regularMarketPrice"]
    prev  = meta["chartPreviousClose"]
    pct   = (price - prev) / prev * 100
    return price, pct

try:
    price, pct = fetch(symbol)
    up    = pct >= 0
    color = "#00dd55" if up else "#ff2233"
    arrow = "▲" if up else "▼"

    crypto = ("BTC", "ETH", "BNB", "SOL", "XRP")
    if any(c in symbol for c in crypto):
        price_str = f"${price:,.0f}" if price >= 100 else f"${price:.2f}"
    else:
        price_str = f"${price:.2f}"

    pct_str = f"{arrow} {abs(pct):.2f}%"
    print(f'<span foreground="#ffaa00">{price_str}</span>  <span foreground="{color}">{pct_str}</span>')
except Exception:
    print(f'<span foreground="#555555">N/A</span>')
