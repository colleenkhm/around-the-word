import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

/// Where the user is using the language: a country and the kinds of setting
/// (urban, coastal, ...) they'll be in. Together they decide which vocab the
/// user sees, and which wording phrases that vary by country use. Both start
/// unset and are chosen on first launch. Persisted locally like the vocab
/// bank.
class LocationSettings extends ChangeNotifier {
  static const _countryKey = 'selected_country';
  static const _environmentsKey = 'selected_environments';

  String? _country;
  Set<String>? _environments;
  bool _loaded = false;
  SharedPreferences? _prefs;

  String? get country => _country;

  /// Null until the user has answered the settings question — an empty set
  /// means they answered and picked none.
  Set<String>? get environments =>
      _environments == null ? null : Set.unmodifiable(_environments!);

  Place get place => Place(_country, _environments ?? const {});

  /// False until the saved choices have been read, so the app doesn't flash
  /// the onboarding screens at someone who already answered.
  bool get loaded => _loaded;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _country = _prefs?.getString(_countryKey);
    final stored = _prefs?.getStringList(_environmentsKey);
    _environments = stored?.toSet();
    _loaded = true;
    notifyListeners();
  }

  void selectCountry(String country) {
    _country = country;
    notifyListeners();
    _prefs?.setString(_countryKey, country);
  }

  void setEnvironments(Set<String> environments) {
    _environments = Set.of(environments);
    notifyListeners();
    _prefs?.setStringList(_environmentsKey, _environments!.toList());
  }

  void toggleEnvironment(String environment) {
    final next = Set.of(_environments ?? const <String>{});
    if (!next.remove(environment)) next.add(environment);
    setEnvironments(next);
  }
}
