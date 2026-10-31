#!/usr/bin/env bash
# setup-bar.sh — Integrate Celebrate mode into your Omarchy status bar
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
USER_BAR_DIR=$(find "$PLUGINS_DIR" -maxdepth 1 -type d -name "*.bar" | head -n 1)

echo "==> Setting up Celebrate integration in Omarchy Status Bar..."

if [[ -z "$USER_BAR_DIR" || ! -f "$USER_BAR_DIR/Bar.qml" ]]; then
  echo "No cloned bar found. Cloning built-in omarchy.bar..."
  omarchy plugin clone omarchy.bar
  USER_BAR_DIR=$(find "$PLUGINS_DIR" -maxdepth 1 -type d -name "*.bar" | head -n 1)
fi

echo "Found bar plugin at: $USER_BAR_DIR"

# Install CLI binary
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/../bin/celebrate" "$HOME/.local/bin/celebrate"
chmod +x "$HOME/.local/bin/celebrate"
echo "Installed CLI helper: ~/.local/bin/celebrate"

echo "Checking Bar.qml celebrate integration..."
if grep -q "zm.celebrate" "$USER_BAR_DIR/Bar.qml"; then
  echo "Bar.qml already contains celebrate integration! Skipping patch."
else
  echo "Backing up Bar.qml..."
  cp "$USER_BAR_DIR/Bar.qml" "$USER_BAR_DIR/Bar.qml.bak.$(date +%s)"
  python3 "$SCRIPT_DIR/patch-bar.py" "$USER_BAR_DIR/Bar.qml"
  echo "Bar integration patched."
fi

echo "Restarting Omarchy shell..."
omarchy restart shell

echo "==> Setup complete! You can test celebrate anytime by typing 'celebrate' in terminal."
