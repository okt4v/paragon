#!/usr/bin/env python3
"""Output todos as Pango markup for eww."""
from pathlib import Path

TODO = Path.home() / ".config" / "paragon" / "todos.txt"

def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

if not TODO.exists() or TODO.stat().st_size == 0:
    print('<span foreground="#555555">No todos — run: paragon todo add ...</span>')
    raise SystemExit

lines = []
for raw in TODO.read_text().splitlines():
    raw = raw.strip()
    if not raw:
        continue
    done  = raw.startswith("[x]") or raw.startswith("[X]")
    clean = esc(raw.lstrip("[xX] ").lstrip("[ ] ").lstrip("- ").strip())
    if done:
        lines.append(f'<span foreground="#333333">✓  {clean}</span>')
    else:
        lines.append(f'<span foreground="#ff6600">☐</span>  <span foreground="#f0f0f0">{clean}</span>')

print("\n".join(lines))
