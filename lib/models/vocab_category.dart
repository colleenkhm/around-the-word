/// A single vocab word or phrase shown to the learner.
class Phrase {
  final String text;

  const Phrase(this.text);
}

/// A selectable topic containing a list of phrases (e.g. "Grocery Shopping").
class Subject {
  final String name;
  final List<Phrase> phrases;

  const Subject({required this.name, required this.phrases});
}

/// A top-level category shown on the home screen (e.g. "Food").
///
/// Categories with a single subject skip straight to the phrase list;
/// categories with multiple subjects show a subject list first.
class Category {
  final String name;
  final List<Subject> subjects;

  const Category({required this.name, required this.subjects});
}
