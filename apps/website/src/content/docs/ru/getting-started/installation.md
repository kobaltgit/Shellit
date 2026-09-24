---
title: Руководство по установке
description: Способы установки Shellit на Windows, Linux и Android.
---

Shellit распространяется в виде готовых бинарных пакетов, портативных сборок и через консольные менеджеры пакетов.

:::note[Поддержка платформ]
Официально поддерживаются: **Windows 10/11**, современные дистрибутивы **Linux** (Ubuntu, Debian, Fedora, Arch) и **Android** (начиная с Android 8.0+). Сборки для macOS не распространяются.
:::

## Windows

### Вариант 1: Через консоль (Winget)

```powershell
winget install Kobalt.Shellit
```

### Вариант 2: Через Scoop

```powershell
scoop bucket add shellit https://github.com/kobaltgit/Shellit
scoop install shellit
```

### Вариант 3: Ручная загрузка

Загрузите `.msi` или портативный `.zip` из [GitHub Releases](https://github.com/kobaltgit/Shellit/releases).

---

## Linux

### Вариант 1: Быстрая установка скриптом

```bash
curl -fsSL https://shellit.dev/install.sh | bash
```

### Вариант 2: Пакет .deb (Ubuntu / Debian)

```bash
sudo dpkg -i shellit_linux_amd64.deb
```

### Вариант 3: Универсальный AppImage

```bash
chmod +x Shellit-x86_64.AppImage
./Shellit-x86_64.AppImage
```

---

## Android

Загрузите файл `shellit-release.apk` со страницы релизов и откройте его на устройстве для установки.
