import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:terminal_ui/src/widgets/app_shell/tab_drag_payload.dart';
import 'package:terminal_ui/src/widgets/app_shell/tab_overflow_menu.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyHost1 = HostEntity(
    id: 'host-1',
    label: 'Prod Server',
    hostname: '10.0.0.1',
    username: 'admin',
    authType: HostAuthType.password,
    environment: HostEnvironment.production,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final dummyHost2 = HostEntity(
    id: 'host-2',
    label: 'Dev Server',
    hostname: '10.0.0.2',
    username: 'dev',
    authType: HostAuthType.password,
    environment: HostEnvironment.development,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('TopBarTabs and Tab Drag & Drop Tests', () {
    testWidgets('TopBarTabs renders tabs with pin, color tag, and custom title',
        (tester) async {
      final container = ProviderContainer();
      final notifier = container.read(sessionManagerProvider.notifier);

      final tab1 = SessionTab(
        id: 't-1',
        title: 'Server 1',
        customTitle: 'My Custom Prod',
        colorTag: Colors.redAccent,
        isPinned: true,
        type: TabType.terminal,
        host: dummyHost1,
      );
      final tab2 = SessionTab(
        id: 't-2',
        title: 'Server 2',
        type: TabType.terminal,
        host: dummyHost2,
      );
      final tab3 = SessionTab(
        id: 't-3',
        title: 'Server 3',
        type: TabType.terminal,
        host: dummyHost2,
      );

      notifier.addRawTab(tab1);
      notifier.addRawTab(tab2);
      notifier.addRawTab(tab3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: const Scaffold(
              body: TopBarTabs(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify custom title is displayed
      expect(find.text('My Custom Prod'), findsOneWidget);
      // Verify pin icon is rendered for tab1
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      // Verify overflow button is present because there are 3 tabs (> 2)
      expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Secondary tap on tab item opens TabContextMenu popup menu',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      final notifier = container.read(sessionManagerProvider.notifier);

      final tab1 = SessionTab(
        id: 't-1',
        title: 'Web Server',
        type: TabType.terminal,
        host: dummyHost1,
      );

      notifier.addRawTab(tab1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: TopBarTabs(
                onDuplicateTab: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabFinder = find.text('Web Server');
      expect(tabFinder, findsOneWidget);

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.down(tester.getCenter(tabFinder));
      await gesture.up();
      await tester.pumpAndSettle();

      // Expect popup menu entries from TabContextMenu
      expect(find.text('Duplicate Session'), findsOneWidget);
      expect(find.text('Rename Tab...'), findsOneWidget);
      expect(find.text('Set Color Tag...'), findsOneWidget);
      expect(find.text('Pin Tab'), findsOneWidget);
      expect(find.text('Close Tab'), findsOneWidget);
    });

    testWidgets('Tab Overflow button opens TabOverflowMenuDialog with search',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      final notifier = container.read(sessionManagerProvider.notifier);

      final tab1 = SessionTab(
        id: 't-1',
        title: 'Alpha Node',
        type: TabType.terminal,
        host: dummyHost1,
      );
      final tab2 = SessionTab(
        id: 't-2',
        title: 'Beta Node',
        type: TabType.terminal,
        host: dummyHost2,
      );
      final tab3 = SessionTab(
        id: 't-3',
        title: 'Gamma Node',
        type: TabType.terminal,
        host: dummyHost2,
      );

      notifier.addRawTab(tab1);
      notifier.addRawTab(tab2);
      notifier.addRawTab(tab3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: const Scaffold(
              body: TopBarTabs(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap overflow button
      final overflowFinder = find.byIcon(Icons.layers_outlined);
      expect(overflowFinder, findsOneWidget);
      await tester.tap(overflowFinder);
      await tester.pumpAndSettle();

      // Dialog should be displayed with search field and tab items
      expect(find.byType(TabOverflowMenu), findsOneWidget);
      expect(find.text('Search open tabs...'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TabOverflowMenu),
          matching: find.text('Alpha Node'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TabOverflowMenu),
          matching: find.text('Beta Node'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TabOverflowMenu),
          matching: find.text('Gamma Node'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'SplitMatrixView empty slot accepts DragTarget<TabDragPayload> drop',
        (tester) async {
      final fakeSession1 = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
      TabDragPayload? droppedPayload;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SplitMatrixView(
                sessions: [fakeSession1],
                initialLayout: SplitLayoutType.horizontal,
                onDropTab: (payload) {
                  droppedPayload = payload;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slot 0 has session1, Slot 1 is empty pane with DragTarget
      expect(find.text('Empty Split Slot'), findsOneWidget);
      expect(
          find.text('Drag an open tab here or select a host'), findsOneWidget);

      final dragTargetFinder = find.byType(DragTarget<TabDragPayload>);
      expect(dragTargetFinder, findsOneWidget);

      // Simulate dragging and dropping TabDragPayload
      final dragPayload = TabDragPayload(
        tabId: 't-dropped',
        host: dummyHost2,
        title: 'Dropped Server',
        type: TabType.terminal,
      );

      final dragTargetWidget =
          tester.widget<DragTarget<TabDragPayload>>(dragTargetFinder);
      final details = DragTargetDetails<TabDragPayload>(
        data: dragPayload,
        offset: Offset.zero,
      );
      dragTargetWidget.onAcceptWithDetails?.call(details);

      expect(droppedPayload?.tabId, equals('t-dropped'));
    });

    testWidgets(
        'SplitMatrixView slot header undock button triggers onUndockPane',
        (tester) async {
      final fakeSession1 = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
      final fakeSession2 = FakeTerminalSession(id: 'sess-2', hostId: 'host-2');
      int? undockedSlot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SplitMatrixView(
                sessions: [fakeSession1, fakeSession2],
                initialLayout: SplitLayoutType.horizontal,
                onUndockPane: (slot) {
                  undockedSlot = slot;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In multi-pane layout, each pane with a session has an undock button
      final undockButtons =
          find.byTooltip('Extract / Undock to standalone tab');
      expect(undockButtons, findsNWidgets(2));

      await tester.tap(undockButtons.last);
      await tester.pumpAndSettle();

      expect(undockedSlot, equals(1));
    });

    testWidgets(
        'SplitMatrixView empty slot button opens HostSlotPickerDialog and calls onConnectHostToSlot',
        (tester) async {
      final fakeSession1 = FakeTerminalSession(id: 'sess-1', hostId: 'host-1');
      int? targetSlot;
      HostEntity? connectedHost;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ShellitTheme.obsidianDarkTheme,
            home: Scaffold(
              body: SplitMatrixView(
                sessions: [fakeSession1],
                hosts: [dummyHost1, dummyHost2],
                initialLayout: SplitLayoutType.horizontal,
                onConnectHostToSlot: (slot, host) {
                  targetSlot = slot;
                  connectedHost = host;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slot 1 is empty in horizontal split (1 session out of 2 slots)
      final connectBtn = find.text('Connect Host to this Pane');
      expect(connectBtn, findsOneWidget);

      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // Dialog should appear with hosts
      expect(find.text('Connect Host to Split Pane 2'), findsOneWidget);
      expect(find.text('Dev Server'), findsOneWidget);

      // Tap on Dev Server
      await tester.tap(find.text('Dev Server'));
      await tester.pumpAndSettle();

      // Callback should have received slot 1 and dummyHost2
      expect(targetSlot, equals(1));
      expect(connectedHost?.id, equals('host-2'));
    });
  });
}
