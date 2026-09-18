import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Type of session displayed inside a tab.
enum TabType {
  terminal,
  sftp,
  splitTerminal,
}

/// Layout for matrix split terminals.
enum SplitLayoutType {
  single,
  horizontal, // 2 terminals stacked horizontally (side by side)
  vertical, // 2 terminals stacked vertically (top and bottom)
  grid2x2, // 4 terminals in a 2x2 grid
}

/// Model representing an open tab in the Shellit workspace.
class SessionTab {
  final String id;
  final String title;
  final TabType type;
  final HostEntity? host;
  final ITerminalSession? terminalSession;
  final ISftpSession? sftpSession;
  final List<ITerminalSession> splitSessions;
  final int activeSplitIndex;
  final bool isBroadcastEnabled;
  final SplitLayoutType splitLayout;

  const SessionTab({
    required this.id,
    required this.title,
    required this.type,
    this.host,
    this.terminalSession,
    this.sftpSession,
    this.splitSessions = const [],
    this.activeSplitIndex = 0,
    this.isBroadcastEnabled = false,
    this.splitLayout = SplitLayoutType.single,
  });

  bool get isProduction => host?.isProduction ?? false;

  SessionTab copyWith({
    String? id,
    String? title,
    TabType? type,
    HostEntity? host,
    ITerminalSession? terminalSession,
    ISftpSession? sftpSession,
    List<ITerminalSession>? splitSessions,
    int? activeSplitIndex,
    bool? isBroadcastEnabled,
    SplitLayoutType? splitLayout,
  }) {
    return SessionTab(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      host: host ?? this.host,
      terminalSession: terminalSession ?? this.terminalSession,
      sftpSession: sftpSession ?? this.sftpSession,
      splitSessions: splitSessions ?? this.splitSessions,
      activeSplitIndex: activeSplitIndex ?? this.activeSplitIndex,
      isBroadcastEnabled: isBroadcastEnabled ?? this.isBroadcastEnabled,
      splitLayout: splitLayout ?? this.splitLayout,
    );
  }
}

/// State for active tabs and workspace.
class SessionManagerState {
  final List<SessionTab> tabs;
  final String? activeTabId;

  const SessionManagerState({
    this.tabs = const [],
    this.activeTabId,
  });

  SessionTab? get activeTab {
    if (activeTabId == null) return null;
    try {
      return tabs.firstWhere((t) => t.id == activeTabId);
    } catch (_) {
      return null;
    }
  }

  bool get isCatalogActive => activeTabId == null;

  SessionManagerState copyWith({
    List<SessionTab>? tabs,
    String? Function()? activeTabId,
  }) {
    return SessionManagerState(
      tabs: tabs ?? this.tabs,
      activeTabId: activeTabId != null ? activeTabId() : this.activeTabId,
    );
  }
}

/// State Notifier for open tabs.
class SessionManagerNotifier extends StateNotifier<SessionManagerState> {
  static int _tabCounter = 0;

  SessionManagerNotifier() : super(const SessionManagerState());

  /// Switch view to Hosts catalog/sidebar without closing open tabs.
  void showCatalog() {
    state = state.copyWith(activeTabId: () => null);
  }

  String openTerminalTab({
    required HostEntity host,
    required ITerminalSession session,
  }) {
    final seq = ++_tabCounter;
    final tabId =
        'term-${DateTime.now().millisecondsSinceEpoch}-$seq-${session.id}';
    final tab = SessionTab(
      id: tabId,
      title: host.label,
      type: TabType.terminal,
      host: host,
      terminalSession: session,
      splitSessions: [session],
    );

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: () => tabId,
    );
    return tabId;
  }

  String openSftpTab({
    required HostEntity host,
    required ISftpSession session,
  }) {
    final seq = ++_tabCounter;
    final tabId =
        'sftp-${DateTime.now().millisecondsSinceEpoch}-$seq-${session.id}';
    final tab = SessionTab(
      id: tabId,
      title: 'SFTP: ${host.label}',
      type: TabType.sftp,
      host: host,
      sftpSession: session,
    );

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: () => tabId,
    );
    return tabId;
  }

  String openSplitTab({
    required HostEntity host,
    required List<ITerminalSession> sessions,
    SplitLayoutType layout = SplitLayoutType.horizontal,
  }) {
    final seq = ++_tabCounter;
    final tabId = 'split-${DateTime.now().millisecondsSinceEpoch}-$seq';
    final tab = SessionTab(
      id: tabId,
      title: 'Split: ${host.label}',
      type: TabType.splitTerminal,
      host: host,
      splitSessions: sessions,
      terminalSession: sessions.isNotEmpty ? sessions.first : null,
      splitLayout: layout,
    );

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: () => tabId,
    );
    return tabId;
  }

  void setActiveTab(String tabId) {
    if (state.tabs.any((t) => t.id == tabId)) {
      state = state.copyWith(activeTabId: () => tabId);
    }
  }

  void closeTab(String tabId) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;

    final tabToClose = state.tabs[tabIndex];
    tabToClose.terminalSession?.terminate();
    for (final s in tabToClose.splitSessions) {
      s.terminate();
    }
    tabToClose.sftpSession?.close();

    final newTabs = state.tabs.where((t) => t.id != tabId).toList();
    String? newActiveId = state.activeTabId;

    if (state.activeTabId == tabId) {
      if (newTabs.isEmpty) {
        newActiveId = null;
      } else if (tabIndex < newTabs.length) {
        newActiveId = newTabs[tabIndex].id;
      } else {
        newActiveId = newTabs.last.id;
      }
    }

    state = state.copyWith(
      tabs: newTabs,
      activeTabId: () => newActiveId,
    );
  }

  void setSplitLayout(String tabId, SplitLayoutType layout) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId) t.copyWith(splitLayout: layout) else t,
      ],
    );
  }

  void setBroadcast(String tabId, bool enabled) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId) t.copyWith(isBroadcastEnabled: enabled) else t,
      ],
    );
  }

  void setActiveSplitIndex(String tabId, int index) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId) t.copyWith(activeSplitIndex: index) else t,
      ],
    );
  }
}

final sessionManagerProvider =
    StateNotifierProvider<SessionManagerNotifier, SessionManagerState>((ref) {
  return SessionManagerNotifier();
});
