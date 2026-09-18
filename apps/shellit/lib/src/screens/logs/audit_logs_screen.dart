import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_ui/terminal_ui.dart';
import '../../controllers/log_controllers.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _cleanLogView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions &&
        _scrollController.offset < _scrollController.position.maxScrollExtent) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemState = ref.watch(systemLogsControllerProvider);

    // Trigger auto-scroll if enabled and not paused
    if (systemState.autoScroll && !systemState.isPaused) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: ShellitColors.obsidianBackground,
      appBar: AppBar(
        title: const Text(
          'Logs & Audit Center',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: ShellitColors.obsidianHeader,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ShellitColors.accentCyan,
          labelColor: ShellitColors.accentCyan,
          unselectedLabelColor: ShellitColors.textMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.dvr_outlined, size: 18), text: 'System Logs'),
            Tab(
              icon: Icon(Icons.fiber_smart_record_outlined, size: 18),
              text: 'Session Recordings',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSystemLogsTab(context, systemState),
          _buildSessionRecordingsTab(context),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: SYSTEM LOGS
  // ===========================================================================

  Widget _buildSystemLogsTab(BuildContext context, SystemLogsState state) {
    final controller = ref.read(systemLogsControllerProvider.notifier);

    return Column(
      children: [
        // Controls toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: ShellitColors.obsidianSidebar,
            border: Border(bottom: BorderSide(color: ShellitColors.border)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Search box
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: controller.setSearchQuery,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ShellitColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search message, tag or error...',
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 16,
                            color: ShellitColors.textMuted,
                          ),
                          suffixIcon: state.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 14,
                                    color: ShellitColors.textMuted,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    controller.setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 10,
                          ),
                          filled: true,
                          fillColor: ShellitColors.obsidianCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: ShellitColors.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tag dropdown
                  if (state.availableTags.isNotEmpty) ...[
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ShellitColors.obsidianCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ShellitColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: state.selectedTag,
                          dropdownColor: ShellitColors.obsidianCard,
                          hint: const Text(
                            'All Tags',
                            style: TextStyle(
                              fontSize: 12,
                              color: ShellitColors.textMuted,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ShellitColors.textPrimary,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Tags'),
                            ),
                            ...state.availableTags.map(
                              (tag) => DropdownMenuItem<String?>(
                                value: tag,
                                child: Text(tag),
                              ),
                            ),
                          ],
                          onChanged: controller.setSelectedTag,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Auto-scroll toggle
                  IconButton(
                    tooltip: state.autoScroll
                        ? 'Auto-scroll ON'
                        : 'Auto-scroll OFF',
                    icon: Icon(
                      Icons.arrow_downward,
                      size: 18,
                      color: state.autoScroll
                          ? ShellitColors.accentCyan
                          : ShellitColors.textMuted,
                    ),
                    onPressed: controller.toggleAutoScroll,
                  ),

                  // Pause/Resume toggle
                  IconButton(
                    tooltip: state.isPaused ? 'Resume Stream' : 'Pause Stream',
                    icon: Icon(
                      state.isPaused ? Icons.play_arrow : Icons.pause,
                      size: 18,
                      color: state.isPaused
                          ? ShellitColors.statusYellow
                          : ShellitColors.textSecondary,
                    ),
                    onPressed: controller.togglePause,
                  ),

                  // Copy All
                  IconButton(
                    tooltip: 'Copy Filtered Logs',
                    icon: const Icon(
                      Icons.copy,
                      size: 18,
                      color: ShellitColors.textSecondary,
                    ),
                    onPressed: () {
                      final text = controller.exportLogsText();
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logs copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // Clear buffer
                  IconButton(
                    tooltip: 'Clear In-Memory Buffer',
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      size: 18,
                      color: ShellitColors.statusRed,
                    ),
                    onPressed: controller.clear,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Level Filter Chips
              Row(
                children: [
                  _buildLevelChip(
                    null,
                    'ALL',
                    state.filterLevel == null,
                    () => controller.setFilterLevel(null),
                  ),
                  const SizedBox(width: 6),
                  _buildLevelChip(
                    LogLevel.debug,
                    'DEBUG',
                    state.filterLevel == LogLevel.debug,
                    () => controller.setFilterLevel(LogLevel.debug),
                  ),
                  const SizedBox(width: 6),
                  _buildLevelChip(
                    LogLevel.info,
                    'INFO',
                    state.filterLevel == LogLevel.info,
                    () => controller.setFilterLevel(LogLevel.info),
                  ),
                  const SizedBox(width: 6),
                  _buildLevelChip(
                    LogLevel.warning,
                    'WARN',
                    state.filterLevel == LogLevel.warning,
                    () => controller.setFilterLevel(LogLevel.warning),
                  ),
                  const SizedBox(width: 6),
                  _buildLevelChip(
                    LogLevel.error,
                    'ERROR',
                    state.filterLevel == LogLevel.error,
                    () => controller.setFilterLevel(LogLevel.error),
                  ),
                  const Spacer(),
                  Text(
                    '${state.filteredEntries.length} / ${state.allEntries.length} events',
                    style: const TextStyle(
                      fontSize: 11,
                      color: ShellitColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Log Entries List
        Expanded(
          child: state.filteredEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.terminal_outlined,
                        size: 48,
                        color: ShellitColors.borderLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.allEntries.isEmpty
                            ? 'No logs captured yet'
                            : 'No logs match current filter',
                        style: const TextStyle(
                          color: ShellitColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: state.filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = state.filteredEntries[index];
                    return _buildLogEntryRow(context, entry);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLevelChip(
    LogLevel? level,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    Color activeColor;
    switch (level) {
      case LogLevel.debug:
        activeColor = ShellitColors.textSecondary;
        break;
      case LogLevel.info:
        activeColor = ShellitColors.accentCyan;
        break;
      case LogLevel.warning:
        activeColor = ShellitColors.statusYellow;
        break;
      case LogLevel.error:
        activeColor = ShellitColors.statusRed;
        break;
      case null:
        activeColor = ShellitColors.accentBlue;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : ShellitColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? activeColor : ShellitColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildLogEntryRow(BuildContext context, LogEntry entry) {
    Color levelColor;
    switch (entry.level) {
      case LogLevel.debug:
        levelColor = ShellitColors.textMuted;
        break;
      case LogLevel.info:
        levelColor = ShellitColors.accentCyan;
        break;
      case LogLevel.warning:
        levelColor = ShellitColors.statusYellow;
        break;
      case LogLevel.error:
        levelColor = ShellitColors.statusRed;
        break;
    }

    final timeStr = entry.timestamp.toIso8601String().substring(11, 23);

    return InkWell(
      onTap: () => _showLogDetailModal(context, entry),
      hoverColor: ShellitColors.obsidianCardHover,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x1A2A2F4C))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time
            Text(
              timeStr,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: ShellitColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),

            // Level pill
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: levelColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                entry.level.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: levelColor,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ShellitColors.obsidianCard,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: ShellitColors.border),
              ),
              child: Text(
                entry.tag,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: ShellitColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Sanitized Message
            Expanded(
              child: Text(
                entry.message,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: entry.level == LogLevel.error
                      ? ShellitColors.statusRed
                      : ShellitColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (entry.error != null || entry.stackTrace != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.info_outline,
                size: 14,
                color: ShellitColors.statusYellow,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLogDetailModal(BuildContext context, LogEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ShellitColors.obsidianCard,
          title: Row(
            children: [
              Text(
                'Log Event Details [${entry.level.name.toUpperCase()}]',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 16,
                  color: ShellitColors.textSecondary,
                ),
                tooltip: 'Copy event',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: entry.toString()));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailField('Timestamp', entry.timestamp.toIso8601String()),
                  _detailField('Tag', entry.tag),
                  _detailField('Level', entry.level.name.toUpperCase()),
                  const SizedBox(height: 8),
                  const Text(
                    'Message (Sanitized):',
                    style: TextStyle(
                      fontSize: 11,
                      color: ShellitColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ShellitColors.obsidianBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ShellitColors.border),
                    ),
                    child: SelectableText(
                      entry.message,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: ShellitColors.textPrimary,
                      ),
                    ),
                  ),
                  if (entry.error != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Error:',
                      style: TextStyle(
                        fontSize: 11,
                        color: ShellitColors.statusRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ShellitColors.obsidianBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: ShellitColors.statusRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SelectableText(
                        entry.error.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: ShellitColors.statusRed,
                        ),
                      ),
                    ),
                  ],
                  if (entry.stackTrace != null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Stack Trace:',
                      style: TextStyle(
                        fontSize: 11,
                        color: ShellitColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ShellitColors.obsidianBackground,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ShellitColors.border),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          entry.stackTrace.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: ShellitColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ShellitColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: ShellitColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: SESSION RECORDINGS
  // ===========================================================================

  Widget _buildSessionRecordingsTab(BuildContext context) {
    final recState = ref.watch(sessionRecordingsControllerProvider);
    final recController = ref.read(
      sessionRecordingsControllerProvider.notifier,
    );

    if (recState.isLoading && recState.recordings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ShellitColors.accentCyan),
      );
    }

    if (recState.recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 48,
              color: ShellitColors.borderLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No recorded SSH sessions found',
              style: TextStyle(color: ShellitColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'When terminal sessions run with recording enabled, their logs appear here.',
              style: TextStyle(color: ShellitColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
              onPressed: recController.refresh,
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Left Column: Session Recordings List
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: ShellitColors.obsidianSidebar,
                  border: Border(
                    bottom: BorderSide(color: ShellitColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          onChanged: recController.setSearchQuery,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ShellitColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search session recordings...',
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 16,
                              color: ShellitColors.textMuted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            filled: true,
                            fillColor: ShellitColors.obsidianCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                color: ShellitColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: ShellitColors.textSecondary,
                      ),
                      tooltip: 'Refresh',
                      onPressed: recController.refresh,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: recState.filteredRecordings.length,
                  separatorBuilder: (context, i) =>
                      const Divider(color: ShellitColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final item = recState.filteredRecordings[index];
                    final isSelected =
                        recState.selectedRecording?.id == item.id;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: ShellitColors.obsidianCardHover,
                      leading: _buildEnvBadge(item.environment),
                      title: Text(
                        '${item.hostLabel} (${item.username})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ShellitColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${_formatDate(item.startedAt)} · ${_formatDuration(item.duration)} · ${item.commandCount} cmds · ${(item.byteSize / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ShellitColors.textMuted,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: ShellitColors.textMuted,
                        ),
                        tooltip: 'Delete recording',
                        onPressed: () =>
                            _confirmDeleteRecording(context, item.id),
                      ),
                      onTap: () => recController.selectRecording(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(color: ShellitColors.border, width: 1),

        // Right Column: Text Log Preview
        Expanded(
          flex: 6,
          child: recState.selectedRecording == null
              ? const Center(
                  child: Text(
                    'Select a session to inspect text output',
                    style: TextStyle(
                      color: ShellitColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                )
              : Container(
                  color: ShellitColors.obsidianBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preview header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: ShellitColors.obsidianHeader,
                          border: Border(
                            bottom: BorderSide(color: ShellitColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              recState.selectedRecording!.hostLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // Toggle Clean Text vs Raw VT100
                            InkWell(
                              onTap: () => setState(
                                () => _cleanLogView = !_cleanLogView,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _cleanLogView
                                      ? ShellitColors.accentCyan.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _cleanLogView
                                        ? ShellitColors.accentCyan
                                        : ShellitColors.border,
                                  ),
                                ),
                                child: Text(
                                  _cleanLogView ? 'Clean Text' : 'Raw VT100',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _cleanLogView
                                        ? ShellitColors.accentCyan
                                        : ShellitColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 16,
                                color: ShellitColors.textSecondary,
                              ),
                              tooltip: 'Copy preview text',
                              onPressed: () {
                                if (recState.activePreviewText != null) {
                                  final textToCopy = _cleanLogView
                                      ? AnsiUtils.cleanTerminalOutput(
                                          recState.activePreviewText!,
                                        )
                                      : recState.activePreviewText!;
                                  Clipboard.setData(
                                    ClipboardData(text: textToCopy),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Session log copied to clipboard',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: ShellitColors.textMuted,
                              ),
                              tooltip: 'Close preview',
                              onPressed: () =>
                                  recController.selectRecording(null),
                            ),
                          ],
                        ),
                      ),

                      // Preview body
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ShellitColors.obsidianSidebar,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: ShellitColors.border),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                recState.activePreviewText == null
                                    ? 'Loading log content...'
                                    : (_cleanLogView
                                          ? AnsiUtils.cleanTerminalOutput(
                                              recState.activePreviewText!,
                                            )
                                          : recState.activePreviewText!),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: ShellitColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEnvBadge(HostEnvironment env) {
    Color bg;
    Color text;
    String label;
    switch (env) {
      case HostEnvironment.production:
        bg = ShellitColors.envProdBg;
        text = ShellitColors.envProdText;
        label = 'PROD';
        break;
      case HostEnvironment.staging:
        bg = ShellitColors.envStageBg;
        text = ShellitColors.envStageText;
        label = 'STAGE';
        break;
      case HostEnvironment.development:
        bg = ShellitColors.envDevBg;
        text = ShellitColors.envDevText;
        label = 'DEV';
        break;
      case HostEnvironment.defaultEnv:
        bg = ShellitColors.obsidianCard;
        text = ShellitColors.textSecondary;
        label = 'DEFAULT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  void _confirmDeleteRecording(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ShellitColors.obsidianCard,
        title: const Text('Delete Recording?'),
        content: const Text(
          'This will delete the asciinema .cast and text log files from disk permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ShellitColors.statusRed,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(sessionRecordingsControllerProvider.notifier)
                  .deleteRecording(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
