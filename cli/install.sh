#!/usr/bin/env bash
# Install cs.AI CLI (`csai`) to ~/bin/csai (or /usr/local/bin with --system).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAME="csai"
DEST_DIR="${CS_AI_CLI_HOME:-$HOME/.local/share/chopsticks-ai-cli}"

mkdir -p "$DEST_DIR"
cp "$SCRIPT_DIR/csai" "$DEST_DIR/csai"
cp "$SCRIPT_DIR/csai.py" "$DEST_DIR/csai.py"
cp "$SCRIPT_DIR/csai_tui.py" "$DEST_DIR/csai_tui.py"
cp "$SCRIPT_DIR/csai_client.py" "$DEST_DIR/csai_client.py"
cp "$SCRIPT_DIR/csai_update.py" "$DEST_DIR/csai_update.py"
chmod +x "$DEST_DIR/csai" "$DEST_DIR/csai.py"

install_link() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  ln -sf "$DEST_DIR/csai" "$dest"
  echo "✅ Linked $DEST_DIR/csai → $dest"
}

if [[ "${1:-}" == "--system" ]] && [[ -w /usr/local/bin ]]; then
  install_link "/usr/local/bin/$NAME"
elif [[ "${1:-}" == "--system" ]]; then
  echo "Need write access to /usr/local/bin — run: sudo $0 --system"
  exit 1
else
  install_link "$HOME/bin/$NAME"
  PATH_LINE='export PATH="$HOME/bin:$PATH"'
  PROFILE=""
  for candidate in "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.bash_profile"; do
    if [[ -f "$candidate" ]] || [[ "$candidate" == "$HOME/.zshrc" ]]; then
      PROFILE="$candidate"
      break
    fi
  done
  if [[ -n "$PROFILE" ]]; then
    touch "$PROFILE"
    if ! grep -qF '$HOME/bin' "$PROFILE" 2>/dev/null; then
      {
        echo ""
        echo "# cs.AI CLI"
        echo "$PATH_LINE"
      } >> "$PROFILE"
      echo "✅ Added ~/bin to PATH in $PROFILE"
      echo "   Restart Terminal or run: source $PROFILE"
    fi
  elif [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo ""
    echo "Add to your shell profile:"
    echo "  $PATH_LINE"
  fi
fi

echo ""
echo "Run:  csai"
echo "      csai ask \"What is ChopsticksAI?\""
echo "      csai login"
