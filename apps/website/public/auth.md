# auth.md — Shellit Authentication & Access Model

## Overview
Shellit is a cross-platform SSH client designed with a **zero-knowledge, fail-closed, client-side only** security architecture.

## Agent Audience & Access
- **Target Audience:** Autonomous AI agents, developer tooling, and CLI automation environments interacting with Shellit.
- **Model Context Protocol (MCP):** AI agents interface with Shellit locally via stdio or authenticated local endpoints.
- **No Remote Credential Storage:** Shellit does not upload private keys, server passwords, or master keys to any remote servers or cloud endpoints.

## Authentication Methods
1. **Local Vault Master Password:** Derived using Argon2id with 64 MB memory and 3 iterations, encrypting the SQLite/SQLCipher database with AES-256-GCM.
2. **SSH Key Authentication:** Hardware tokens (FIDO2/YubiKey), ed25519, and RSA keys loaded into local PTY sessions.
3. **Prod Guard Protection:** Guardrails block high-risk commands on production servers unless explicitly unlocked by the human operator.
