import 'package:flutter_test/flutter_test.dart';

import 'package:around_the_word/models/subject.dart';

void main() {
  group('Subject.fromJson', () {
    test('parses a top-level subject (parentId omitted)', () {
      final subject = Subject.fromJson({'id': 'museums', 'name': 'Museums'});
      expect(subject.id, 'museums');
      expect(subject.name, 'Museums');
      expect(subject.parentId, isNull);
    });

    test('parses a sub-subject with a parentId', () {
      final subject = Subject.fromJson({
        'id': 'food-cooking',
        'name': 'Cooking',
        'parentId': 'food',
      });
      expect(subject.parentId, 'food');
    });
  });

  group('SubjectListX', () {
    // Two levels, matching the real subjects.json shape (Food -> Cooking).
    const twoLevel = [
      Subject(id: 'food', name: 'Food'),
      Subject(id: 'food-cooking', name: 'Cooking', parentId: 'food'),
      Subject(id: 'food-grocery', name: 'Grocery Shopping', parentId: 'food'),
      Subject(id: 'museums', name: 'Museums'),
    ];

    test('topLevel returns only subjects with no parent', () {
      final top = twoLevel.topLevel;
      expect(top.map((s) => s.id), containsAll(['food', 'museums']));
      expect(top, hasLength(2));
    });

    test('childrenOf returns direct children only', () {
      final children = twoLevel.childrenOf('food');
      expect(children.map((s) => s.id), ['food-cooking', 'food-grocery']);
    });

    test('childrenOf returns empty for a leaf subject', () {
      expect(twoLevel.childrenOf('museums'), isEmpty);
    });

    test('idAndDescendantIds for a leaf is just its own id', () {
      expect(twoLevel.idAndDescendantIds('museums'), ['museums']);
    });

    test('idAndDescendantIds for a parent includes all children', () {
      final ids = twoLevel.idAndDescendantIds('food');
      expect(ids, containsAll(['food', 'food-cooking', 'food-grocery']));
      expect(ids, hasLength(3));
    });

    test('idAndDescendantIds recurses beyond one level', () {
      // Synthetic three-level tree — real content is two levels deep today,
      // but the personalize() filter relies on this generalizing correctly.
      const threeLevel = [
        Subject(id: 'a', name: 'A'),
        Subject(id: 'a-b', name: 'A-B', parentId: 'a'),
        Subject(id: 'a-b-c', name: 'A-B-C', parentId: 'a-b'),
      ];

      final ids = threeLevel.idAndDescendantIds('a');
      expect(ids, containsAll(['a', 'a-b', 'a-b-c']));
      expect(ids, hasLength(3));
    });
  });
}
