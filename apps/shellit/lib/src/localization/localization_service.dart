import 'package:core_foundation/core_foundation.dart';
import 'default_strings.dart';

/// Concrete implementation of [ILocalizationService].
/// Provides key-based translation lookup with fallback to English,
/// parameter interpolation, and dynamic language pack registration.
class AppLocalizationService implements ILocalizationService {
  String _currentLocale = 'en';
  final Map<String, Map<String, String>> _dictionaries = {};

  AppLocalizationService() {
    // Register built-in English dictionary
    _dictionaries['en'] = Map.unmodifiable(defaultEnglishStrings);
  }

  @override
  String get currentLocale => _currentLocale;

  @override
  List<String> get availableLocales => _dictionaries.keys.toList();

  @override
  Future<void> setLocale(String localeCode) async {
    if (_dictionaries.containsKey(localeCode)) {
      _currentLocale = localeCode;
    } else {
      _currentLocale = 'en';
    }
  }

  @override
  void registerLanguagePack(String localeCode, Map<String, String> strings) {
    _dictionaries[localeCode] = Map.unmodifiable(strings);
  }

  @override
  void unregisterLanguagePack(String localeCode) {
    if (localeCode == 'en') return;
    _dictionaries.remove(localeCode);
    if (_currentLocale == localeCode) {
      _currentLocale = 'en';
    }
  }

  @override
  String translate(
    String key, {
    Map<String, String>? params,
    String? defaultText,
  }) {
    // 1. Look up in active dictionary
    String? rawString = _dictionaries[_currentLocale]?[key];

    // 2. Fallback to default English dictionary if missing in active dictionary
    if (rawString == null || rawString.trim().isEmpty) {
      rawString = _dictionaries['en']?[key];
    }

    // 3. Fallback to explicit defaultText if provided
    if (rawString == null || rawString.trim().isEmpty) {
      rawString = defaultText ?? key;
    }

    // 4. Interpolate parameters if any
    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramVal) {
        rawString = rawString!.replaceAll('{$paramKey}', paramVal);
      });
    }

    return rawString!;
  }

  @override
  Map<String, String> exportTemplate() {
    return Map.unmodifiable(defaultEnglishStrings);
  }
}
