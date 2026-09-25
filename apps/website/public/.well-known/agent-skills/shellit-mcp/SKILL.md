# Shellit Remote SSH & SFTP Management via MCP

Connect to configured SSH servers, execute safe diagnostic commands with Prod Guard protection, and read remote logs or configuration files via Shellit's native Model Context Protocol (MCP) server.

## Features
- **Fail-Closed Execution:** Remote commands are evaluated against destructive patterns before running.
- **Prod Guard:** Production servers are protected against unauthorized modification.
- **Zero-Knowledge:** Host keys and credentials remain encrypted in the local SQLCipher vault.

## Capabilities
- `shellit_list_servers`: Enumerate configured servers with latency telemetry and environment tags.
- `shellit_exec_command`: Run commands on a target host.
- `shellit_read_remote_file`: Inspect remote files and logs via SFTP.
- `shellit_get_terminal_buffer`: Retrieve real-time terminal screen buffer.
