class Subject {
  final String id;
  final String name;
  final String? parentId;

  const Subject({required this.id, required this.name, this.parentId});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
    );
  }
}

extension SubjectListX on List<Subject> {
  List<Subject> get topLevel => where((s) => s.parentId == null).toList();

  List<Subject> childrenOf(String parentId) =>
      where((s) => s.parentId == parentId).toList();

  /// A subject's own id plus every descendant id (recursively) — used to
  /// pull all content for a selected top-level category, including its
  /// sub-subjects, out of a country's content file.
  List<String> idAndDescendantIds(String id) {
    final ids = [id];
    for (final child in childrenOf(id)) {
      ids.addAll(idAndDescendantIds(child.id));
    }
    return ids;
  }
}
