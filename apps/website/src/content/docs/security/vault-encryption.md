---
title: Vault Encryption (Argon2id + AES-256)
description: Deep dive into Shellit's zero-knowledge cryptography, key derivation, and memory safety.
---

Shellit strictly adheres to a **Zero-Knowledge** architecture: all server credentials, private SSH keys, passwords, and custom snippets are encrypted locally on your device before writing to disk.

## Cryptographic Architecture

1. **Argon2id Key Derivation Function (KDF):**
   * The user's Master Password is never saved to disk or transmitted over the wire.
   * On unlocking the application, the Master Password and a unique cryptographically random 256-bit salt are processed through `Argon2id` (configured with high memory cost and iteration count to make GPU and ASIC brute-force attacks infeasible).
2. **SQLCipher (AES-256-GCM / CBC with HMAC-SHA512):**
   * The Drift SQLite database is encrypted at the page level using SQLCipher.
   * Every database page carries an HMAC checksum to prevent offline ciphertext tampering.
3. **In-Memory Zeroization:**
   * Whenever an SSH connection closes or the application auto-locks, decrypted key bytes stored in `Uint8List` are immediately overwritten with zeros (`buffer.fillRange(0, buffer.length, 0)`), preventing sensitive material from leaking into memory crash dumps or swap files.

## Keychain & Certificate Management

In the **Primary Vault** dashboard, you can import and generate ED25519 and RSA private keys, inspect their SHA-256 fingerprints, set optional secondary passphrases, and deploy your public keys to target servers with a single click:

![SSH Keychain and Vault certificates in Shellit](/screenshots/02_keychain_vault.png)
