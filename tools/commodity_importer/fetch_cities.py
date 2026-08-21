"""
Fetches top-population cities from GeoNames and outputs a CSV matching the
`cities` table columns (see around-the-word-data-architecture.md's
"Commodity: cities" section) — paste the rows straight into the Cities
sheet of the collection spreadsheet.

This only ever populates `is_major` (every row here is "top N by
population" for the country) and never `is_featured` — that column is
left to editorial judgment and this script leaves it blank on purpose.
Fill it in by hand for the cities actually worth surfacing on the country
page. See the doc: "An importer may only touch is_major."

Requires a free GeoNames username (register at geonames.org/login) — pass
it with --username or set the GEONAMES_USERNAME environment variable.

Usage:
    export GEONAMES_USERNAME=your_username
    python fetch_cities.py CR --top 8 > cities.csv
    python fetch_cities.py CR PT GR --top 5 > cities.csv
"""

import argparse
import csv
import os
import sys
import time

import requests

API_URL = "http://api.geonames.org/searchJSON"

FIELDS = [
    "country_code",
    "name",
    "population",
    "latitude",
    "longitude",
    "is_major",
    "is_featured",
]


def fetch_cities(iso2, top_n, username):
    params = {
        "country": iso2,
        "featureClass": "P",  # populated places
        "maxRows": top_n,
        "orderby": "population",
        "username": username,
    }
    resp = requests.get(API_URL, params=params, timeout=15)
    # GeoNames reports errors (bad/not-yet-enabled username, rate limit,
    # etc.) as a JSON "status" body — sometimes under a 200, sometimes under
    # a non-200 like 401 — so check for it before raise_for_status() would
    # otherwise mask GeoNames' actual message behind a generic HTTP error.
    # (Confirmed 2026-08-10: a not-yet-enabled account gets a 401 with a
    # "user does not exist" status body — misleading wording, but it means
    # "enable free web services," not "this username is wrong.")
    try:
        payload = resp.json()
    except ValueError:
        resp.raise_for_status()
        raise
    if "status" in payload:
        message = payload["status"].get("message", "unknown GeoNames error")
        if "does not exist" in message:
            message += (
                " (if the username is right, this usually means the account's "
                "free web services aren't enabled yet: log in and visit "
                "https://www.geonames.org/enablefreewebservice)"
            )
        raise RuntimeError(message)
    resp.raise_for_status()
    return payload.get("geonames", [])


def normalize(iso2, entry):
    return {
        "country_code": iso2,
        "name": entry.get("name"),
        "population": entry.get("population"),
        "latitude": entry.get("lat"),
        "longitude": entry.get("lng"),
        "is_major": True,
        "is_featured": "",  # curated — never auto-filled, see module docstring
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("iso_codes", nargs="+", help="ISO 3166-1 alpha-2 codes, e.g. CR PT GR")
    parser.add_argument("--top", type=int, default=10, help="cities per country (default 10)")
    parser.add_argument("--username", default=os.environ.get("GEONAMES_USERNAME"))
    args = parser.parse_args()

    if not args.username:
        print(
            "No GeoNames username. Pass --username or set GEONAMES_USERNAME\n"
            "(free registration: https://www.geonames.org/login)",
            file=sys.stderr,
        )
        sys.exit(1)

    writer = csv.DictWriter(sys.stdout, fieldnames=FIELDS)
    writer.writeheader()

    for i, iso2 in enumerate(args.iso_codes):
        iso2 = iso2.upper()
        try:
            cities = fetch_cities(iso2, args.top, args.username)
        except (requests.HTTPError, RuntimeError) as e:
            print(f"skipping {iso2}: {e}", file=sys.stderr)
            continue
        for entry in cities:
            writer.writerow(normalize(iso2, entry))
        if i < len(args.iso_codes) - 1:
            time.sleep(0.2)


if __name__ == "__main__":
    main()
