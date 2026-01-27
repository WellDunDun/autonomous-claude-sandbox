#!/bin/bash
# Generate a secure random token for SERVER_AUTH_TOKEN
# Output: JSON with the generated token
# Exit: 0 on success

set -e

# Generate 32 bytes of random hex (64 characters)
TOKEN=$(openssl rand -hex 32)

cat <<EOF
{
  "success": true,
  "token": "$TOKEN",
  "instructions": {
    "step1": "Copy the token above",
    "step2": "Run: npx wrangler secret put SERVER_AUTH_TOKEN",
    "step3": "Paste the token when prompted",
    "step4": "Save this token securely - you need it for API requests"
  }
}
EOF

exit 0
