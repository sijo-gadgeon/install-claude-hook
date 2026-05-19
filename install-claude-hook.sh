#!/bin/bash
# install-claude-hook.sh — install a Claude-powered pre-commit hook in the current repo
# Usage:   bash install-claude-hook.sh
# Or:      curl -fsSL <your-url>/install-claude-hook.sh | bash

set -e

# 1. Make sure we're inside a git repo and find its .git dir (works from subdirs too)
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || {
  echo "❌ Not inside a git repository. cd into one and try again."
  exit 1
}

# 2. Install Claude Code if it's not already on PATH
if ! command -v claude &> /dev/null; then
  echo "📦 claude CLI not found — installing..."
  curl -fsSL https://claude.ai/install.sh | bash
  # Pick up the new binary for the rest of this session
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v claude &> /dev/null; then
    echo "⚠️  Install ran but 'claude' still isn't on PATH. Open a new shell and re-run."
    exit 1
  fi
fi

# 3. Write the pre-commit hook
HOOK_PATH="$GIT_DIR/hooks/pre-commit"
mkdir -p "$(dirname "$HOOK_PATH")"

if [ -f "$HOOK_PATH" ]; then
  BACKUP="$HOOK_PATH.backup.$(date +%s)"
  echo "ℹ️  Existing hook found — backing up to $BACKUP"
  mv "$HOOK_PATH" "$BACKUP"
fi

cat > "$HOOK_PATH" <<'HOOK'
#!/bin/bash
# Claude-powered pre-commit review

if ! command -v claude &> /dev/null; then
  echo "⚠️  claude CLI not found — skipping review."
  echo "    Install with: curl -fsSL https://claude.ai/install.sh | bash"
  echo "    Or bypass this hook with: git commit --no-verify"
  exit 1
fi

DIFF=$(git diff --cached)
[ -z "$DIFF" ] && exit 0

REVIEW=$(echo "$DIFF" | claude -p "Review this staged diff for bugs, security issues, and obvious problems. If you find a CRITICAL issue, start your response with 'BLOCK:'. Otherwise summarize briefly.")

echo "$REVIEW"

if echo "$REVIEW" | grep -q "^BLOCK:"; then
  echo "❌ Commit blocked by Claude review. Use --no-verify to override."
  exit 1
fi

exit 0
HOOK

chmod +x "$HOOK_PATH"

echo "✅ Installed Claude pre-commit hook at $HOOK_PATH"
echo "   Test it with: git commit (or bypass with --no-verify)"