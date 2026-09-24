#!/usr/bin/env bash
# Shellit Linux Installer Script
set -e

REPO="kobaltgit/Shellit"
INSTALL_DIR="/usr/local/bin"

echo "========================================================"
echo "          Installing Shellit for Linux                 "
echo "========================================================"

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)
    ASSET_ARCH="x86_64"
    ;;
  aarch64|arm64)
    ASSET_ARCH="arm64"
    ;;
  *)
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "Detected architecture: $ASSET_ARCH"
echo "Fetching latest release from GitHub ($REPO)..."

LATEST_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
  echo "Notice: Could not fetch release tag automatically. Using latest main release."
  LATEST_TAG="latest"
fi

echo "Installing Shellit version: $LATEST_TAG"
echo "Please visit https://github.com/$REPO/releases for direct .deb / .AppImage packages."
echo "Successfully prepared installer."
