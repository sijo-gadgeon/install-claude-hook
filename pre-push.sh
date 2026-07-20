#!/bin/sh
# Installs the shared pre-push hook (PHPUnit + Vitest + git-lfs) into the
# current repo's hooks directory.
#
# Usage (run from inside the repo you want to install into):
#   curl -fsSL https://raw.githubusercontent.com/<ORG>/<REPO>/main/install.sh | sh
#
# Or download and inspect first (recommended before piping to sh):
#   curl -fsSLo install.sh https://raw.githubusercontent.com/<ORG>/<REPO>/main/install.sh
#   less install.sh
#   sh install.sh

set -eu

# ---- CHANGE THIS to the raw URL of the pre-push file in your repo ----
HOOK_URL="https://raw.githubusercontent.com/sijo-gadgeon/install-claude-hook/sijo-gadgeon-patch-1/pre-push"
# ------------------------------------------------------------------------

# Must be run inside a git repo
if ! REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "❌ Not inside a git repository. cd into your repo and re-run." >&2
  exit 1
fi

# Respect core.hookspath if the repo has one configured; otherwise default
# to the standard .git/hooks directory.
HOOKS_DIR=$(git -C "$REPO_ROOT" rev-parse --git-path hooks)
CUSTOM_HOOKSPATH=$(git -C "$REPO_ROOT" config --get core.hookspath || true)
if [ -n "$CUSTOM_HOOKSPATH" ]; then
  case "$CUSTOM_HOOKSPATH" in
    /*) HOOKS_DIR="$CUSTOM_HOOKSPATH" ;;
    *)  HOOKS_DIR="$REPO_ROOT/$CUSTOM_HOOKSPATH" ;;
  esac
fi

mkdir -p "$HOOKS_DIR"
TARGET="$HOOKS_DIR/pre-push"

# Back up any existing hook instead of silently clobbering it
if [ -f "$TARGET" ]; then
  BACKUP="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
  echo "ℹ️  Existing pre-push hook found — backing up to $BACKUP"
  cp "$TARGET" "$BACKUP"
fi

echo "⬇️  Downloading pre-push hook..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$HOOK_URL" -o "$TARGET"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$HOOK_URL" -O "$TARGET"
else
  echo "❌ Neither curl nor wget is available. Install one and retry." >&2
  exit 1
fi

chmod +x "$TARGET"

echo "✅ pre-push hook installed at: $TARGET"
echo "   Hooks dir in use: $HOOKS_DIR"
echo ""
echo "It will run PHPUnit (via docker-compose) and Vitest (in pimcore-vue-unittest)"
echo "before every 'git push'. Bypass a single push with: git push --no-verify"
