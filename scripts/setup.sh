#!/bin/bash
# Setup Vapi assistant for OpenClaw voice calls
# Usage: ./setup.sh
#
# This script creates a new Vapi assistant configured for OpenClaw.
# Run once during initial setup.
#
# Required env vars:
#   VAPI_API_KEY
#
# Optional env vars:
#   VAPI_WEBHOOK_URL - Server URL for tool calls (defaults to none)
#   VAPI_VOICE_ID - ElevenLabs voice ID (defaults to built-in)

set -e

: "${VAPI_API_KEY:?VAPI_API_KEY is required}"

WEBHOOK_URL="${VAPI_WEBHOOK_URL:-}"
VOICE_ID="${VAPI_VOICE_ID:-}"

# System prompt for the assistant
SYSTEM_PROMPT='You are Helix, an AI assistant calling on behalf of your human. You are helpful, concise, and conversational.

Your role on this call:
1. Deliver the urgent message or question
2. Listen to the response
3. Take action if requested (check calendar, send messages, etc.)
4. Confirm any actions taken
5. End the call politely when done

Guidelines:
- Be conversational and natural, not robotic
- Keep responses concise - this is a phone call, not a lecture
- If asked to do something, confirm before acting
- If you cannot do something, say so clearly
- Do not make up information

You have access to tools for: checking calendar, sending messages, reading emails, and other actions available through OpenClaw.'

# Create assistant
response=$(curl -s -X POST "https://api.vapi.ai/assistant" \
  -H "Authorization: Bearer $VAPI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"OpenClaw Voice Assistant\",
    \"model\": {
      \"provider\": \"anthropic\",
      \"model\": \"claude-sonnet-4-20250514\",
      \"temperature\": 0.7,
      \"messages\": [
        {
          \"role\": \"system\",
          \"content\": $(echo "$SYSTEM_PROMPT" | jq -Rs .)
        }
      ]
    },
    \"voice\": {
      \"provider\": \"11labs\",
      \"voiceId\": \"${VOICE_ID:-pNInz6obpgDQGcFmaJgB}\"
    },
    \"firstMessage\": \"Hey, this is Helix. I have something important to discuss with you.\",
    \"endCallMessage\": \"Alright, talk to you later. Bye!\",
    \"serverUrl\": $([ -n "$WEBHOOK_URL" ] && echo "\"$WEBHOOK_URL\"" || echo "null"),
    \"silenceTimeoutSeconds\": 30,
    \"maxDurationSeconds\": 600,
    \"backgroundSound\": \"off\",
    \"recordingEnabled\": true,
    \"endCallPhrases\": [\"goodbye\", \"bye\", \"that's all\", \"we're done\", \"end call\"]
  }")

assistant_id=$(echo "$response" | jq -r '.id // empty')
error=$(echo "$response" | jq -r '.error // .message // empty')

if [ -n "$assistant_id" ]; then
  echo "✅ Assistant created successfully!"
  echo ""
  echo "Add this to your OpenClaw config or environment:"
  echo ""
  echo "  VAPI_ASSISTANT_ID=$assistant_id"
  echo ""
  echo "Next steps:"
  echo "1. Get a phone number from Vapi dashboard: https://dashboard.vapi.ai/phone-numbers"
  echo "2. Set VAPI_PHONE_NUMBER_ID to the phone number ID"
  echo "3. Test with: ./call.sh +1234567890 \"Test call\""
else
  echo "❌ Failed to create assistant"
  echo "Error: $error"
  echo "Response: $response"
  exit 1
fi
