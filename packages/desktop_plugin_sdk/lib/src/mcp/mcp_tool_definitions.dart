import 'package:meta/meta.dart';

/// Definition of an MCP tool exposed to AI assistants (Cursor, Claude, etc.).
@immutable
class McpToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  const McpToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
      };
}

/// Standard predefined MCP tools provided by Shellit.
abstract class McpStandardTools {
  /// Tool: shellit_list_servers
  static const McpToolDefinition listServers = McpToolDefinition(
    name: 'shellit_list_servers',
    description:
        'Returns the list of configured servers/hosts from Shellit vault (ID, label, hostname, port, environment, OS, latency).',
    inputSchema: {
      'type': 'object',
      'properties': <String, dynamic>{},
    },
  );

  /// Tool: shellit_list_active_sessions
  static const McpToolDefinition listActiveSessions = McpToolDefinition(
    name: 'shellit_list_active_sessions',
    description:
        'Returns the list of currently open tabs and active SSH/SFTP terminal sessions in Shellit.',
    inputSchema: {
      'type': 'object',
      'properties': <String, dynamic>{},
    },
  );

  /// Tool: shellit_exec_command
  static const McpToolDefinition execCommand = McpToolDefinition(
    name: 'shellit_exec_command',
    description:
        'Executes a shell command on a specified server or active terminal session in Shellit and returns the standard output.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'command': {
          'type': 'string',
          'description': 'The command line to execute on the server (e.g. "uptime", "docker ps").',
        },
        'serverId': {
          'type': 'string',
          'description':
              'Optional target server ID or label. If omitted, the command runs in the currently active tab.',
        },
      },
      'required': ['command'],
    },
  );

  /// Tool: shellit_get_terminal_buffer
  static const McpToolDefinition getTerminalBuffer = McpToolDefinition(
    name: 'shellit_get_terminal_buffer',
    description:
        'Retrieves recent lines of text output from an active terminal session buffer in Shellit.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'lines': {
          'type': 'integer',
          'description': 'Number of lines to retrieve from the end of the buffer (default: 50).',
          'default': 50,
        },
      },
    },
  );

  /// Tool: shellit_read_remote_file
  static const McpToolDefinition readRemoteFile = McpToolDefinition(
    name: 'shellit_read_remote_file',
    description:
        'Reads the text content of a remote file via Shellit SFTP engine (e.g. /etc/nginx/nginx.conf, logs).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'path': {
          'type': 'string',
          'description': 'Absolute path to the remote file on the server.',
        },
        'serverId': {
          'type': 'string',
          'description':
              'Optional target server ID. If omitted, uses the currently active tab.',
        },
        'maxBytes': {
          'type': 'integer',
          'description': 'Maximum number of bytes to read (default 65536 = 64KB).',
          'default': 65536,
        },
      },
      'required': ['path'],
    },
  );

  /// Returns the complete list of default MCP tools.
  static List<McpToolDefinition> get defaultTools => [
        listServers,
        listActiveSessions,
        execCommand,
        getTerminalBuffer,
        readRemoteFile,
      ];
}

/// Audit log entry representing an MCP request from an AI client.
@immutable
class McpAuditLogEntry {
  final DateTime timestamp;
  final String clientName;
  final String toolName;
  final Map<String, dynamic> arguments;
  final bool isSuccess;
  final String? resultSnippet;
  final String? errorMessage;

  const McpAuditLogEntry({
    required this.timestamp,
    required this.clientName,
    required this.toolName,
    required this.arguments,
    required this.isSuccess,
    this.resultSnippet,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'clientName': clientName,
        'toolName': toolName,
        'arguments': arguments,
        'isSuccess': isSuccess,
        'resultSnippet': resultSnippet,
        'errorMessage': errorMessage,
      };
}
