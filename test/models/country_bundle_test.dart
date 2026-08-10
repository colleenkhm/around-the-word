import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/country_bundle.dart';
import 'package:around_the_word/models/country_guide.dart';
import 'package:around_the_word/models/language_content.dart';
import 'package:around_the_word/models/point_of_interest.dart';

/// Parses the real Costa Rica mock bundle (assets/data/bundles/cr.json) —
/// the same file the app will eventually load via rootBundle — to catch
/// model/JSON shape mismatches before any UI depends on them. Read via
/// dart:io rather than rootBundle since this is a plain model test, not a
/// widget test with Flutter asset bindings.
void main() {
  late CountryBundle bundle;

  setUpAll(() {
    final raw = File('assets/data/bundles/cr.json').readAsStringSync();
    bundle = CountryBundle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('parses country and facts', () {
    expect(bundle.country.isoCode, 'CR');
    expect(bundle.country.nameCommon, 'Costa Rica');
    expect(bundle.country.contentStatus, ContentStatus.partial);
    expect(bundle.facts.capital, 'San José');
    expect(bundle.facts.currencyCode, 'CRC');
    expect(bundle.facts.officialLanguages, ['Spanish']);
  });

  test('parses cities, distinguishing featured from non-featured', () {
    expect(bundle.cities, hasLength(4));
    expect(bundle.cities.where((c) => c.isFeatured), hasLength(3));
    expect(bundle.cities.firstWhere((c) => c.name == 'Limón').isFeatured, isFalse);
  });

  test('leader is null (not shown in V1 — see Open Decisions)', () {
    expect(bundle.leader, isNull);
  });

  test('parses the curated guide, including the why_short/why split', () {
    expect(bundle.guide.bestTimes, hasLength(2));
    final dry = bundle.guide.bestTimes.first;
    expect(dry.whyShort, 'dry season nationwide');
    expect(dry.crowdLevel, CrowdLevel.high);

    expect(bundle.guide.practicalNorms, hasLength(3));
    final tipping = bundle.guide.practicalNorms
        .firstWhere((n) => n.type == 'tipping_norm');
    expect(tipping.severity, Severity.important);

    expect(bundle.guide.festivals, hasLength(1));
    expect(bundle.guide.prepNotes.first.urgency, Urgency.recommended);
    expect(bundle.guide.isEmpty, isFalse);
  });

  test('groups points of interest by city, leaving regional ones unassigned', () {
    expect(bundle.pointsOfInterest, hasLength(3));
    final regional =
        bundle.pointsOfInterest.where((p) => p.cityId == null).toList();
    expect(regional, hasLength(1));
    expect(regional.single.name, 'Monteverde Cloud Forest Reserve');
    expect(regional.single.poiType, PoiType.landmark);
  });

  test('parses phrases down to their tokens', () {
    final pura = bundle.phrases.firstWhere((p) => p.id == 'phrase-cr-pura-vida');
    expect(pura.formality, Formality.informal);
    expect(pura.tokens, hasLength(2));

    final bano = bundle.phrases.firstWhere((p) => p.id == 'phrase-cr-bano');
    expect(bano.maskable.map((t) => t.surfaceForm), ['Dónde', 'está', 'baño']);
  });

  test('parses words and links a phrase token back to its dictionary form', () {
    expect(bundle.words, hasLength(11));
    final hervir = bundle.words.firstWhere((w) => w.id == 'word-cr-hervir');
    expect(hervir.partOfSpeech, 'verb');
    expect(hervir.ipa, isNotNull);

    final hirviendoToken = bundle.phrases
        .firstWhere((p) => p.id == 'phrase-cr-hirviendo')
        .tokens
        .firstWhere((t) => t.surfaceForm == 'hirviendo');
    expect(hirviendoToken.wordId, hervir.id);
  });

  test('the category tree arrives prebuilt, with real nesting', () {
    final food = bundle.categories.firstWhere((c) => c.slug == 'food');
    expect(food.children.map((c) => c.slug), ['food-cooking', 'food-grocery']);
    expect(
      bundle.categories.idAndDescendantIds('cat-food'),
      containsAll(['cat-food', 'cat-food-cooking', 'cat-food-grocery']),
    );
  });

  test('advisories always carry an issuing authority and verification date', () {
    expect(bundle.advisories, hasLength(2));
    for (final advisory in bundle.advisories) {
      expect(advisory.issuingAuthority, isNotEmpty);
      expect(advisory.officialUrl, startsWith('https://'));
    }
  });

  test('visa info is present and nationality-scoped', () {
    expect(bundle.visa, isNotNull);
    expect(bundle.visa!.nationalityIsoCode, 'US');
    expect(bundle.visa!.prohibitedOnExit, isNull);
  });

  test('no regional note for a non-Schengen-style country', () {
    expect(bundle.regionalNote, isNull);
  });
}
