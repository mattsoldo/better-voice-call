# Vapi Voice Calls

Make interactive outbound voice calls from OpenClaw using [Vapi](https://vapi.ai).

## What It Does

- **Outbound calls** — Call contacts with a custom first message
- **Real-time conversation** — Natural voice AI with <500ms latency  
- **Tool calling** — Assistant can execute tools mid-conversation (calendar, messaging, etc.)
- **Contact whitelist** — Safety controls to prevent unwanted calls
- **Transcripts** — Full call transcripts available after each call

## Setup

### 1. Create a Vapi Account

Sign up at [dashboard.vapi.ai](https://dashboard.vapi.ai)

### 2. Get Your Credentials

From the Vapi dashboard, you'll need:
- **API Key** — Settings → API Keys
- **Phone Number ID** — Phone Numbers → (buy or import a number) → Copy ID
- **Assistant ID** — Run `scripts/setup.sh` or create manually in Assistants

### 3. Configure OpenClaw

Add to your OpenClaw config (`~/.openclaw/config.yaml`):

```yaml
skills:
  entries:
    vapi-voice:
      env:
        VAPI_API_KEY: "your-api-key"
        VAPI_PHONE_NUMBER_ID: "your-phone-number-id"
        VAPI_ASSISTANT_ID: "your-assistant-id"
```

Or set as environment variables.

### 4. Initialize Contacts (Optional)

Copy the example contacts file:

```bash
cp contacts.json.example contacts.json
```

Then add your contacts:

```bash
./scripts/contacts.sh add "Mom" "+14155551234" "family" "Call anytime"
```

## Usage

### Make a Call

```bash
./scripts/call.sh "+14155551234" "Hey, just checking in to see if you need anything."
```

### With Force (Skip Whitelist)

```bash
./scripts/call.sh "+18005551234" "Hi, calling about my order" --force
```

### Manage Contacts

```bash
# List all contacts
./scripts/contacts.sh list

# Add a contact
./scripts/contacts.sh add "Name" "+1234567890" "role" "notes"

# Remove a contact
./scripts/contacts.sh remove "+1234567890"

# Check if whitelisted
./scripts/contacts.sh check "+1234567890"
```

### View Call History

```bash
./scripts/list-calls.sh
```

### Get Transcript

```bash
./scripts/get-transcript.sh <call-id>
```

## Scripts

| Script | Purpose |
|--------|---------|
| `call.sh` | Make an outbound call |
| `contacts.sh` | Manage contact whitelist |
| `list-calls.sh` | List recent calls |
| `get-transcript.sh` | Retrieve call transcript |
| `setup.sh` | Create/configure Vapi assistant |

## Safety Features

### Whitelist Mode (Default)

Only contacts in `contacts.json` can be called. This prevents accidental calls to wrong numbers.

### Bypass with --force

Use `--force` flag to call any number (use responsibly).

### Disable Whitelist

```bash
./scripts/contacts.sh settings require-whitelist false
```

## Integration with OpenClaw

When used as an OpenClaw skill, the agent can:

1. Check contact permissions before calling
2. Initiate calls with context-aware messages
3. Follow up with text if call goes to voicemail
4. Log interactions for continuity

### Example Agent Prompt

> "Call Tiffany and ask if she needs anything. If you don't get her, text."

The agent will:
1. Look up Tiffany in contacts
2. Initiate the call with appropriate message
3. Monitor call status
4. Send text if it goes to voicemail

## Pricing

Vapi charges per minute, typically $0.05-0.15/min depending on:
- Voice provider (ElevenLabs costs more than Deepgram)
- LLM model (Claude/GPT-4 vs faster models)
- Telephony rates

## Troubleshooting

### "VAPI_API_KEY is required"

Set your credentials in OpenClaw config or environment.

### Call Not Connecting

- Check phone number format (+1XXXXXXXXXX)
- Verify Vapi phone number is active
- Check Vapi dashboard for error logs

### Whitelist Errors

Either add the contact or use `--force`:

```bash
./scripts/contacts.sh add "New Contact" "+1234567890"
# or
./scripts/call.sh "+1234567890" "message" --force
```

## References

- [Vapi Documentation](https://docs.vapi.ai)
- `references/assistant-config.md` — Assistant setup guide
- `references/webhook-events.md` — Webhook integration details

## License

MIT
