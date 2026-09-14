import csv, re, json, sys

MONTHS = ["January","February","March","April","May","June","July","August",
          "September","October","November","December"]
MON_ABBR = {m[:3].lower(): m for m in MONTHS}
# also allow "sept" for September
MON_ABBR["sep"] = "September"

def find_months_in_clause(clause):
    """Find month tokens (Jan, Feb, ... incl. 'Mid Jan', 'late Sep') in order, dedup."""
    found = []
    for m in re.finditer(r'\b([A-Z][a-z]{2,8})\b', clause):
        tok = m.group(1).lower()[:3]
        if tok in MON_ABBR:
            full = MON_ABBR[tok]
            if full not in found:
                found.append(full)
    return found

def expand_range(clause):
    """Handle 'Jan-Mar' as a contiguous range vs 'Jan & Mar' as a list.
    If clause contains a '-' between two month tokens close together, fill the range."""
    months_found = find_months_in_clause(clause)
    if len(months_found) < 2:
        return months_found
    # crude range-fill: if there's a hyphen and exactly 2 endpoints per '-' segment,
    # fill contiguous months between them (handles wraparound e.g. Nov-Feb)
    result = []
    segments = re.split(r'\s*&\s*|,\s*', clause)
    for seg in segments:
        seg_months = find_months_in_clause(seg)
        if '-' in seg and len(seg_months) == 2:
            i1, i2 = MONTHS.index(seg_months[0]), MONTHS.index(seg_months[1])
            if i1 <= i2:
                rng = MONTHS[i1:i2+1]
            else:
                rng = MONTHS[i1:] + MONTHS[:i2+1]
            for mo in rng:
                if mo not in result:
                    result.append(mo)
        else:
            for mo in seg_months:
                if mo not in result:
                    result.append(mo)
    return result if result else months_found

def crowd_level(text):
    t = text.lower()
    if any(k in t for k in ["busiest", "priciest", "peak season", "most crowded", "book ahead", "book far ahead"]):
        return "peak"
    if any(k in t for k in ["cheapest", "quiet", "low season", "fewer crowds", "off-peak", "fewer tourists", "uncrowded"]):
        return "low"
    if "crowded" in t:
        return "high"
    return "moderate"

def make_why_short(clause):
    c = clause.strip()
    c = re.sub(r'^(best overall,?\s*)', '', c, flags=re.I)
    # take up to first comma, semicolon, or '--'
    c = re.split(r',| -- |\(', c)[0].strip()
    words = c.split()
    c = ' '.join(words[:6]).rstrip('.:;-')
    if not c:
        c = ' '.join(clause.split()[:6]).rstrip('.:;-')
    return c.strip().lower() if not c[:1].isupper() or c.split()[0].lower() in MON_ABBR.values() else c

def parse_country(draft_notes, month_cap=6):
    sentences = re.split(r'(?<=[.])\s+', draft_notes.strip())
    entries = []
    covered = set()
    for sent in sentences:
        sent = sent.strip().rstrip('.')
        if not sent or sent.lower().startswith('avoid'):
            continue
        if ':' not in sent:
            continue
        lead, _, rest = sent.partition(':')
        months = expand_range(lead)
        if not months:
            continue
        new_months = [m for m in months if m not in covered]
        if not new_months:
            continue
        if len(covered) + len(new_months) > month_cap:
            if entries:
                # would blow the cap and we already have at least one entry — stop here
                continue
            # first entry itself is oversized — truncate rather than drop it entirely
            room = month_cap - len(covered)
            new_months = new_months[:room]
            months = [m for m in months if m in covered or m in new_months]
        why_short = make_why_short(rest)
        why = rest.strip().lstrip('-').strip()
        entries.append({
            "months": ",".join(months),
            "why_short": why_short,
            "why": why,
            "crowd_level": crowd_level(sent),
        })
        covered.update(months)
        if len(covered) >= month_cap:
            break
    return entries

if __name__ == "__main__":
    DEST = "/Users/colleenmurray/Desktop/code/around_the_word/research_drafts/best_times"
    r = csv.reader(open(f"{DEST}/best_times_draft.csv")); next(r)
    rows = list(r)
    test_codes = ["JP","KE","GD","MN","PT"]
    for row in rows:
        if row[0] not in test_codes:
            continue
        entries = parse_country(row[3])
        print(f"=== {row[1]} ({row[0]}) ===")
        for e in entries:
            print(f"  {e['months']:40s} | {e['why_short']:35s} | {e['crowd_level']}")
            print(f"    why: {e['why']}")
        print()
