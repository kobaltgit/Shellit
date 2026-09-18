import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_foundation/core_foundation.dart';
import 'package:terminal_ui/src/providers/session_manager_provider.dart';
import 'test_helpers.dart';

void main() {
  group('SessionManagerNotifier Tab Extensions & Split Docking Tests', () {
    late SessionManagerNotifier notifier;

    final dummyHost1 = HostEntity(
      id: 'host-1',
      label: 'Production Web',
      hostname: '192.168.1.10',
      port: 22,
      username: 'root',
      authType: HostAuthType.password,
      environment: HostEnvironment.production,
      tags: const ['web', 'frontend'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final dummyHost2 = HostEntity(
      id: 'host-2',
      label: 'Staging DB',
      hostname: '192.168.1.20',
      port: 22,
      username: 'postgres',
      authType: HostAuthType.password,
      environment: HostEnvironment.staging,
      tags: const ['db'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final dummyHost3 = HostEntity(
      id: 'host-3',
      label: 'Dev Worker',
      hostname: '192.168.1.30',
      port: 22,
      username: 'ubuntu',
      authType: HostAuthType.password,
      environment: HostEnvironment.development,
      tags: const ['worker'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      notifier = SessionManagerNotifier();
    });

    test('renameTab updates customTitle and displayTitle correctly', () {
      final tab = SessionTab(
        id: 't-1',
        title: 'Initial Title',
        type: TabType.terminal,
        host: dummyHost1,
      );
      notifier.addRawTab(tab);

      expect(notifier.state.tabs.first.displayTitle, equals('Initial Title'));

      notifier.renameTab('t-1', 'Custom Web Server');
      expect(
          notifier.state.tabs.first.customTitle, equals('Custom Web Server'));
      expect(
          notifier.state.tabs.first.displayTitle, equals('Custom Web Server'));

      // Clearing customTitle reverts to original title
      notifier.renameTab('t-1', null);
      expect(notifier.state.tabs.first.customTitle, isNull);
      expect(notifier.state.tabs.first.displayTitle, equals('Initial Title'));
    });

    test('setTabColor sets and clears color tag on tab', () {
      final tab = SessionTab(
        id: 't-1',
        title: 'Web',
        type: TabType.terminal,
        host: dummyHost1,
      );
      notifier.addRawTab(tab);

      notifier.setTabColor('t-1', Colors.purpleAccent);
      expect(notifier.state.tabs.first.colorTag, equals(Colors.purpleAccent));

      notifier.setTabColor('t-1', null);
      expect(notifier.state.tabs.first.colorTag, isNull);
    });

    test('togglePinTab pins and unpins tab', () {
      final tab = SessionTab(
        id: 't-1',
        title: 'Web',
        type: TabType.terminal,
        host: dummyHost1,
      );
      notifier.addRawTab(tab);
      expect(notifier.state.tabs.first.isPinned, isFalse);

      notifier.togglePinTab('t-1');
      expect(notifier.state.tabs.first.isPinned, isTrue);

      notifier.togglePinTab('t-1');
      expect(notifier.state.tabs.first.isPinned, isFalse);
    });

    test(
        'moveTabToSplit docks top bar tab into split pane and undock extracts it',
        () {
      final fakeSession1 = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
      final fakeSession2 = FakeTerminalSession(id: 'sess-2', hostId: 'host-2');

      final tab1 = SessionTab(
        id: 't-1',
        title: 'Tab 1',
        type: TabType.terminal,
        host: dummyHost1,
        terminalSession: fakeSession1,
        splitSessions: [fakeSession1],
      );
      final tab2 = SessionTab(
        id: 't-2',
        title: 'Tab 2',
        type: TabType.terminal,
        host: dummyHost2,
        terminalSession: fakeSession2,
        splitSessions: [fakeSession2],
      );

      notifier.addRawTab(tab1);
      notifier.addRawTab(tab2);
      expect(notifier.state.tabs.length, equals(2));

      // Drag/move tab2 into split pane of tab1
      notifier.setActiveTab('t-1');
      notifier.moveTabToSplit(sourceTabId: 't-2', targetTabId: 't-1');

      // Tab2 is removed from top-level tabs list
      expect(notifier.state.tabs.length, equals(1));
      final updatedTab1 = notifier.state.tabs.first;
      expect(updatedTab1.id, equals('t-1'));
      expect(updatedTab1.type, equals(TabType.splitTerminal));
      expect(updatedTab1.splitSessions.length, equals(2));
      expect(updatedTab1.splitSessions[0], equals(fakeSession1));
      expect(updatedTab1.splitSessions[1], equals(fakeSession2));

      // Undock slot 1 back to top-level tab
      notifier.undockSplitPane(tabId: 't-1', paneIndex: 1, host: dummyHost2);

      expect(notifier.state.tabs.length, equals(2));
      final undockedTab = notifier.state.tabs.firstWhere((t) => t.id != 't-1');
      expect(undockedTab.terminalSession, equals(fakeSession2));
      expect(notifier.state.tabs.first.splitSessions.length, equals(1));
      expect(notifier.state.tabs.first.type, equals(TabType.splitTerminal));
      expect(notifier.state.activeTabId, equals('t-1'));
    });

    test('addSessionToSplit docks new session directly into split tab', () {
      final fakeSession1 = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
      final fakeSession2 = FakeTerminalSession(id: 'sess-2', hostId: 'host-2');

      final tab1 = SessionTab(
        id: 't-1',
        title: 'Split Node',
        type: TabType.splitTerminal,
        splitLayout: SplitLayoutType.horizontal,
        host: dummyHost1,
        terminalSession: fakeSession1,
        splitSessions: [fakeSession1],
      );

      notifier.addRawTab(tab1);
      notifier.setActiveTab('t-1');

      // Add second session into slot 1
      notifier.addSessionToSplit(
        tabId: 't-1',
        session: fakeSession2,
        slotIndex: 1,
        host: dummyHost2,
      );

      final updatedTab = notifier.state.tabs.first;
      expect(updatedTab.splitSessions.length, equals(2));
      expect(updatedTab.splitSessions[0], equals(fakeSession1));
      expect(updatedTab.splitSessions[1], equals(fakeSession2));
      expect(updatedTab.type, equals(TabType.splitTerminal));
      expect(notifier.state.activeTabId, equals('t-1'));
    });

    test('closeOtherTabs closes all non-pinned tabs except target tab', () {
      final tab1 = SessionTab(
        id: 't-1',
        title: 'Pinned 1',
        type: TabType.terminal,
        host: dummyHost1,
        isPinned: true,
      );
      final tab2 = SessionTab(
        id: 't-2',
        title: 'Target 2',
        type: TabType.terminal,
        host: dummyHost2,
      );
      final tab3 = SessionTab(
        id: 't-3',
        title: 'To Close 3',
        type: TabType.terminal,
        host: dummyHost3,
      );

      notifier.addRawTab(tab1);
      notifier.addRawTab(tab2);
      notifier.addRawTab(tab3);

      expect(notifier.state.tabs.length, equals(3));

      notifier.closeOtherTabs('t-2');

      // tab1 is preserved because it's pinned, tab2 is preserved because it's target
      // tab3 is closed
      final remainingIds = notifier.state.tabs.map((t) => t.id).toList();
      expect(remainingIds, containsAll(['t-1', 't-2']));
      expect(remainingIds, isNot(contains('t-3')));
    });

    test('closeTabsToTheRight closes only unpinned tabs located to the right',
        () {
      final tab1 = SessionTab(
        id: 't-1',
        title: 'Tab 1',
        type: TabType.terminal,
        host: dummyHost1,
      );
      final tab2 = SessionTab(
        id: 't-2',
        title: 'Target 2',
        type: TabType.terminal,
        host: dummyHost2,
      );
      final tab3 = SessionTab(
        id: 't-3',
        title: 'Pinned 3 (Right)',
        type: TabType.terminal,
        host: dummyHost3,
        isPinned: true,
      );
      final tab4 = SessionTab(
        id: 't-4',
        title: 'Unpinned 4 (Right)',
        type: TabType.terminal,
        host: dummyHost1,
      );

      notifier.addRawTab(tab1);
      notifier.addRawTab(tab2);
      notifier.addRawTab(tab3);
      notifier.addRawTab(tab4);

      expect(notifier.state.tabs.length, equals(4));

      notifier.closeTabsToTheRight('t-2');

      final remainingIds = notifier.state.tabs.map((t) => t.id).toList();
      // t-1 is to the left, t-2 is target, t-3 is to the right but pinned
      // t-4 is to the right and unpinned -> closed
      expect(remainingIds, equals(['t-1', 't-2', 't-3']));
    });

    test('closeDisconnectedTabs closes only disconnected sessions', () {
      final fakeActive = FakeTerminalSession(id: 's-1', hostId: 'h-1');
      final fakeDisconnected = FakeTerminalSession(id: 's-2', hostId: 'h-2');
      fakeDisconnected.emitState(SessionState.disconnected);

      final tab1 = SessionTab(
        id: 't-1',
        title: 'Active Tab',
        type: TabType.terminal,
        host: dummyHost1,
        terminalSession: fakeActive,
      );
      final tab2 = SessionTab(
        id: 't-2',
        title: 'Disconnected Tab',
        type: TabType.terminal,
        host: dummyHost2,
        terminalSession: fakeDisconnected,
      );

      notifier.addRawTab(tab1);
      notifier.addRawTab(tab2);

      notifier.closeDisconnectedTabs();

      final remainingIds = notifier.state.tabs.map((t) => t.id).toList();
      expect(remainingIds, equals(['t-1']));
    });
  });
}
