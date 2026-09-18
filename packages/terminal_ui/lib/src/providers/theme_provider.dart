import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../theme/terminal_color_schemes.dart';

/// Available view modes for the host catalog.
enum HostCatalogViewMode {
  grid,
  denseList,
  folderTree,
}

/// Catalog view mode provider.
final hostCatalogViewModeProvider =
    StateProvider<HostCatalogViewMode>((ref) => HostCatalogViewMode.grid);

/// Selected terminal color scheme name provider.
final terminalSchemeNameProvider =
    StateProvider<String>((ref) => 'Obsidian Dark');

/// Resolved active TerminalTheme provider.
final activeTerminalThemeProvider = Provider<TerminalTheme>((ref) {
  final name = ref.watch(terminalSchemeNameProvider);
  return TerminalColorSchemes.allSchemes[name] ??
      TerminalColorSchemes.obsidianDark;
});
