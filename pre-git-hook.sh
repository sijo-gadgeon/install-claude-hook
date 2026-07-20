#!/bin/sh
command -v git-lfs >/dev/null 2>&1 || { echo >&2 "\nThis repository is configured for Git LFS but 'git-lfs' was not found on your path. If you no longer wish to use Git LFS, remove this hook by deleting the 'pre-push' file in the hooks directory (set by 'core.hookspath'; usually '.git/hooks').\n"; exit 2; }
git lfs pre-push "$@"

REPO_ROOT=$(git rev-parse --show-toplevel)

echo "🧪 Running PHP unit tests (PHPUnit)..."
if command -v docker-compose >/dev/null 2>&1; then
  (cd "$REPO_ROOT" && docker-compose run --rm pimcore-cli vendor/bin/phpunit)
  PHP_STATUS=$?
else
  echo "⚠️  docker-compose not found — skipping PHP tests."
  PHP_STATUS=0
fi

if [ $PHP_STATUS -ne 0 ]; then
  echo "❌ PHP unit tests failed. Push aborted."
  echo "   Bypass with: git push --no-verify"
  exit 1
fi

echo "🧪 Running Vue unit tests (Vitest)..."
if [ -d "$REPO_ROOT/pimcore-vue-unittest" ]; then
  (cd "$REPO_ROOT/pimcore-vue-unittest" && npm test)
  VUE_STATUS=$?
else
  echo "⚠️  pimcore-vue-unittest directory not found — skipping Vue tests."
  VUE_STATUS=0
fi

if [ $VUE_STATUS -ne 0 ]; then
  echo "❌ Vue unit tests failed. Push aborted."
  echo "   Bypass with: git push --no-verify"
  exit 1
fi

echo "✅ All tests passed — proceeding with push."
exit 0
