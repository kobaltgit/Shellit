/// Contract for managing application localizations, language packs from plugins, and string translations.
abstract class ILocalizationService {
  /// Translates a given [key] into the current active language.
  ///
  /// If the key is not found in the current locale dictionary, falls back to the default
  /// English dictionary, and then to [defaultText] if provided.
  /// If [params] are provided, replaces `{paramName}` in the string with its corresponding value.
  String translate(
    String key, {
    Map<String, String>? params,
    String? defaultText,
  });

  /// Switches the active locale (e.g., 'en', 'ru_RU').
  Future<void> setLocale(String localeCode);

  /// The currently active locale code (e.g., 'en').
  String get currentLocale;

  /// List of available locale codes, including built-in and loaded plugins.
  List<String> get availableLocales;

  /// Registers or updates a dictionary for a specific locale (typically loaded from a plugin).
  void registerLanguagePack(String localeCode, Map<String, String> strings);

  /// Unregisters a dictionary for a specific locale (e.g. when a language plugin is uninstalled or disabled).
  void unregisterLanguagePack(String localeCode);

  /// Exports the complete dictionary of default English strings and keys for plugin authors.
  Map<String, String> exportTemplate();
}
