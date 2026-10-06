"""Check the three lab API keys from .env with one cheap call each.
Run from the repo root:  uv run python iam/check_api_keys.py
"""
import os
from pathlib import Path

import requests

env = Path(__file__).resolve().parent.parent / ".env"
for line in env.read_text().splitlines():
    line = line.strip()
    if line and not line.startswith("#") and "=" in line:
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip())

def check(name, url, ok):
    key = os.getenv(name)
    if not key:
        print(f"[MISSING] {name}")
        return
    try:
        r = requests.get(url.format(key=key), timeout=10)
        data = r.json()
        print(f"[{'OK' if ok(r, data) else 'FAIL'}] {name}: HTTP {r.status_code}"
              + ("" if ok(r, data) else f" -> {str(data)[:150]}"))
    except Exception as e:
        print(f"[ERROR] {name}: {e}")

check("OPENWEATHERMAP_API_KEY",
      "https://api.openweathermap.org/data/2.5/weather?q=Bengaluru&appid={key}",
      lambda r, d: r.status_code == 200)
check("EXCHANGERATE_API_KEY",
      "https://v6.exchangerate-api.com/v6/{key}/pair/USD/INR",
      lambda r, d: d.get("result") == "success")
check("AVIATIONSTACK_API_KEY",
      "http://api.aviationstack.com/v1/flights?access_key={key}&limit=1",
      lambda r, d: r.status_code == 200 and "error" not in d)
