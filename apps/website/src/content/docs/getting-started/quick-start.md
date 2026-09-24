---
title: Quick Start with Shellit
description: Initial setup, master password vault creation, and connecting to your first remote server.
---

Welcome to **Shellit** — an independent, cross-platform SSH & SFTP client engineered for developers and DevOps professionals who value privacy, control, and ergonomic efficiency.

## 1. First Launch & Vault Creation

Upon launching Shellit for the first time, you will be prompted to set a **Master Password** for your local encrypted vault:

:::tip[Zero-Knowledge Security Architecture]
Your Master Password is fed into **Argon2id** (memory-hard key derivation function) to derive the local database encryption key. The password itself is never stored in plaintext and never transmitted across the network. If you lose your master password, encrypted keys and credentials cannot be recovered.
:::

## 2. Adding Your First Remote Host

1. Click the **"New Host"** button in the top navigation bar or press `Ctrl+N` (`Cmd+N`).
2. Fill in the connection parameters:
   * **Label:** e.g., `prod-k8s-master`
   * **Host / IP:** `65.108.57.255`
   * **Port:** Default `22`
   * **Username:** `root` or your system username
   * **Authentication:** Select a private SSH key from your Vault or enter a password.
3. Select an **Environment**:
   * `PROD` — Activates **Prod Guard** destructive command protection;
   * `STAGE` — Staging / testing server;
   * `DEV` — Local development environment.

![Server catalog and live telemetry in Shellit](/screenshots/01_hero_dashboard.png)

## 3. Matrix Tiling Splits (2x2) & Broadcast Input

Inside any active terminal tab, you can split your screen into dynamic matrix panes:
* `Ctrl+Shift+D` — Split vertically;
* `Ctrl+Shift+E` — Split horizontally;
* `Ctrl+Shift+B` — Toggle **Broadcast Input** (simultaneously transmit keystrokes to all visible panels).

![2x2 Matrix tiling splits and Broadcast Input in Shellit](/screenshots/08_matrix_tiling_2x2.png)

## 4. Omni-Bar Command Palette (`Ctrl+K`)

Press `Ctrl+K` to open the Raycast-style command palette. You can instantly filter servers by label, tags, or IP address, launch saved command snippets, toggle themes, or switch split layouts completely hands-free.

## 5. Port Forwarding & SSH Tunnels

Shellit includes a visual builder for local (`-L`), remote (`-R`), and dynamic SOCKS5 (`-D`) port forwarding tunnels:

![Visual SSH Port Forwarding manager in Shellit](/screenshots/03_port_forwarding.png)
