"""
Auto-tags vocab entries with part of speech, gender, and grammatical number.

This is a content-authoring tool, not part of the Flutter app. Run it once
per batch of new vocab, review its output, then hand-merge the result into
the app's assets/data/content/{countryCode}.json.

Usage:
    python tag_vocab.py input.json --lang es > output.json

Input JSON: a list of entries, each either
    {"phrase": "la sartén", "translation": "the frying pan"}
or, for multi-word chunks that shouldn't be grammatically decomposed:
    {"phrase": "¿Dónde está...?", "translation": "Where is...?", "isExpression": true}

Output JSON: the same entries, enriched with "partOfSpeech" and (for nouns/
adjectives) "gender" and "number". Entries the tagger couldn't confidently
handle get "needsReview": true instead of guessed tags — check those by hand.
"""

import argparse
import json
import sys

import spacy

MODELS = {
    "es": "es_core_news_sm",
    "fr": "fr_core_news_sm",
}

POS_MAP = {
    "NOUN": "noun",
    "PROPN": "noun",
    "VERB": "verb",
    "AUX": "verb",
    "ADJ": "adjective",
    "ADV": "adverb",
}

GENDER_MAP = {"Fem": "feminine", "Masc": "masculine"}
NUMBER_MAP = {"Sing": "singular", "Plur": "plural"}


def head_token(doc):
    for token in doc:
        if token.dep_ == "ROOT":
            return token
    return doc[-1] if len(doc) else None


def tag_entry(nlp, entry):
    if entry.get("isExpression"):
        return {**entry, "partOfSpeech": "expression"}

    doc = nlp(entry["phrase"])
    token = head_token(doc)
    if token is None:
        return {**entry, "needsReview": True}

    pos = POS_MAP.get(token.pos_)
    if pos is None:
        return {**entry, "needsReview": True, "spacyPos": token.pos_}

    tagged = {**entry, "partOfSpeech": pos}

    if pos in ("noun", "adjective"):
        genders = token.morph.get("Gender")
        numbers = token.morph.get("Number")
        if genders:
            tagged["gender"] = GENDER_MAP.get(genders[0], genders[0])
        if numbers:
            # Grammatical form only — "mass" (uncountable) vs. "singular"
            # is a semantic call spaCy can't make; confirm/override by hand.
            tagged["number"] = NUMBER_MAP.get(numbers[0], numbers[0])
        if "gender" not in tagged or "number" not in tagged:
            tagged["needsReview"] = True

    return tagged


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="Path to input JSON (list of vocab entries)")
    parser.add_argument("--lang", choices=MODELS, default="es")
    args = parser.parse_args()

    with open(args.input, encoding="utf-8") as f:
        entries = json.load(f)

    try:
        nlp = spacy.load(MODELS[args.lang])
    except OSError:
        print(
            f"Model {MODELS[args.lang]!r} not found. Install it with:\n"
            f"  python -m spacy download {MODELS[args.lang]}",
            file=sys.stderr,
        )
        sys.exit(1)

    tagged = [tag_entry(nlp, entry) for entry in entries]

    review_count = sum(1 for e in tagged if e.get("needsReview"))
    if review_count:
        print(f"{review_count} entr{'y' if review_count == 1 else 'ies'} flagged for manual review", file=sys.stderr)

    json.dump(tagged, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
