import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/widgets.dart';

/// InheritedWidget providing localization service down the widget tree.
class LocalizationScope extends InheritedWidget {
  final ILocalizationService service;
  final String locale;

  const LocalizationScope({
    super.key,
    required this.service,
    required this.locale,
    required super.child,
  });

  static LocalizationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocalizationScope>();
  }

  @override
  bool updateShouldNotify(LocalizationScope oldWidget) {
    return oldWidget.locale != locale || oldWidget.service != service;
  }
}

/// Extension on [BuildContext] to translate UI strings with zero ceremony.
extension LocalizationContextExtension on BuildContext {
  String tr(
    String key, {
    Map<String, String>? params,
    Map<String, String>? namedArgs,
    String? defaultText,
  }) {
    final effectiveParams = params ?? namedArgs;
    final scope = LocalizationScope.of(this);
    if (scope != null) {
      return scope.service.translate(
        key,
        params: effectiveParams,
        defaultText: defaultText,
      );
    }
    if (defaultText != null && effectiveParams != null) {
      var res = defaultText;
      for (final entry in effectiveParams.entries) {
        res = res.replaceAll('{${entry.key}}', entry.value);
      }
      return res;
    }
    return defaultText ?? key;
  }
}
