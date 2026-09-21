/// Terminal UI package for Shellit SSH Client.
/// Provides obsidian dark design system, xterm terminal renderer,
/// multi-pane SFTP manager, matrix splits, and cross-platform app shell.
library terminal_ui;

// Theme
export 'src/theme/shellit_theme.dart';
export 'src/theme/terminal_color_schemes.dart';

// Providers
export 'src/providers/vault_provider.dart';
export 'src/providers/hosts_provider.dart';
export 'src/providers/folders_provider.dart';
export 'src/providers/session_manager_provider.dart';
export 'src/providers/ping_monitor_provider.dart';
export 'src/providers/theme_provider.dart';

// App Shell Widgets
export 'src/widgets/app_shell/shellit_app_shell.dart';
export 'src/widgets/app_shell/shellit_logo.dart';
export 'src/widgets/app_shell/navigation_sidebar.dart';
export 'src/widgets/app_shell/top_bar_tabs.dart';
export 'src/widgets/app_shell/window_controls.dart';
export 'src/widgets/app_shell/window_header_bar.dart';
export 'src/widgets/app_shell/plugin_activity_rail.dart';

// Host Catalog Widgets
export 'src/widgets/hosts/host_card.dart';
export 'src/widgets/hosts/host_views_switcher.dart';
export 'src/widgets/hosts/host_context_menu.dart';
export 'src/widgets/hosts/host_form_dialog.dart';
export 'src/widgets/hosts/os_icon_badge.dart';
export 'src/widgets/hosts/os_svg_icons.dart';

// Terminal Screen, Shortcuts & Prod Guard
export 'src/widgets/terminal/terminal_screen.dart';
export 'src/widgets/terminal/terminal_connecting_view.dart';
export 'src/widgets/terminal/terminal_context_menu.dart';
export 'src/widgets/terminal/terminal_shortcuts_dialog.dart';
export 'src/widgets/terminal/prod_guard_border.dart';
export 'src/widgets/terminal/prod_confirmation_dialog.dart';
export 'src/widgets/terminal/local_terminal_button.dart';

// Local Terminal Services & Providers
export 'src/services/local_terminal_session.dart';
export 'src/services/local_shell_detector.dart';
export 'src/providers/local_terminal_provider.dart';

// SFTP Manager
export 'src/widgets/sftp/sftp_tab_view.dart';
export 'src/widgets/sftp/local_file_pane.dart';
export 'src/widgets/sftp/remote_file_pane.dart';
export 'src/widgets/sftp/transfer_queue_bar.dart';
export 'src/widgets/sftp/sftp_breadcrumbs.dart';
export 'src/widgets/sftp/sftp_dialogs.dart';
export 'src/widgets/sftp/sftp_drag_payload.dart';
export 'src/widgets/sftp/sftp_file_editor_dialog.dart';

// Matrix Splits & Broadcast
export 'src/widgets/splits/split_matrix_view.dart';
export 'src/widgets/splits/broadcast_input_bar.dart';

// Omni-Bar & Mobile
export 'src/widgets/omni_bar/omni_search_modal.dart';
export 'src/widgets/mobile/mobile_accessory_bar.dart';
export 'src/widgets/mobile/mobile_app_shell.dart';
export 'src/widgets/mobile/mobile_hosts_view.dart';
export 'src/widgets/mobile/mobile_terminal_screen.dart';

// Dialogs
export 'src/widgets/dialogs/unlock_vault_dialog.dart';

// Localization
export 'src/localization/localization_scope.dart';
