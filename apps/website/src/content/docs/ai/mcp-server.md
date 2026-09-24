---
title: Native Model Context Protocol (MCP) Server
description: Connect Claude Desktop, Cursor, and Antigravity to Shellit using open protocol standards.
---

Shellit features a built-in, native **Model Context Protocol (MCP)** server compliant with Anthropic's open specification. This turns Shellit into an intelligent, auditable gateway connecting your local AI agents directly to your server infrastructure.

## Available MCP Tools

* `shellit_list_servers`: Returns the sanitized list of hosts stored in your Vault (labels, hostnames, environments, and latency tags without exposing secrets).
* `shellit_list_active_sessions`: Lists all currently open terminal tabs, active commands, and unique session IDs.
* `shellit_exec_command`: Safely executes a command in a specified active SSH terminal session.
* `shellit_get_terminal_buffer`: Reads recent lines from the terminal screen buffer for error diagnostics and log analysis.
* `shellit_read_remote_file`: Fetches file contents from a remote host using an active SFTP channel.

## MCP Gateway Management Interface

Inside Shellit's dedicated MCP Gateway panel, you can start or stop the MCP daemon, inspect live connections from agent clients (Claude Desktop, Antigravity, Cursor), enforce PROD environment safety locks, and copy client configuration snippets:

![Model Context Protocol (MCP) Gateway in Shellit](/screenshots/09_mcp_server_gateway.png)

## Connecting to Claude Desktop

Add Shellit to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "shellit": {
      "command": "node",
      "args": ["-e", "require('http').request('http://127.0.0.1:4422/message')"]
    }
  }
}
```

:::caution[Prod Guard Integration]
All commands initiated by external AI agents through MCP are strictly vetted by Shellit's **Prod Guard**. Destructive commands on production hosts will trigger an interactive confirmation dialog in the Shellit GUI, preventing unauthorized or hallucinatory destruction.
:::
