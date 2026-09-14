import csv, re, json, sys, os, urllib.request
sys.path.insert(0, "/Users/colleenmurray/Desktop/code/around_the_word/research_drafts/best_times")
from parse_best_times import parse_country, MONTHS

DEST_BT = "/Users/colleenmurray/Desktop/code/around_the_word/research_drafts/best_times"
DEST_W = "/Users/colleenmurray/Desktop/code/around_the_word/research_drafts/weather"

# load weather: {code: {MonthName: (high, low)}}
weather = {}
r = csv.reader(open(f"{DEST_W}/weather_draft.csv")); next(r)
for row in r:
    code, name, lat, lon, line = row
    monthly = {}
    for part in line.split("; "):
        # e.g. "Jan 59/46F"
        m = re.match(r'(\w{3}) (-?\d+)/(-?\d+)F', part.strip())
        if m:
            abbr, hi, lo = m.groups()
            full = {"Jan":"January","Feb":"February","Mar":"March","Apr":"April","May":"May","Jun":"June",
                    "Jul":"July","Aug":"August","Sep":"September","Oct":"October","Nov":"November","Dec":"December"}[abbr]
            monthly[full] = (int(hi), int(lo))
    weather[code] = monthly

def weather_note_for(code, months_csv):
    wm = weather.get(code)
    if not wm:
        return None
    months = [m.strip() for m in months_csv.split(",")]
    highs = [wm[m][0] for m in months if m in wm]
    lows = [wm[m][1] for m in months if m in wm]
    if not highs:
        return None
    avg_hi = round(sum(highs)/len(highs))
    avg_lo = round(sum(lows)/len(lows))
    return f"Avg {avg_hi}°F high / {avg_lo}°F low"

# build best_times per country
r = csv.reader(open(f"{DEST_BT}/best_times_draft.csv")); next(r)
rows = list(r)

output = {}
zero_entry_countries = []
for row in rows:
    code, name, source_method, draft_notes = row
    entries = parse_country(draft_notes)
    for e in entries:
        note = weather_note_for(code, e["months"])
        if note:
            e["weather_note"] = note
    if not entries:
        zero_entry_countries.append((code, name))
    output[code] = {"name": name, "best_times": entries}

json.dump(output, open(f"{DEST_BT}/parsed_best_times.json", "w"), indent=1)

print("total countries parsed:", len(output))
print("countries with zero parsed entries:", len(zero_entry_countries))
for c in zero_entry_countries:
    print("  ", c)

entry_counts = [len(v["best_times"]) for v in output.values()]
print("avg entries/country:", sum(entry_counts)/len(entry_counts))
print("max months covered any country:")
for code, v in output.items():
    months_covered = set()
    for e in v["best_times"]:
        months_covered.update(e["months"].split(","))
    if len(months_covered) > 6:
        print("  OVER CAP:", code, v["name"], len(months_covered))
