#!/bin/bash
# Get transcript for a Vapi call
# Usage: ./get-transcript.sh <call_id>
#
# Required env vars:
#   VAPI_API_KEY

set -e

CALL_ID="${1:?Usage: get-transcript.sh <call_id>}"

: "${VAPI_API_KEY:?VAPI_API_KEY is required}"

response=$(curl -s -X GET "https://api.vapi.ai/call/$CALL_ID" \
  -H "Authorization: Bearer $VAPI_API_KEY")

# Check if call exists
status=$(echo "$response" | jq -r '.status // empty')
if [ -z "$status" ]; then
  echo "Call not found: $CALL_ID"
  exit 1
fi

echo "Call ID: $CALL_ID"
echo "Status: $status"
echo "Duration: $(echo "$response" | jq -r '.endedAt // "ongoing"')"
echo ""
echo "=== Transcript ==="

# Extract messages and format as conversation
echo "$response" | jq -r '.artifact.messages[]? | "\(.role): \(.message)"'
