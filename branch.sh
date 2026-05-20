#!/bin/bash

# ─────────────────────────────────────────────
#  jira-branch.sh
#  Usage: ./jira-branch.sh <TICKET-ID> [type]
#  Example: ./jira-branch.sh DPN-118
#  Example: ./jira-branch.sh DPN-118 bugfix
# ─────────────────────────────────────────────

set -e

# ── CONFIG (loaded securely from GNOME Keyring) ─
# To store your credentials, run once:
#   secret-tool store --label="Jira URL"   jira url
#   secret-tool store --label="Jira User"  jira user
#   secret-tool store --label="Jira Token" jira token

if ! command -v secret-tool &>/dev/null; then
  echo -e "${RED}Error:${NC} secret-tool is not installed."
  echo -e "Run: ${CYAN}sudo apt install libsecret-tools${NC}"
  exit 1
fi

JIRA_BASE_URL=$(secret-tool lookup jira url 2>/dev/null)
JIRA_USER=$(secret-tool lookup jira user 2>/dev/null)
JIRA_API_TOKEN=$(secret-tool lookup jira token 2>/dev/null)

BASE_BRANCH="feature/ditto-dev10.6.9"

# ── COLORS ─────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ── VALIDATE ARGS ──────────────────────────────
TICKET_ID="${1:-}"
BRANCH_TYPE="${2:-feature}"   # default type is 'feature'

if [[ -z "$TICKET_ID" ]]; then
  echo -e "${RED}Error:${NC} No ticket ID provided."
  echo -e "Usage: ${CYAN}./jira-branch.sh <TICKET-ID> [type]${NC}"
  echo -e "Example: ${CYAN}./jira-branch.sh DPN-118 feature${NC}"
  exit 1
fi

# ── VALIDATE CONFIG ────────────────────────────
if [[ -z "$JIRA_BASE_URL" || -z "$JIRA_USER" || -z "$JIRA_API_TOKEN" ]]; then
  echo -e "${RED}Error:${NC} Missing Jira credentials in keyring."
  echo -e "Please store them using secret-tool:"
  echo -e "  ${CYAN}secret-tool store --label=\"Jira URL\"   jira url${NC}"
  echo -e "  ${CYAN}secret-tool store --label=\"Jira User\"  jira user${NC}"
  echo -e "  ${CYAN}secret-tool store --label=\"Jira Token\" jira token${NC}"
  exit 1
fi

# ── FETCH JIRA TICKET ──────────────────────────
echo -e "\n${CYAN}🔍 Fetching Jira ticket:${NC} $TICKET_ID ..."

RESPONSE=$(curl --silent --fail \
  -u "$JIRA_USER:$JIRA_API_TOKEN" \
  -H "Accept: application/json" \
  "${JIRA_BASE_URL}/rest/api/3/issue/${TICKET_ID}?fields=summary")

if [[ $? -ne 0 || -z "$RESPONSE" ]]; then
  echo -e "${RED}Error:${NC} Could not fetch ticket '$TICKET_ID'. Check your credentials and ticket ID."
  exit 1
fi

# ── PARSE TITLE ────────────────────────────────
TITLE=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['fields']['summary'])
" 2>/dev/null)

if [[ -z "$TITLE" ]]; then
  echo -e "${RED}Error:${NC} Could not parse ticket summary. Raw response:"
  echo "$RESPONSE"
  exit 1
fi

echo -e "${GREEN}✔ Ticket found:${NC} $TITLE"

# ── BUILD BRANCH NAME ──────────────────────────
# Lowercase, replace spaces/special chars with hyphens, trim leading/trailing hyphens
SLUG=$(echo "$TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]/-/g' \
  | sed 's/-\+/-/g' \
  | sed 's/^-//;s/-$//')

BRANCH_NAME="${BRANCH_TYPE}/${TICKET_ID}-${SLUG}"

echo -e "${CYAN}🌿 Branch name:${NC} $BRANCH_NAME"

# ── CONFIRM ────────────────────────────────────
read -r -p "$(echo -e "${YELLOW}Create this branch? [Y/n]:${NC} ")" CONFIRM
CONFIRM="${CONFIRM:-Y}"

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Aborted.${NC}"
  exit 0
fi

# ── GIT: FETCH & CHECKOUT BASE BRANCH ─────────
echo -e "\n${CYAN}⬇  Fetching latest from remote...${NC}"
git fetch origin

echo -e "${CYAN}🔀 Checking out base branch:${NC} $BASE_BRANCH"
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"

# ── GIT: CREATE NEW BRANCH ─────────────────────
echo -e "${CYAN}🌱 Creating branch:${NC} $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

echo -e "\n${GREEN}✅ Done! You are now on branch:${NC} $BRANCH_NAME"
echo -e "   ${YELLOW}(branched from $BASE_BRANCH)${NC}\n"
