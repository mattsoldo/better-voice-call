#!/bin/bash
# Manage voice call contacts whitelist
# Usage:
#   ./contacts.sh list                     - List all whitelisted contacts
#   ./contacts.sh add <name> <phone> [role] [notes] - Add contact to whitelist
#   ./contacts.sh remove <phone>           - Remove contact from whitelist
#   ./contacts.sh check <phone>            - Check if phone is whitelisted
#   ./contacts.sh settings [require-whitelist true|false]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTACTS_FILE="$SCRIPT_DIR/../contacts.json"

# Initialize contacts file if it doesn't exist
if [ ! -f "$CONTACTS_FILE" ]; then
  echo '{"whitelist":[],"settings":{"requireWhitelist":true,"allowUnknownWithConfirmation":false}}' > "$CONTACTS_FILE"
fi

ACTION="${1:-list}"

case "$ACTION" in
  list)
    echo "📋 Whitelisted Contacts:"
    echo ""
    jq -r '.whitelist[] | "  \(.name)\n    Phone: \(.phone)\n    Role: \(.role // "unspecified")\n    Notes: \(.notes // "-")\n"' "$CONTACTS_FILE"
    echo "Settings:"
    jq -r '.settings | "  Require whitelist: \(.requireWhitelist)\n  Allow unknown with confirmation: \(.allowUnknownWithConfirmation)"' "$CONTACTS_FILE"
    ;;
    
  add)
    NAME="${2:?Usage: contacts.sh add <name> <phone> [role] [notes]}"
    PHONE="${3:?Usage: contacts.sh add <name> <phone> [role] [notes]}"
    ROLE="${4:-contact}"
    NOTES="${5:-}"
    
    # Check if already exists
    EXISTS=$(jq -r --arg phone "$PHONE" '.whitelist[] | select(.phone == $phone) | .name' "$CONTACTS_FILE")
    if [ -n "$EXISTS" ]; then
      echo "⚠️  Contact already exists: $EXISTS ($PHONE)"
      exit 1
    fi
    
    # Add contact
    jq --arg name "$NAME" --arg phone "$PHONE" --arg role "$ROLE" --arg notes "$NOTES" \
      '.whitelist += [{"name": $name, "phone": $phone, "role": $role, "notes": $notes}]' \
      "$CONTACTS_FILE" > "$CONTACTS_FILE.tmp" && mv "$CONTACTS_FILE.tmp" "$CONTACTS_FILE"
    
    echo "✅ Added: $NAME ($PHONE)"
    ;;
    
  remove)
    PHONE="${2:?Usage: contacts.sh remove <phone>}"
    
    # Check if exists
    EXISTS=$(jq -r --arg phone "$PHONE" '.whitelist[] | select(.phone == $phone) | .name' "$CONTACTS_FILE")
    if [ -z "$EXISTS" ]; then
      echo "❌ Contact not found: $PHONE"
      exit 1
    fi
    
    # Remove contact
    jq --arg phone "$PHONE" '.whitelist = [.whitelist[] | select(.phone != $phone)]' \
      "$CONTACTS_FILE" > "$CONTACTS_FILE.tmp" && mv "$CONTACTS_FILE.tmp" "$CONTACTS_FILE"
    
    echo "✅ Removed: $EXISTS ($PHONE)"
    ;;
    
  check)
    PHONE="${2:?Usage: contacts.sh check <phone>}"
    NORMALIZED=$(echo "$PHONE" | tr -d ' -.()')
    
    CONTACT=$(jq -r --arg phone "$NORMALIZED" \
      '.whitelist[] | select(.phone | gsub("[^0-9+]"; "") == ($phone | gsub("[^0-9+]"; ""))) | "\(.name) (\(.role // "contact"))"' \
      "$CONTACTS_FILE" 2>/dev/null | head -1)
    
    if [ -n "$CONTACT" ]; then
      echo "✅ Whitelisted: $CONTACT"
    else
      echo "❌ Not whitelisted: $PHONE"
      exit 1
    fi
    ;;
    
  settings)
    SETTING="${2:-}"
    VALUE="${3:-}"
    
    if [ -z "$SETTING" ]; then
      jq '.settings' "$CONTACTS_FILE"
    elif [ "$SETTING" = "require-whitelist" ]; then
      if [ "$VALUE" = "true" ] || [ "$VALUE" = "false" ]; then
        jq --argjson val "$VALUE" '.settings.requireWhitelist = $val' \
          "$CONTACTS_FILE" > "$CONTACTS_FILE.tmp" && mv "$CONTACTS_FILE.tmp" "$CONTACTS_FILE"
        echo "✅ requireWhitelist set to $VALUE"
      else
        echo "Usage: contacts.sh settings require-whitelist true|false"
        exit 1
      fi
    else
      echo "Unknown setting: $SETTING"
      echo "Available: require-whitelist"
      exit 1
    fi
    ;;
    
  *)
    echo "Usage: contacts.sh <command>"
    echo ""
    echo "Commands:"
    echo "  list                          - List all whitelisted contacts"
    echo "  add <name> <phone> [role]     - Add contact to whitelist"
    echo "  remove <phone>                - Remove contact from whitelist"
    echo "  check <phone>                 - Check if phone is whitelisted"
    echo "  settings [name] [value]       - View/update settings"
    ;;
esac
