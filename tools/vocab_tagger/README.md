# Vocab Tagger

Content-authoring tool. Not part of the Flutter app — run this locally when
adding vocab, then hand-merge its output into `assets/data/content/{countryCode}.json`.

Auto-tags each vocab entry with part of speech and, for nouns/adjectives,
grammatical gender and number, using spaCy. See the "Data Model" and "Tagging
pipeline" sections of [language-app-system-design.md](../../language-app-system-design.md)
for why these fields exist and what they mean.

## Setup (one-time)

```bash
cd tools/vocab_tagger
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m spacy download es_core_news_sm
# python -m spacy download fr_core_news_sm   # once French content starts (V1.2)
```

## Usage

```bash
source .venv/bin/activate
python tag_vocab.py path/to/raw_entries.json --lang es > tagged_output.json
```

Input: a JSON list of `{"phrase": ..., "translation": ...}` entries. Add
`"isExpression": true` for multi-word chunks that shouldn't be grammatically
decomposed (e.g. `"¿Dónde está...?"`) — these get `partOfSpeech: "expression"`
and skip gender/number tagging entirely.

Output: the same entries with `partOfSpeech` added, plus `gender`/`number`
for nouns and adjectives. Entries the tagger couldn't confidently handle get
`"needsReview": true` instead of guessed tags.

**Always review the output before merging it in — this is an assist, not an
authority.** Two things spaCy specifically can't get right on its own:
- **Mass vs. countable nouns.** It tags the grammatical form (singular/plural
  as written), not whether a noun is conceptually mass/uncountable (e.g.
  *agua*/water). Change `"number"` to `"mass"` by hand where that applies.
- Anything flagged `needsReview` — usually a part of speech the tagger
  doesn't map cleanly (see `POS_MAP` in `tag_vocab.py`), which needs a human
  call either way.

See `sample_input/food-cooking.json` for a worked example.
