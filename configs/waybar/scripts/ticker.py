#!/usr/bin/env python3
"""Waybar finance ticker module.

Shows a configurable list of stock/crypto prices from Yahoo Finance (no API key needed).
Edit SYMBOLS below to customize what appears in your bar.
"""
import json
import urllib.request
import sys

SYMBOLS = ["BTC-USD", "ETH-USD", "SPY"]

def fetch_price(symbol: str) -> str | None:
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1d&range=1d"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            data = json.loads(r.read())
        meta = data["chart"]["result"][0]["meta"]
        price = meta["regularMarketPrice"]
        prev = meta["chartPreviousClose"]
        change_pct = ((price - prev) / prev) * 100
        sign = "+" if change_pct >= 0 else ""
        if symbol in ("BTC-USD", "ETH-USD"):
            return f"{symbol.replace('-USD','')} ${price:,.0f} ({sign}{change_pct:.1f}%)"
        return f"{symbol} ${price:.2f} ({sign}{change_pct:.1f}%)"
    except Exception:
        return None

def main():
    parts = [p for s in SYMBOLS if (p := fetch_price(s))]
    if parts:
        print("  ".join(parts))
    else:
        print("N/A")

if __name__ == "__main__":
    main()
