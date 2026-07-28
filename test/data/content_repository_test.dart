import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/data/content_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = ContentRepository();

  group('loading the real bundled assets', () {
    test('loadCountries parses countries.json', () async {
      final countries = await repository.loadCountries();

      expect(countries, isNotEmpty);
      final costaRica =
          countries.firstWhere((c) => c.countryCode == 'CR');
      expect(costaRica.name, 'Costa Rica');
      expect(costaRica.active, isTrue);
    });

    test('loadSubjects parses subjects.json', () async {
      final subjects = await repository.loadSubjects();

      expect(subjects, isNotEmpty);
      expect(subjects.any((s) => s.id == 'food'), isTrue);
      expect(subjects.any((s) => s.id == 'food-cooking'), isTrue);
    });

    test('loadContent parses content/cr.json, keyed by subject id', () async {
      final content = await repository.loadContent('CR');

      expect(content.containsKey('museums'), isTrue);
      expect(content['museums'], isNotEmpty);
      expect(content['museums']!.first.phrase, isNotEmpty);
    });

    test('loadContent lowercases the country code for the file path', () async {
      final upper = await repository.loadContent('CR');
      final lower = await repository.loadContent('cr');

      expect(lower.keys, upper.keys);
    });
  });

  group('personalize', () {
    late final subjects = repository.loadSubjects();

    test('a top-level id pulls in content filed under its sub-subjects', () async {
      final result = await repository.personalize(
        countryCode: 'CR',
        allSubjects: await subjects,
        selectedTopLevelIds: {'food'},
      );

      // Placeholder content has entries under food-cooking, not under the
      // "food" parent itself or the (also childless-of-content) food-grocery.
      expect(result.containsKey('food-cooking'), isTrue);
      expect(result.containsKey('food'), isFalse);
      expect(result.containsKey('food-grocery'), isFalse);
    });

    test('a leaf id with content is included directly', () async {
      final result = await repository.personalize(
        countryCode: 'CR',
        allSubjects: await subjects,
        selectedTopLevelIds: {'museums'},
      );

      expect(result.keys, ['museums']);
    });

    test('multiple selected ids merge into one result map', () async {
      final result = await repository.personalize(
        countryCode: 'CR',
        allSubjects: await subjects,
        selectedTopLevelIds: {'museums', 'hiking'},
      );

      expect(result.keys, containsAll(['museums', 'hiking']));
    });

    test('a selected id with no matching content yields no entry for it', () async {
      final result = await repository.personalize(
        countryCode: 'CR',
        allSubjects: await subjects,
        selectedTopLevelIds: {'party'},
      );

      expect(result, isEmpty);
    });
  });
}
