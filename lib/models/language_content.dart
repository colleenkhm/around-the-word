/// The Language tab's dictionary layer: categories (prebuilt tree, never
/// assembled client-side), words, and phrases built from ordered tokens.
/// See around-the-word-data-architecture.md's "Curated: language content"
/// and "Client Data Objects" sections.
library;

enum TokenType { word, punctuation, particle }

TokenType _tokenTypeFromJson(String value) =>
    TokenType.values.firstWhere((e) => e.name == value);

enum Formality { formal, informal, either }

Formality _formalityFromJson(String value) =>
    Formality.values.firstWhere((e) => e.name == value);

/// A category tree node. Arrives prebuilt from the server (or, in V1, from
/// the mock bundle) — the client never assembles a hierarchy from parent
/// pointers.
class CategoryNode {
  final String id;
  final String slug;
  final String name;
  final List<CategoryNode> children;
  final int sortOrder;

  const CategoryNode({
    required this.id,
    required this.slug,
    required this.name,
    required this.children,
    required this.sortOrder,
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    return CategoryNode(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => CategoryNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      sortOrder: json['sortOrder'] as int,
    );
  }
}

extension CategoryNodeListX on List<CategoryNode> {
  CategoryNode? findById(String id) {
    for (final node in this) {
      if (node.id == id) return node;
      final found = node.children.findById(id);
      if (found != null) return found;
    }
    return null;
  }

  /// A category's own id plus every descendant id (recursively) — used to
  /// pull all content for a selected top-level category, sub-subjects
  /// included, out of a country bundle.
  List<String> idAndDescendantIds(String id) {
    final node = findById(id);
    if (node == null) return [id];
    final ids = [node.id];
    for (final child in node.children) {
      ids.addAll(idAndDescendantIds(child.id));
    }
    return ids;
  }
}

class Word {
  final String id;
  final String lemma;
  final String translation;
  final String? partOfSpeech;
  final String? gender;
  final String? pronunciation;
  final String? ipa;
  final String? audioUrl;
  final String? usageNote;
  final int? difficulty;
  final List<String> categoryIds;

  const Word({
    required this.id,
    required this.lemma,
    required this.translation,
    this.partOfSpeech,
    this.gender,
    this.pronunciation,
    this.ipa,
    this.audioUrl,
    this.usageNote,
    this.difficulty,
    required this.categoryIds,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      lemma: json['lemma'] as String,
      translation: json['translation'] as String,
      partOfSpeech: json['partOfSpeech'] as String?,
      gender: json['gender'] as String?,
      pronunciation: json['pronunciation'] as String?,
      ipa: json['ipa'] as String?,
      audioUrl: json['audioUrl'] as String?,
      usageNote: json['usageNote'] as String?,
      difficulty: json['difficulty'] as int?,
      categoryIds: (json['categoryIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class Phrase {
  final String id;
  final String categoryId;
  final String text;
  final String translation;
  final String? literalTranslation;
  final String? pronunciation;
  final String? audioUrl;
  final Formality? formality;
  final String? usageNote;
  final List<PhraseToken> tokens;

  const Phrase({
    required this.id,
    required this.categoryId,
    required this.text,
    required this.translation,
    this.literalTranslation,
    this.pronunciation,
    this.audioUrl,
    this.formality,
    this.usageNote,
    required this.tokens,
  });

  /// Convenience for exercise generation (fill-in-blank, etc.) — not used
  /// by V1's flashcard-only UI yet, kept for when those exercises land.
  List<PhraseToken> get maskable => tokens.where((t) => t.isMaskable).toList();

  factory Phrase.fromJson(Map<String, dynamic> json) {
    return Phrase(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      text: json['text'] as String,
      translation: json['translation'] as String,
      literalTranslation: json['literalTranslation'] as String?,
      pronunciation: json['pronunciation'] as String?,
      audioUrl: json['audioUrl'] as String?,
      formality: json['formality'] == null
          ? null
          : _formalityFromJson(json['formality'] as String),
      usageNote: json['usageNote'] as String?,
      tokens: (json['tokens'] as List<dynamic>? ?? [])
          .map((e) => PhraseToken.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PhraseToken {
  final int position;
  final String surfaceForm;
  final String? wordId;
  final bool isMaskable;
  final TokenType type;

  const PhraseToken({
    required this.position,
    required this.surfaceForm,
    this.wordId,
    required this.isMaskable,
    required this.type,
  });

  factory PhraseToken.fromJson(Map<String, dynamic> json) {
    return PhraseToken(
      position: json['position'] as int,
      surfaceForm: json['surfaceForm'] as String,
      wordId: json['wordId'] as String?,
      isMaskable: json['isMaskable'] as bool,
      type: _tokenTypeFromJson(json['type'] as String),
    );
  }
}
