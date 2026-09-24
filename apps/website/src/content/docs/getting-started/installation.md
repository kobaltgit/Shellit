---
title: Installation Guide
description: Step-by-step instructions to install Shellit on Windows, Linux, and Android.
---

Shellit is distributed as precompiled native binaries, portable archives, and through system package managers.

:::note[Platform Support]
Shellit officially supports **Windows 10/11** (x64), modern **Linux** distributions (Ubuntu, Debian, Fedora, Arch via `.deb` and `AppImage`), and **Android** (8.0+ Oreo and newer via standalone `.apk`). macOS builds are not currently provided.
:::

## Windows

### Option 1: Windows Package Manager (Winget)

Run the following command in PowerShell or Windows Terminal:

```powershell
winget install Kobalt.Shellit
```

### Option 2: Scoop Package Manager

If you use Scoop for command-line tool management:

```powershell
scoop bucket add shellit https://github.com/kobaltgit/Shellit
scoop install shellit
```

### Option 3: Standalone Installer & Portable ZIP

1. Head over to the official [GitHub Releases](https://github.com/kobaltgit/Shellit/releases) page.
2. Download either `shellit-windows-x64-setup.msi` for standard system-wide installation or `shellit-windows-x64-portable.zip` for a zero-installation portable setup.
3. If using the portable ZIP, extract it to any desired folder (e.g., `D:\Tools\Shellit`) and launch `shellit.exe`.

---

## Linux

### Option 1: Automated Shell Script

Install or update Shellit with a single command:

```bash
curl -fsSL https://shellit.dev/install.sh | bash
```

### Option 2: Debian / Ubuntu Package (`.deb`)

Download the `.deb` package from GitHub Releases and install using `dpkg`:

```bash
sudo dpkg -i shellit_linux_amd64.deb
sudo apt-get install -f # Resolve any missing dependencies
```

### Option 3: Universal AppImage

For distributions without Debian packaging (Arch, Fedora, openSUSE):

```bash
chmod +x Shellit-x86_64.AppImage
./Shellit-x86_64.AppImage
```

---

## Android

Shellit for mobile provides touch-optimized SSH terminal access, full SFTP browsing, and cryptographic sync.

1. Download `shellit-release.apk` directly from [GitHub Releases](https://github.com/kobaltgit/Shellit/releases).
2. Open the `.apk` on your Android device and confirm installation.
3. Grant network permissions to enable remote host connections.
