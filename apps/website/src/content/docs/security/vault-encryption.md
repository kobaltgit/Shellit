---
title: Cryptography & Security (Zero-Trust Architecture)
description: Deep dive into Shellit's zero-knowledge cryptography, TOFU host verification, memory hygiene, and plugin sandboxing.
---

Shellit strictly adheres to a **Zero-Knowledge** architecture: all server credentials, private SSH keys, passwords, and custom snippets are encrypted locally on your device before writing to disk.

:::caution[Status: Alpha / Developer Preview]
Shellit is currently under active alpha testing. It features an **experimental Zero-Trust architecture** undergoing continuous security auditing. The application has not yet undergone a formal external third-party cryptographic audit or certification. We transparently invite security researchers, cryptographers, and penetration testers to inspect and analyze our codebase.
:::

## 1. Local Vault Cryptographic Stack

1. **Argon2id Key Derivation Function (RFC 9106):**
   * The user's Master Password is never stored on disk or transmitted across the network.
   * On unlocking the vault, the Master Password and a unique cryptographically random 256-bit salt are processed through `Argon2id` (configured with high memory cost and iteration counts to make GPU and ASIC brute-force attacks mathematically infeasible).
2. **SQLCipher (AES-256):**
   * The Drift SQLite database is encrypted at the page level using SQLCipher.
   * Every database page carries an authenticated HMAC checksum to prevent offline ciphertext tampering.
3. **In-Memory Zeroization (Dart GC Protection):**
   * To prevent secret retention in the Dart garbage collector heap, private keys, passwords, and derived master keys are maintained as mutable `Uint8List` byte buffers.
   * Immediately upon connection completion or vault locking, sensitive buffers are explicitly zeroized (`.fillRange(0, length, 0)`) and cryptographic `SecretKey.destroy()` is executed, preventing secrets from leaking into crash dumps or swap files.

## 2. Man-in-the-Middle Defense (SSH TOFU & Known Hosts)

During SSH handshake establishment, Shellit enforces a strict **Trust On First Use (TOFU)** policy governed by the **Fail-Closed** principle:

1. **Strict Fail-Closed (Deny by Default):**
   * When connecting to a host, the remote key fingerprint is verified against the `known_hosts` table. If the host is unknown or the verification callback is unavailable, the connection is immediately aborted (`return false`).
   * Silent fail-open bypasses are strictly forbidden.
2. **Canonical OpenSSH SHA-256 Fingerprints:**
   * Raw 32-byte host key digests are formatted to standard OpenSSH notation: `SHA256:<base64-without-padding>`.
3. **Visual Randomart (Drunken Bishop):**
   * In the host key confirmation modal, the fingerprint is complemented by an ASCII art bounding box computed via the OpenSSH Drunken Bishop algorithm, enabling operators to immediately recognize unexpected key changes visually.
4. **Host Key Mismatch Alert:**
   * If a host key has changed since the previous session, Shellit halts execution with a prominent red security warning alerting to a potential Man-in-the-Middle attack.

## 3. Sandboxed Desktop Plugin SDK

Third-party plugins (`.shellit`) execute in an isolated environment with enforced boundaries:

1. **JSON-RPC 2.0 Protocol Validation:** all incoming RPC messages from plugins are verified against a strict schema and an allowed API method whitelist.
2. **Injection Defense:** strict prevention of null-bytes (`\x00`) and directory traversal sequences (`..`, `/`, `\`) in plugin storage operations.
3. **Content Security Policy (CSP):** the internal static server delivers all plugin web assets with restrictive headers: `default-src 'self'`, `frame-ancestors 'none'`, blocking unauthorized network or embedding vectors.

## Keychain & Certificate Management

In the **Primary Vault** dashboard, you can import and generate ED25519 and RSA private keys, inspect their SHA-256 fingerprints, set optional secondary passphrases, and deploy your public keys to target servers with a single click:

![SSH Keychain and Vault certificates in Shellit](/screenshots/02_keychain_vault.png)
