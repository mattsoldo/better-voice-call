#!/bin/bash
# List recent Vapi calls
# Usage: ./list-calls.sh [limit]
#
# Required env vars:
#   VAPI_API_KEY

set -e

LIMIT="${1:-10}"

: "${VAPI_API_KEY:?VAPI_API_KEY is required}"

response=$(curl -s -X GET "https://api.vapi.ai/call?limit=$LIMIT" \
  -H "Authorization: Bearer $VAPI_API_KEY")

echo "$response" | jq -r '.[] | "\(.id)\t\(.status)\t\(.startedAt // "pending")\t\(.endedReason // "-")"' | \
  column -t -s $'\t' -N "ID,STATUS,STARTED,ENDED_REASON"
