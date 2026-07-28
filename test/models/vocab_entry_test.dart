import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/vocab_entry.dart';

void main() {
  group('VocabEntry.fromJson', () {
    test('parses a fully tagged noun entry', () {
      final entry = VocabEntry.fromJson({
        'phrase': 'la sartén',
        'translation': 'the frying pan',
        'partOfSpeech': 'noun',
        'gender': 'feminine',
        'number': 'singular',
      });

      expect(entry.phrase, 'la sartén');
      expect(entry.translation, 'the frying pan');
      expect(entry.partOfSpeech, 'noun');
      expect(entry.gender, 'feminine');
      expect(entry.number, 'singular');
    });

    test('leaves gender/number null for a verb entry that omits them', () {
      final entry = VocabEntry.fromJson({
        'phrase': 'hervir',
        'translation': 'to boil',
        'partOfSpeech': 'verb',
      });

      expect(entry.partOfSpeech, 'verb');
      expect(entry.gender, isNull);
      expect(entry.number, isNull);
    });

    test('parses an untagged expression entry', () {
      final entry = VocabEntry.fromJson({
        'phrase': '¿Dónde está...?',
        'translation': 'Where is...?',
        'partOfSpeech': 'expression',
      });

      expect(entry.partOfSpeech, 'expression');
      expect(entry.gender, isNull);
      expect(entry.number, isNull);
    });

    test('tolerates an entry with no grammar tags at all', () {
      final entry = VocabEntry.fromJson({
        'phrase': 'hola',
        'translation': 'hello',
      });

      expect(entry.partOfSpeech, isNull);
    });
  });
}
