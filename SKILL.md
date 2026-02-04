---
name: better-voice-call
description: "Make interactive voice calls via Vapi. Use for urgent matters, complex decisions, or when the user explicitly requests a call."
metadata:
  {
    "openclaw":
      {
        "emoji": "📞",
        "requires": { "env": ["VAPI_API_KEY", "VAPI_PHONE_NUMBER_ID", "VAPI_ASSISTANT_ID"] },
        "primaryEnv": "VAPI_API_KEY"
      }
  }
---

# Vapi Voice Calls

Make outbound voice calls using [Vapi](https://vapi.ai) voice AI.

## Setup

### 1. Create a Vapi Account

Go to [vapi.ai](https://vapi.ai) and sign up.

### 2. Get Your API Key

1. Open [dashboard.vapi.ai](https://dashboard.vapi.ai)
2. Go to **Organization Settings** (gear icon) → **API Keys**
3. Click **Create API Key** or copy your existing key
4. Save this as `VAPI_API_KEY`

### 3. Get a Phone Number

1. In the Vapi dashboard, go to **Phone Numbers**
2. Click **Get a Number**
3. Copy the **ID** (not the phone number itself)
4. Save this as `VAPI_PHONE_NUMBER_ID`

### 4. Create an Assistant

Run the setup script:

```bash
./scripts/setup.sh
```

Or create manually in the dashboard:
1. Go to **Assistants** → **Create Assistant**
2. Configure model (Claude/GPT-4), voice, and first message
3. **Enable voicemail detection** (see below)
4. Copy the **Assistant ID**
5. Save this as `VAPI_ASSISTANT_ID`

### 5. Configure OpenClaw

Add to your OpenClaw config (`~/.openclaw/config.yaml`):

```yaml
skills:
  entries:
    better-voice-call:
      env:
        VAPI_API_KEY: "your-api-key"
        VAPI_PHONE_NUMBER_ID: "your-phone-number-id"
        VAPI_ASSISTANT_ID: "your-assistant-id"
```

Or export as environment variables:

```bash
export VAPI_API_KEY="your-api-key"
export VAPI_PHONE_NUMBER_ID="your-phone-number-id"
export VAPI_ASSISTANT_ID="your-assistant-id"
```

### 6. Set Up Contacts (Optional)

```bash
cp contacts.json.example contacts.json
./scripts/contacts.sh add "Mom" "+14155551234" "family"
./scripts/contacts.sh add "Assistant" "+14155559999" "work"
```

## Usage

### Make a call

```bash
./scripts/call.sh "+14155551234" "Hey, just checking in!"
```

### Bypass whitelist

```bash
./scripts/call.sh "+18005551234" "Calling about my order" --force
```

### Manage contacts

```bash
./scripts/contacts.sh list
./scripts/contacts.sh add "Name" "+14155551234" "role"
./scripts/contacts.sh remove "+14155551234"
./scripts/contacts.sh check "+14155551234"
```

### View call history

```bash
./scripts/list-calls.sh
```

### Get transcript

```bash
./scripts/get-transcript.sh <call-id>
```

## Voicemail Handling

The assistant automatically handles voicemail using Vapi's voicemail detection:

### How It Works

1. **Detection**: Vapi detects voicemail systems using audio analysis and transcription
2. **Wait for beep**: Waits up to 30 seconds for the voicemail beep
3. **Leave message**: Speaks a pre-configured voicemail message after the beep
4. **Hang up**: Ends the call cleanly

### Configuration

When creating an assistant via `setup.sh`, voicemail detection is enabled by default with:
- **Provider**: Vapi (recommended - fast and accurate)
- **Voicemail message**: "Hi, this is Helix calling on behalf of Matt. Please give him a call back when you get a chance. Thanks!"

### Manual Configuration

In the Vapi dashboard:
1. Go to your Assistant → Settings
2. Find **Voicemail Detection**
3. Enable and select provider (Vapi recommended)
4. Set **Voicemail Message** — what to say when voicemail is detected

### API Configuration

```json
{
  "voicemailDetection": {
    "provider": "vapi",
    "enabled": true
  },
  "voicemailMessage": "Hi, this is Helix calling on behalf of Matt. Please call back when you can. Thanks!"
}
```

### Troubleshooting Voicemail

**AI tries to "press buttons" verbally**
→ Enable voicemail detection — the AI will recognize voicemail systems and leave a message instead

**Message gets cut off**
→ Increase `beepMaxAwaitSeconds` (default 30, max 60) — some voicemail greetings are long

**False positives (human answers, AI thinks it's voicemail)**
→ Use Vapi or Google provider — they have better false positive protection

## When to Call

**Good use cases:**
- Urgent matters requiring immediate response
- Complex decisions needing real-time back-and-forth
- Time-sensitive items where text might be missed
- User explicitly requests a call

**Avoid calling for:**
- Routine notifications (use text instead)
- Late night (23:00–08:00) unless critical
- Non-urgent updates

## Safety

By default, only contacts in `contacts.json` can be called.

```bash
# Add a contact
./scripts/contacts.sh add "Name" "+14155551234"

# Disable whitelist entirely
./scripts/contacts.sh settings require-whitelist false
```

Or use `--force` to bypass for a single call.

## Pricing

Vapi charges ~$0.05–0.15 per minute depending on voice provider and LLM model.

## Troubleshooting

**"VAPI_API_KEY is required"**
→ Add credentials to OpenClaw config or set environment variables

**Call not connecting**
→ Check phone format (+1XXXXXXXXXX), verify number is active in Vapi dashboard

**"Not whitelisted" error**
→ Add contact or use `--force`

**Daily call limit reached**
→ Vapi free numbers have limits. Import a Twilio number for unlimited calls.

## References

- [Vapi Documentation](https://docs.vapi.ai)
- [Voicemail Detection Guide](https://docs.vapi.ai/calls/voicemail-detection)
- `references/assistant-config.md` — Assistant configuration details
- `references/webhook-events.md` — Webhook integration for tool calling
