/// Desktop Plugin SDK for Shellit SSH Client.
/// Provides sandboxed plugin runtime, manifest validation, safe ZIP extraction with Zip Slip defense,
/// and bidirectional JSON-RPC 2.0 bridge with permission enforcement.
library desktop_plugin_sdk;

// Re-export core foundation plugin contracts
export 'package:core_foundation/core_foundation.dart'
    show
        PluginManifest,
        InstalledPlugin,
        PluginTarget,
        IPluginLoader,
        IPluginBridge,
        PluginFailure,
        PluginFailureType;

// Manifest & Permissions
export 'src/manifest/plugin_manifest_validator.dart';
export 'src/manifest/plugin_permissions.dart';

// Security & Safe extraction
export 'src/security/safe_archive_extractor.dart';

// Loader
export 'src/loader/desktop_plugin_loader.dart';
export 'src/loader/noop_plugin_loader.dart';
export 'src/loader/plugin_loader_factory.dart';
export 'src/loader/plugin_packer.dart';

// Bridge & RPC
export 'src/bridge/json_rpc_message.dart';
export 'src/bridge/desktop_plugin_bridge.dart';
export 'src/bridge/noop_plugin_bridge.dart';

// Platform
export 'src/platform/plugin_platform.dart';

// Server
export 'src/server/plugin_static_server.dart';

// Model Context Protocol (MCP)
export 'src/mcp/mcp_tool_definitions.dart';
export 'src/mcp/mcp_server_service.dart';
