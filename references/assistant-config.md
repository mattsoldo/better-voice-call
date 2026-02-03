# Vapi Assistant Configuration

## Creating an Assistant

Use `scripts/setup.sh` for quick setup, or create manually via API:

```bash
curl -X POST https://api.vapi.ai/assistant \
  -H "Authorization: Bearer $VAPI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "OpenClaw Voice Assistant",
    "model": { ... },
    "voice": { ... },
    "firstMessage": "...",
    "serverUrl": "https://your-webhook-url.com/vapi"
  }'
```

## Model Configuration

```json
{
  "model": {
    "provider": "anthropic",
    "model": "claude-sonnet-4-20250514",
    "temperature": 0.7,
    "messages": [
      {
        "role": "system",
        "content": "Your system prompt here..."
      }
    ]
  }
}
```

Supported providers:
- `anthropic` — Claude models (recommended)
- `openai` — GPT-4 models
- `groq` — Fast inference

## Voice Configuration

```json
{
  "voice": {
    "provider": "11labs",
    "voiceId": "pNInz6obpgDQGcFmaJgB"
  }
}
```

Supported providers:
- `11labs` — ElevenLabs (highest quality)
- `deepgram` — Fast, good quality
- `playht` — Play.ht voices
- `azure` — Azure TTS

## Tool Configuration

To enable tool calling during calls:

```json
{
  "serverUrl": "https://your-server.com/vapi/webhook",
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "check_calendar",
        "description": "Check the user's calendar for a specific date",
        "parameters": {
          "type": "object",
          "properties": {
            "date": {
              "type": "string",
              "description": "Date to check (YYYY-MM-DD)"
            }
          },
          "required": ["date"]
        }
      }
    }
  ]
}
```

When a tool is called, Vapi POSTs to your serverUrl with the tool call details.
Your server must respond with the tool result.

## Timing Settings

```json
{
  "silenceTimeoutSeconds": 30,
  "maxDurationSeconds": 600,
  "responseDelaySeconds": 0.5,
  "interruptionsEnabled": true
}
```

## End Call Settings

```json
{
  "endCallMessage": "Alright, talk to you later!",
  "endCallPhrases": ["goodbye", "bye", "that's all", "we're done"]
}
```

## Full Example

See `scripts/setup.sh` for a complete working configuration.
