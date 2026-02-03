# Vapi Webhook Events

Vapi sends POST requests to your `serverUrl` for various events during a call.

## Event Types

### call.started

Sent when call is initiated.

```json
{
  "type": "call.started",
  "call": {
    "id": "call_abc123",
    "status": "in-progress",
    "customer": {
      "number": "+14155470001"
    },
    "createdAt": "2024-01-15T09:30:00Z"
  }
}
```

### transcript.partial

Real-time transcript updates during the call.

```json
{
  "type": "transcript.partial",
  "call": { "id": "call_abc123" },
  "transcript": {
    "text": "Yes, Friday at noon works for me",
    "role": "user",
    "isFinal": false
  }
}
```

### tool.call

Assistant wants to execute a tool. **Must respond with result.**

```json
{
  "type": "tool.call",
  "call": { "id": "call_abc123" },
  "toolCall": {
    "id": "tc_xyz789",
    "name": "check_calendar",
    "arguments": {
      "date": "2024-02-07"
    }
  }
}
```

**Required response:**

```json
{
  "result": "You have a meeting with Alan Maloney at 9 AM. You're free after 10 AM."
}
```

### call.ended

Call completed. Includes full transcript and analytics.

```json
{
  "type": "call.ended",
  "call": {
    "id": "call_abc123",
    "status": "ended",
    "endedReason": "customer-ended-call",
    "duration": 127
  },
  "artifact": {
    "transcript": "Full conversation transcript...",
    "messages": [
      { "role": "assistant", "message": "Hey Matt..." },
      { "role": "user", "message": "Yes, go ahead..." }
    ],
    "recordingUrl": "https://..."
  }
}
```

## Implementing a Webhook Server

### Basic Express.js Example

```javascript
const express = require('express');
const app = express();
app.use(express.json());

app.post('/vapi/webhook', async (req, res) => {
  const { type, call, toolCall } = req.body;
  
  switch (type) {
    case 'tool.call':
      // Execute the tool and return result
      const result = await executeToolCall(toolCall.name, toolCall.arguments);
      return res.json({ result });
    
    case 'call.ended':
      // Log transcript, trigger follow-up actions
      console.log('Call ended:', call.id);
      console.log('Transcript:', req.body.artifact?.transcript);
      break;
    
    default:
      console.log('Event:', type);
  }
  
  res.json({ ok: true });
});

async function executeToolCall(name, args) {
  switch (name) {
    case 'check_calendar':
      // Call your calendar API
      return await checkCalendar(args.date);
    case 'send_message':
      // Send via OpenClaw
      return await sendMessage(args.to, args.message);
    default:
      return `Unknown tool: ${name}`;
  }
}

app.listen(3000);
```

## OpenClaw Integration

For OpenClaw to handle tool calls during voice conversations, the gateway needs
a webhook endpoint that:

1. Receives Vapi tool.call events
2. Maps tool names to OpenClaw actions
3. Executes actions and returns results
4. Routes call.ended transcripts to the conversation

This integration is pending implementation in OpenClaw core.

## Security

- Validate webhook signatures (Vapi provides HMAC)
- Use HTTPS for your serverUrl
- Rate limit incoming requests
- Sanitize tool call arguments
