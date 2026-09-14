/// A small, deliberately incomplete language-name translator — covers only
/// what this MVP branch's one country (Costa Rica, Spanish) actually
/// needs. Falls back to the English name for anything else rather than
/// guessing at a translation with no real source. Used to build the
/// Spanish side of a `FlipReveal` showing a language name (e.g.
/// `bundle.facts.officialLanguages`, which is stored in English).
String translateLanguageNameEs(String englishName) {
  const es = {'Spanish': 'Español', 'English': 'Inglés'};
  return es[englishName] ?? englishName;
}
