import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'localization_service.dart';

export 'package:terminal_ui/terminal_ui.dart'
    show LocalizationScope, LocalizationContextExtension;

/// Singleton provider for the localization service.
final localizationServiceProvider = Provider<AppLocalizationService>((ref) {
  return AppLocalizationService();
});

/// State notifier for the list of available locale codes.
class AvailableLocalesNotifier extends StateNotifier<List<String>> {
  final AppLocalizationService _service;

  AvailableLocalesNotifier(this._service)
      : super(List<String>.unmodifiable(_service.availableLocales));

  void refresh() {
    state = List<String>.unmodifiable(_service.availableLocales);
  }

  @override
  bool updateShouldNotify(List<String> old, List<String> current) {
    if (old.length != current.length) return true;
    for (var i = 0; i < old.length; i++) {
      if (old[i] != current[i]) return true;
    }
    return false;
  }
}

/// Provider for tracking available locale codes reactively.
final availableLocalesProvider =
    StateNotifierProvider<AvailableLocalesNotifier, List<String>>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return AvailableLocalesNotifier(service);
});

/// State notifier for the currently active locale.
class ActiveLocaleNotifier extends StateNotifier<String> {
  final AppLocalizationService _service;
  final Ref? _ref;

  ActiveLocaleNotifier(this._service, [this._ref])
      : super(_service.currentLocale);

  Future<void> changeLocale(String newLocale) async {
    await _service.setLocale(newLocale);
    state = _service.currentLocale;
  }

  void registerLanguagePack(String localeCode, Map<String, String> strings) {
    _service.registerLanguagePack(localeCode, strings);
    _ref?.read(availableLocalesProvider.notifier).refresh();
  }

  void unregisterLanguagePack(String localeCode) {
    _service.unregisterLanguagePack(localeCode);
    _ref?.read(availableLocalesProvider.notifier).refresh();
    if (state == localeCode) {
      state = _service.currentLocale;
    }
  }
}

/// Provider for tracking and mutating active locale reactively.
final activeLocaleProvider =
    StateNotifierProvider<ActiveLocaleNotifier, String>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return ActiveLocaleNotifier(service, ref);
});

/// Extension on [WidgetRef] to translate strings inside Riverpod controllers.
extension LocalizationRefExtension on WidgetRef {
  String tr(
    String key, {
    Map<String, String>? params,
    String? defaultText,
  }) {
    final service = watch(localizationServiceProvider);
    watch(activeLocaleProvider); // register reactive dependency
    return service.translate(
      key,
      params: params,
      defaultText: defaultText,
    );
  }
}

