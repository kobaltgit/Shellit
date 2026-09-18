import 'package:flutter/foundation.dart';

/// Lightweight controller that triggers pane reload without fragile GlobalKeys.
class PaneReloadController extends ChangeNotifier {
  void reload() {
    notifyListeners();
  }
}
