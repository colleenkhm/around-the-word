import json, csv, os, time, urllib.request, urllib.parse, urllib.error
from collections import defaultdict

DEST = "/Users/colleenmurray/Desktop/code/around_the_word/research_drafts/weather"
latlong = {r['country_id']: (r['latitude'], r['longitude']) for r in json.load(open(f"{DEST}/latlong.json"))}
names = {}
r = csv.reader(open("/Users/colleenmurray/Desktop/code/around_the_word/research_drafts/best_times/best_times_draft.csv"))
next(r)
for row in r:
    names[row[0]] = row[1]

MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

draft_path = f"{DEST}/weather_draft.csv"
flagged_path = f"{DEST}/weather_flagged.csv"

done_codes = set()
if os.path.exists(draft_path):
    r = csv.reader(open(draft_path)); next(r, None)
    for row in r:
        if row: done_codes.add(row[0])
if os.path.exists(flagged_path):
    r = csv.reader(open(flagged_path)); next(r, None)
    for row in r:
        if row: done_codes.add(row[0])

def fetch(lat, lon):
    url = ("https://archive-api.open-meteo.com/v1/archive?"
           + urllib.parse.urlencode({
                "latitude": lat, "longitude": lon,
                "start_date": "2019-01-01", "end_date": "2023-12-31",
                "daily": "temperature_2m_max,temperature_2m_min",
                "temperature_unit": "fahrenheit",
                "timezone": "auto"
           }))
    req = urllib.request.Request(url, headers={"User-Agent": "forin-research/1.0"})
    last_err = None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                return json.load(resp)
        except urllib.error.HTTPError as e:
            last_err = e
            if e.code == 429:
                time.sleep(15 * (attempt + 1))
                continue
            raise
    raise last_err

need_header_draft = not os.path.exists(draft_path)
need_header_flag = not os.path.exists(flagged_path)
fdraft = open(draft_path, "a", newline="")
fflag = open(flagged_path, "a", newline="")
wdraft = csv.writer(fdraft)
wflag = csv.writer(fflag)
if need_header_draft:
    wdraft.writerow(["country_code","country_name","latitude","longitude","monthly_avg_high_low_f"])
if need_header_flag:
    wflag.writerow(["country_code","country_name","error"])

codes = sorted(latlong.keys())
todo = [c for c in codes if c not in done_codes]
print("already done:", len(done_codes), "remaining:", len(todo))

count = 0
for code in todo:
    lat, lon = latlong[code]
    try:
        data = fetch(lat, lon)
        times = data["daily"]["time"]
        tmax = data["daily"]["temperature_2m_max"]
        tmin = data["daily"]["temperature_2m_min"]
        month_max = defaultdict(list)
        month_min = defaultdict(list)
        for t, mx, mn in zip(times, tmax, tmin):
            if mx is None or mn is None:
                continue
            m = int(t.split("-")[1]) - 1
            month_max[m].append(mx)
            month_min[m].append(mn)
        avg_high = [round(sum(month_max[m])/len(month_max[m])) if month_max[m] else None for m in range(12)]
        avg_low  = [round(sum(month_min[m])/len(month_min[m])) if month_min[m] else None for m in range(12)]
        line = "; ".join(f"{MONTHS[m]} {avg_high[m]}/{avg_low[m]}F" for m in range(12))
        wdraft.writerow([code, names.get(code, code), lat, lon, line])
        fdraft.flush()
    except Exception as e:
        wflag.writerow([code, names.get(code, code), str(e)])
        fflag.flush()
    time.sleep(4)
    count += 1
    if count % 20 == 0:
        print(f"progress: {count}/{len(todo)}")

fdraft.close()
fflag.close()
print("batch complete:", count, "processed this run")
