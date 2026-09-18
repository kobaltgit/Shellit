import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
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
  final String? customTitle;
  final Color? colorTag;
  final bool isPinned;
  final TabType type;
  final HostEntity? host;
  final ITerminalSession? terminalSession;
  final ISftpSession? sftpSession;
  final List<ITerminalSession> splitSessions;
  final int activeSplitIndex;
  final bool isBroadcastEnabled;
  final SplitLayoutType splitLayout;

  final bool isConnecting;
  final String? connectionStatus;
  final String? connectionError;

  const SessionTab({
    required this.id,
    required this.title,
    this.customTitle,
    this.colorTag,
    this.isPinned = false,
    required this.type,
    this.host,
    this.terminalSession,
    this.sftpSession,
    this.splitSessions = const [],
    this.activeSplitIndex = 0,
    this.isBroadcastEnabled = false,
    this.splitLayout = SplitLayoutType.single,
    this.isConnecting = false,
    this.connectionStatus,
    this.connectionError,
  });

  String get displayTitle => customTitle ?? title;

  bool get isProduction => host?.isProduction ?? false;

  SessionTab copyWith({
    String? id,
    String? title,
    String? customTitle,
    bool clearCustomTitle = false,
    Color? colorTag,
    bool clearColorTag = false,
    bool? isPinned,
    TabType? type,
    HostEntity? host,
    ITerminalSession? terminalSession,
    bool clearTerminalSession = false,
    ISftpSession? sftpSession,
    bool clearSftpSession = false,
    List<ITerminalSession>? splitSessions,
    int? activeSplitIndex,
    bool? isBroadcastEnabled,
    SplitLayoutType? splitLayout,
    bool? isConnecting,
    String? connectionStatus,
    bool clearConnectionStatus = false,
    String? connectionError,
    bool clearConnectionError = false,
  }) {
    return SessionTab(
      id: id ?? this.id,
      title: title ?? this.title,
      customTitle: clearCustomTitle ? null : (customTitle ?? this.customTitle),
      colorTag: clearColorTag ? null : (colorTag ?? this.colorTag),
      isPinned: isPinned ?? this.isPinned,
      type: type ?? this.type,
      host: host ?? this.host,
      terminalSession: clearTerminalSession
          ? null
          : (terminalSession ?? this.terminalSession),
      sftpSession: clearSftpSession ? null : (sftpSession ?? this.sftpSession),
      splitSessions: splitSessions ?? this.splitSessions,
      activeSplitIndex: activeSplitIndex ?? this.activeSplitIndex,
      isBroadcastEnabled: isBroadcastEnabled ?? this.isBroadcastEnabled,
      splitLayout: splitLayout ?? this.splitLayout,
      isConnecting: isConnecting ?? this.isConnecting,
      connectionStatus: clearConnectionStatus
          ? null
          : (connectionStatus ?? this.connectionStatus),
      connectionError: clearConnectionError
          ? null
          : (connectionError ?? this.connectionError),
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

  /// Opens a terminal tab in connecting state immediately with a spinner.
  String openConnectingTerminalTab({
    required HostEntity host,
  }) {
    final seq = ++_tabCounter;
    final tabId = 'term-${DateTime.now().millisecondsSinceEpoch}-$seq';
    final tab = SessionTab(
      id: tabId,
      title: host.label,
      type: TabType.terminal,
      host: host,
      isConnecting: true,
      connectionStatus: 'Connecting...',
    );

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: () => tabId,
    );
    return tabId;
  }

  /// Updates live connection step text (e.g. 'Authenticating as root...')
  void updateTabConnectingStatus(String tabId, String status) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              isConnecting: true,
              connectionStatus: status,
              clearConnectionError: true,
            )
          else
            t,
      ],
    );
  }

  /// Attaches an established terminal session to a connecting tab.
  void attachTerminalSession({
    required String tabId,
    required ITerminalSession session,
  }) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              terminalSession: session,
              splitSessions: [session],
              isConnecting: false,
              clearConnectionStatus: true,
              clearConnectionError: true,
            )
          else
            t,
      ],
    );
  }

  /// Marks a tab as failed with a detailed error message and displays Retry/Close options.
  void setTabConnectionError({
    required String tabId,
    required String errorMessage,
  }) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              isConnecting: false,
              clearConnectionStatus: true,
              connectionError: errorMessage,
            )
          else
            t,
      ],
    );
  }

  /// Resets a tab back to connecting state (used when clicking 'Retry').
  void setTabConnecting({
    required String tabId,
    String initialStatus = 'Connecting...',
  }) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              isConnecting: true,
              connectionStatus: initialStatus,
              clearConnectionError: true,
            )
          else
            t,
      ],
    );
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

  /// Opens an SFTP tab in connecting state immediately.
  String openConnectingSftpTab({
    required HostEntity host,
  }) {
    final seq = ++_tabCounter;
    final tabId = 'sftp-${DateTime.now().millisecondsSinceEpoch}-$seq';
    final tab = SessionTab(
      id: tabId,
      title: 'SFTP: ${host.label}',
      type: TabType.sftp,
      host: host,
      isConnecting: true,
      connectionStatus: 'Opening SFTP...',
    );

    state = state.copyWith(
      tabs: [...state.tabs, tab],
      activeTabId: () => tabId,
    );
    return tabId;
  }

  /// Attaches an established SFTP session to a connecting tab.
  void attachSftpSession({
    required String tabId,
    required ISftpSession session,
  }) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              sftpSession: session,
              isConnecting: false,
              clearConnectionStatus: true,
              clearConnectionError: true,
            )
          else
            t,
      ],
    );
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
      if (s != tabToClose.terminalSession) {
        // Only terminate session if not owned as primary terminalSession by another tab
        final isOwnedByAnother = state.tabs.any(
          (other) => other.id != tabId && other.terminalSession == s,
        );
        if (!isOwnedByAnother) {
          s.terminate();
        }
      }
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
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;
    final currentTab = state.tabs[tabIndex];

    if (layout == SplitLayoutType.single) {
      state = state.copyWith(
        tabs: [
          for (final t in state.tabs)
            if (t.id == tabId)
              t.copyWith(
                type: TabType.terminal,
                splitLayout: SplitLayoutType.single,
              )
            else
              t,
        ],
      );
      return;
    }

    // Keep only current tab's existing session(s).
    // All other split slots remain empty for user drag-and-drop or manual host connection.
    final sessions = <ITerminalSession>[];
    if (currentTab.terminalSession != null) {
      sessions.add(currentTab.terminalSession!);
    }
    for (final s in currentTab.splitSessions) {
      if (!sessions.contains(s)) {
        sessions.add(s);
      }
    }

    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              type: TabType.splitTerminal,
              splitLayout: layout,
              splitSessions: sessions,
            )
          else
            t,
      ],
    );
  }

  void closeSplitPane({
    required String tabId,
    required int paneIndex,
  }) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;
    final currentTab = state.tabs[tabIndex];
    if (paneIndex < 0 || paneIndex >= currentTab.splitSessions.length) return;

    final remainingSessions =
        List<ITerminalSession>.from(currentTab.splitSessions)
          ..removeAt(paneIndex);

    if (remainingSessions.length <= 1) {
      state = state.copyWith(
        tabs: [
          for (final t in state.tabs)
            if (t.id == tabId)
              t.copyWith(
                type: TabType.terminal,
                splitLayout: SplitLayoutType.single,
                splitSessions: remainingSessions,
                terminalSession: remainingSessions.isNotEmpty
                    ? remainingSessions.first
                    : null,
              )
            else
              t,
        ],
      );
    } else {
      state = state.copyWith(
        tabs: [
          for (final t in state.tabs)
            if (t.id == tabId)
              t.copyWith(
                splitSessions: remainingSessions,
              )
            else
              t,
        ],
      );
    }
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

  void renameTab(String tabId, String? newTitle) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              customTitle:
                  newTitle?.trim().isEmpty ?? true ? null : newTitle!.trim(),
              clearCustomTitle: newTitle == null || newTitle.trim().isEmpty,
            )
          else
            t,
      ],
    );
  }

  void setTabColor(String tabId, Color? color) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId)
            t.copyWith(
              colorTag: color,
              clearColorTag: color == null,
            )
          else
            t,
      ],
    );
  }

  void togglePinTab(String tabId) {
    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId) t.copyWith(isPinned: !t.isPinned) else t,
      ],
    );
  }

  void moveTabToSplit({
    required String sourceTabId,
    required String targetTabId,
    int? targetSlotIndex,
  }) {
    if (sourceTabId == targetTabId) return;

    final sourceIndex = state.tabs.indexWhere((t) => t.id == sourceTabId);
    final targetIndex = state.tabs.indexWhere((t) => t.id == targetTabId);
    if (sourceIndex == -1 || targetIndex == -1) return;

    final sourceTab = state.tabs[sourceIndex];
    final targetTab = state.tabs[targetIndex];

    final sourceSessions = sourceTab.splitSessions.isNotEmpty
        ? sourceTab.splitSessions
        : (sourceTab.terminalSession != null
            ? [sourceTab.terminalSession!]
            : <ITerminalSession>[]);
    if (sourceSessions.isEmpty) return;

    final targetSessions = targetTab.splitSessions.isNotEmpty
        ? List<ITerminalSession>.from(targetTab.splitSessions)
        : (targetTab.terminalSession != null
            ? [targetTab.terminalSession!]
            : <ITerminalSession>[]);

    final combinedSessions = [...targetSessions, ...sourceSessions];
    final layout = targetTab.splitLayout == SplitLayoutType.single
        ? SplitLayoutType.horizontal
        : targetTab.splitLayout;

    final updatedTarget = targetTab.copyWith(
      type: TabType.splitTerminal,
      splitLayout: layout,
      splitSessions: combinedSessions,
    );

    final newTabs = [
      for (final t in state.tabs)
        if (t.id == targetTabId) updatedTarget else if (t.id != sourceTabId) t,
    ];

    state = state.copyWith(
      tabs: newTabs,
      activeTabId: () => targetTabId,
    );
  }

  void undockSplitPane({
    required String tabId,
    required int paneIndex,
    HostEntity? host,
  }) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;

    final currentTab = state.tabs[tabIndex];
    if (paneIndex < 0 || paneIndex >= currentTab.splitSessions.length) return;

    final sessionToUndock = currentTab.splitSessions[paneIndex];
    final remainingSessions =
        List<ITerminalSession>.from(currentTab.splitSessions)
          ..removeAt(paneIndex);

    final updatedCurrentTab = currentTab.copyWith(
      type: TabType.splitTerminal,
      splitSessions: remainingSessions,
      terminalSession:
          remainingSessions.isNotEmpty ? remainingSessions.first : null,
    );

    final seq = ++_tabCounter;
    final newTabId =
        'term-${DateTime.now().millisecondsSinceEpoch}-$seq-${sessionToUndock.id}';
    final undockedTab = SessionTab(
      id: newTabId,
      title: host?.label ?? currentTab.title,
      type: TabType.terminal,
      host: host ?? currentTab.host,
      terminalSession: sessionToUndock,
      splitSessions: [sessionToUndock],
    );

    final newTabs = [
      for (final t in state.tabs)
        if (t.id == tabId) updatedCurrentTab else t,
      undockedTab,
    ];

    state = state.copyWith(
      tabs: newTabs,
      activeTabId: () => tabId,
    );
  }

  void addSessionToSplit({
    required String tabId,
    required ITerminalSession session,
    int? slotIndex,
    HostEntity? host,
  }) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1) return;

    final currentTab = state.tabs[tabIndex];
    final currentSessions = currentTab.splitSessions.isNotEmpty
        ? List<ITerminalSession>.from(currentTab.splitSessions)
        : (currentTab.terminalSession != null
            ? [currentTab.terminalSession!]
            : <ITerminalSession>[]);

    if (slotIndex != null && slotIndex <= currentSessions.length) {
      currentSessions.insert(slotIndex, session);
    } else {
      currentSessions.add(session);
    }

    final updatedTab = currentTab.copyWith(
      type: TabType.splitTerminal,
      splitSessions: currentSessions,
      terminalSession: currentTab.terminalSession ?? session,
    );

    state = state.copyWith(
      tabs: [
        for (final t in state.tabs)
          if (t.id == tabId) updatedTab else t,
      ],
      activeTabId: () => tabId,
    );
  }

  void closeOtherTabs(String keepTabId) {
    final tabsToClose = state.tabs
        .where((t) => t.id != keepTabId && !t.isPinned)
        .map((t) => t.id)
        .toList();

    for (final id in tabsToClose) {
      closeTab(id);
    }
  }

  void closeTabsToTheRight(String tabId) {
    final tabIndex = state.tabs.indexWhere((t) => t.id == tabId);
    if (tabIndex == -1 || tabIndex >= state.tabs.length - 1) return;

    final tabsToClose = state.tabs
        .sublist(tabIndex + 1)
        .where((t) => !t.isPinned)
        .map((t) => t.id)
        .toList();

    for (final id in tabsToClose) {
      closeTab(id);
    }
  }

  void closeDisconnectedTabs() {
    final tabsToClose = state.tabs
        .where((t) =>
            !t.isPinned &&
            t.terminalSession?.currentState == SessionState.disconnected)
        .map((t) => t.id)
        .toList();

    for (final id in tabsToClose) {
      closeTab(id);
    }
  }

  @visibleForTesting
  void addRawTab(SessionTab tab) {
    state = state.copyWith(tabs: [...state.tabs, tab]);
  }
}

final sessionManagerProvider =
    StateNotifierProvider<SessionManagerNotifier, SessionManagerState>((ref) {
  return SessionManagerNotifier();
});
