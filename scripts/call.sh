#!/bin/bash
# Make an outbound voice call via Vapi
# Usage: ./call.sh <phone_number> <first_message> [--force]
#
# Uses unified contact system at ~/workspace/contacts/
# By default, only whitelisted contacts can be called.
#
# Required env vars:
#   VAPI_API_KEY
#   VAPI_PHONE_NUMBER_ID
#   VAPI_ASSISTANT_ID

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTACTS_DIR="$HOME/.openclaw/workspace/contacts"
CONTACTS_CHECK="$CONTACTS_DIR/check.sh"
CONTACTS_LOG="$CONTACTS_DIR/log-interaction.sh"

PHONE_NUMBER="${1:?Usage: call.sh <phone_number> <first_message> [--force]}"
FIRST_MESSAGE="${2:?Usage: call.sh <phone_number> <first_message> [--force]}"
FORCE_FLAG="${3:-}"

# Validate env vars
: "${VAPI_API_KEY:?VAPI_API_KEY is required}"
: "${VAPI_PHONE_NUMBER_ID:?VAPI_PHONE_NUMBER_ID is required}"
: "${VAPI_ASSISTANT_ID:?VAPI_ASSISTANT_ID is required}"

# Check permissions unless --force
if [ "$FORCE_FLAG" != "--force" ] && [ -x "$CONTACTS_CHECK" ]; then
  RESULT=$("$CONTACTS_CHECK" call "$PHONE_NUMBER" 2>/dev/null) || true
  STATUS="${RESULT%%:*}"
  REASON="${RESULT#*:}"
  
  case "$STATUS" in
    ALLOWED)
      echo "📞 Contact permitted"
      ;;
    ASK)
      echo "⚠️  Permission check: $REASON"
      echo "This contact requires confirmation before calling."
      echo "Use --force to proceed anyway."
      exit 2
      ;;
    BLOCKED)
      echo "🚫 Contact blocked: $REASON"
      exit 1
      ;;
    *)
      echo "⚠️  Unknown contact - whitelist mode requires explicit permission"
      echo "Use --force to proceed, or add to contacts first:"
      echo "  ~/workspace/contacts/manage.sh add \"Name\" --phone $PHONE_NUMBER"
      exit 1
      ;;
  esac
fi

if [ "$FORCE_FLAG" = "--force" ]; then
  echo "⚠️  Bypassing permission check (--force)"
fi

# Make the call
response=$(curl -s -X POST "https://api.vapi.ai/call" \
  -H "Authorization: Bearer $VAPI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"assistantId\": \"$VAPI_ASSISTANT_ID\",
    \"phoneNumberId\": \"$VAPI_PHONE_NUMBER_ID\",
    \"customer\": { \"number\": \"$PHONE_NUMBER\" },
    \"assistantOverrides\": {
      \"firstMessage\": $(echo "$FIRST_MESSAGE" | jq -Rs .)
    }
  }")

# Extract call ID and status
call_id=$(echo "$response" | jq -r '.id // empty')
status=$(echo "$response" | jq -r '.status // empty')
error=$(echo "$response" | jq -r '.error // .message // empty')

if [ -n "$call_id" ]; then
  echo "✅ Call initiated successfully"
  echo "  Call ID: $call_id"
  echo "  Status: $status"
  echo "  To: $PHONE_NUMBER"
  
  # Log interaction
  if [ -x "$CONTACTS_LOG" ]; then
    "$CONTACTS_LOG" call "$PHONE_NUMBER" >/dev/null 2>&1 || true
  fi
else
  echo "❌ Failed to initiate call"
  echo "  Error: $error"
  echo "  Response: $response"
  exit 1
fi
