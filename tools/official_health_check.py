#!/usr/bin/env python3
"""Weekly ping of official tribunal homepages. Run from repo root: python tools/official_health_check.py"""
from __future__ import annotations

import json
import urllib.error
import urllib.request

URLS = [
    ("NCLAT", "https://nclat.nic.in/"),
    ("NCLT", "https://nclt.gov.in/"),
    ("NGT", "https://www.greentribunal.gov.in/"),
    ("DRT", "https://drt.gov.in/"),
    ("CAT", "https://cgat.gov.in/"),
    ("CESTAT", "https://cestat.gov.in/"),
    ("TDSAT", "https://www.tdsat.gov.in/Delhi/Delhi.php"),
    ("APTEL", "http://aptel.gov.in/en"),
    ("SAT", "https://satweb.sat.gov.in/"),
    ("AFT", "https://aft.gov.in/"),
    ("NCDRC", "https://e-jagriti.gov.in/"),
    ("ATFP", "https://atfp.gov.in/"),
    ("CGIT", "https://apps.labour.gov.in/cgit"),
]


def check(name: str, url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": "eTribunals-health/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=20) as res:
            return {"tribunal": name, "url": url, "ok": True, "status": res.status}
    except urllib.error.HTTPError as e:
        return {"tribunal": name, "url": url, "ok": e.code < 500, "status": e.code, "error": str(e)}
    except Exception as e:
        return {"tribunal": name, "url": url, "ok": False, "error": str(e)}


def main() -> int:
    rows = [check(n, u) for n, u in URLS]
    print(json.dumps(rows, indent=2))
    failed = [r for r in rows if not r.get("ok")]
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
