#!/usr/bin/env python3
"""Output weather info as Pango markup for eww."""
import json
import urllib.request

def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def icon(desc):
    d = desc.lower()
    if "thunder"                  in d: return "⚡"
    if "snow"                     in d: return "❄"
    if "rain" in d or "drizzle" in d: return "🌧"
    if "cloud" in d and "part"   in d: return "⛅"
    if "overcast" in d or "cloud" in d: return "☁"
    if "fog"  in d or "mist"     in d: return "🌫"
    if "sunny" in d or "clear"   in d: return "☀"
    return "🌡"

try:
    req = urllib.request.Request(
        "https://wttr.in/?format=j1",
        headers={"User-Agent": "Mozilla/5.0"}
    )
    with urllib.request.urlopen(req, timeout=7) as r:
        d = json.loads(r.read())

    cur  = d["current_condition"][0]
    area = d["nearest_area"][0]
    city    = esc(area["areaName"][0]["value"])
    country = esc(area["country"][0]["value"])
    temp    = cur["temp_C"]
    feels   = cur["FeelsLikeC"]
    desc    = esc(cur["weatherDesc"][0]["value"])
    wind    = cur["windspeedKmph"]
    today   = d["weather"][0]
    hi, lo  = today["maxtempC"], today["mintempC"]

    ic = icon(desc)
    print(
        f'<span foreground="#ffffff" font_size="large" font_weight="bold">{ic}  {temp}°C</span>\n'
        f'<span foreground="#cccccc">{desc}</span>\n'
        f'<span foreground="#555555">Feels {feels}°C   H:{hi}° L:{lo}°\n'
        f'Wind {wind} km/h\n'
        f'{city}, {country}</span>'
    )
except Exception as e:
    print(f'<span foreground="#555555">Unavailable</span>')
