#!/bin/bash
# install-claude-hook.sh — install a Claude-powered pre-commit hook in the current repo
set -e

echo "🔍 Checking git repository..."
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || {
  echo "❌ Not inside a git repository. cd into one and try again."
  exit 1
}
echo "✅ Git repo found at: $(git rev-parse --show-toplevel)"

if ! command -v claude &> /dev/null; then
  echo ""
  echo "📦 Claude Code not found on PATH."
  echo "⬇️  Downloading Claude Code CLI..."
  curl -fsSL https://claude.ai/install.sh | bash
  echo "🔧 Updating PATH to include ~/.local/bin..."
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v claude &> /dev/null; then
    echo "⚠️  Download completed but 'claude' still isn't on PATH."
    echo "    Open a new shell and re-run this script."
    exit 1
  fi
  echo "✅ Claude Code installed successfully: $(command -v claude)"
else
  echo "✅ Claude Code already installed: $(command -v claude)"
fi

echo ""
echo "🪝 Installing pre-commit hook..."
HOOK_PATH="$GIT_DIR/hooks/pre-commit"
mkdir -p "$(dirname "$HOOK_PATH")"

if [ -f "$HOOK_PATH" ]; then
  BACKUP="$HOOK_PATH.backup.$(date +%s)"
  echo "ℹ️  Existing hook found — backing up to $BACKUP"
  mv "$HOOK_PATH" "$BACKUP"
fi

CLAUDE_PATH=$(command -v claude 2>/dev/null || true)
echo "📝 Writing hook to $HOOK_PATH..."

cat > "$HOOK_PATH" <<HOOK
#!/bin/bash
# Claude-powered pre-commit review

# ── PATH resolution ──────────────────────────────────────────────
export PATH="\$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:\$PATH"
CLAUDE_BIN="${CLAUDE_PATH:-claude}"

if ! command -v claude &> /dev/null && [ ! -x "\$CLAUDE_BIN" ]; then
  echo "⚠️  claude CLI not found — skipping review."
  echo "    Install with: curl -fsSL https://claude.ai/install.sh | bash"
  echo "    Or bypass this hook with: git commit --no-verify"
  exit 0
fi

CLAUDE=\$(command -v claude 2>/dev/null || echo "\$CLAUDE_BIN")
# ─────────────────────────────────────────────────────────────────

echo "🤖 Running Claude Code pre-commit review..."

DIFF=\$(git diff --cached)
[ -z "\$DIFF" ] && { echo "✅ No staged changes to review."; exit 0; }

echo "🔍 Analyzing staged diff..."
REVIEW=\$(echo "\$DIFF" | "\$CLAUDE" -p "Review this staged diff for bugs, security issues, and obvious problems. If you find a CRITICAL issue, start your response with 'BLOCK:'. Otherwise summarize briefly.")

echo ""
echo "📋 Claude Code Review:"
echo "───────────────────────────────────────"
echo "\$REVIEW"
echo "───────────────────────────────────────"

if echo "\$REVIEW" | grep -q "^BLOCK:"; then
  echo ""
  echo "❌ Commit blocked by Claude review. Use --no-verify to override."
  exit 1
fi

echo ""
echo "✅ Review passed — proceeding with commit."
exit 0
HOOK

chmod +x "$HOOK_PATH"
echo "✅ Hook installed successfully at $HOOK_PATH"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  All done! Claude Code pre-commit hook is active."
echo "  • Test it:   git commit"
echo "  • Bypass it: git commit --no-verify"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
