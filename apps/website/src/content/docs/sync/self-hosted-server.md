---
title: Self-Hosted E2EE Sync Server
description: Architectural overview, protocol details, and security principles of Shellit's sync engine.
---

Shellit ships with an autonomous, open-source synchronization server (`servers/sync_server`), engineered to run reliably on any host machine — from a minimal Raspberry Pi or home NAS to enterprise cloud servers.

## Core Architectural Principles

* **Zero-Knowledge E2EE (End-to-End Encryption):** Every host record, key association, and snippet is encrypted locally using authenticated ciphers (`AES-256-GCM` or `XChaCha20-Poly1305`) before dispatch. The sync server acts as a blind relay storing opaque binary packages (`nonce + tag + ciphertext`). The server operator has zero mathematical means to view your server addresses, private credentials, or shell commands.
* **Minimal Resource Footprint:** Compiled into native AOT Dart binary, the server uses a mere 15–25 MB of RAM even under multi-device sync loads.
* **Embedded SQLite Storage:** Employs an embedded SQLite database configured in WAL (Write-Ahead Logging) mode, eliminating dependencies on external database servers like PostgreSQL or Redis.
* **Real-Time WebSocket Bus:** Maintains persistent WebSocket connections with active client apps to broadcast real-time sync revision notices (`sync:revision_pushed`), triggering immediate delta reconciliation across all your workstations and mobile phones.

## System Architecture Diagram

```text
+-----------------------+              +-----------------------+
|  Shellit Desktop      |              |  Shellit Mobile       |
|  (Local Vault DB)     |              |  (Local Vault DB)     |
+-----------+-----------+              +-----------+-----------+
            |                                      |
       (Encrypted)                            (Encrypted)
            |       +----------------------+       |
            +------>| Shellit Sync Server  |<------+
                    | (Zero-Knowledge Relay|
                    |  SQLite + WebSockets)|
                    +----------------------+
```

## Environment Configuration

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `PORT` | `8080` | TCP port for HTTP and WebSocket listeners |
| `BIND_ADDRESS` | `0.0.0.0` | Network binding interface |
| `DATA_PATH` | `/data/shellit-sync.db` | Local file path for the SQLite database |
| `REGISTRATION_TOKEN` | *(empty)* | Shared secret required to register new client devices. Prevents unauthorized relays |
| `MAX_PAYLOAD_MB` | `50` | Maximum allowed sync payload size in MB |

## Replication Protocol

1. **Device Registration (`POST /api/v1/auth/register`):** Client passes its public device UUID and optional registration token. Server issues a scoped JWT.
2. **Head State Check (`GET /api/v1/sync/head`):** Client verifies latest revision hash on the relay.
3. **Encrypted Push (`POST /api/v1/sync/push`):** Uploads encrypted delta changes and increments revision counter.
4. **Encrypted Pull (`GET /api/v1/sync/pull?since={rev}`):** Downloads missed revision blobs for local CRDT conflict resolution.
5. **WebSocket Push (`WS /api/v1/sync/ws`):** Instant trigger notifies all online client devices of available updates.
