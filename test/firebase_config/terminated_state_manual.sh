#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# terminated_state_manual.sh
#
# Manual test helper for the "terminated state / cold start" FCM scenario.
# This cannot be automated inside a test runner because the device must be
# killed and re-launched externally.
#
# Usage:
#   bash test/firebase_config/terminated_state_manual.sh \
#     --token   <fcm-token> \
#     --project <firebase-project-id> \
#     --key-file test/firebase_config/service_account.json
#
# Steps performed:
#   1. Obtains an OAuth2 bearer token from the service account.
#   2. POSTs an FCM notification to the given device token.
#   3. Prints instructions for the developer to follow.
# ---------------------------------------------------------------------------

set -euo pipefail

# ── Argument parsing ────────────────────────────────────────────────────────
FCM_TOKEN=""
PROJECT_ID=""
KEY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)   FCM_TOKEN="$2";   shift 2 ;;
    --project) PROJECT_ID="$2";  shift 2 ;;
    --key-file) KEY_FILE="$2";   shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$FCM_TOKEN" || -z "$PROJECT_ID" || -z "$KEY_FILE" ]]; then
  echo "Usage: $0 --token <fcm-token> --project <project-id> --key-file <path>"
  exit 1
fi

if [[ ! -f "$KEY_FILE" ]]; then
  echo "Service account file not found: $KEY_FILE" >&2
  exit 1
fi

# ── Dependency check ────────────────────────────────────────────────────────
for cmd in python3 curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Required tool not found: $cmd" >&2
    exit 1
  fi
done

# ── Step 1: Obtain OAuth2 bearer token ─────────────────────────────────────
echo "[1/3] Obtaining OAuth2 bearer token from service account…"

BEARER=$(python3 - <<PYEOF
import json, time, base64, hashlib, hmac, urllib.request, urllib.parse

with open("$KEY_FILE") as f:
    sa = json.load(f)

header = base64.urlsafe_b64encode(json.dumps({"alg":"RS256","typ":"JWT"}).encode()).rstrip(b"=").decode()
now = int(time.time())
claims = {
    "iss": sa["client_email"],
    "scope": "https://www.googleapis.com/auth/firebase.messaging",
    "aud": "https://oauth2.googleapis.com/token",
    "exp": now + 3600,
    "iat": now,
}
payload = base64.urlsafe_b64encode(json.dumps(claims).encode()).rstrip(b"=").decode()

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.backends import default_backend

private_key = serialization.load_pem_private_key(
    sa["private_key"].encode(), password=None, backend=default_backend()
)
signing_input = f"{header}.{payload}".encode()
signature = private_key.sign(signing_input, padding.PKCS1v15(), hashes.SHA256())
sig_b64 = base64.urlsafe_b64encode(signature).rstrip(b"=").decode()

jwt = f"{header}.{payload}.{sig_b64}"

data = urllib.parse.urlencode({
    "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
    "assertion": jwt,
}).encode()

req = urllib.request.Request(
    "https://oauth2.googleapis.com/token",
    data=data,
    headers={"Content-Type": "application/x-www-form-urlencoded"},
)
resp = json.loads(urllib.request.urlopen(req).read())
print(resp["access_token"])
PYEOF
)

echo "   ✓ Bearer token obtained."

# ── Step 2: Send FCM notification ──────────────────────────────────────────
echo "[2/3] Sending terminated-state FCM notification…"

TS=$(date +%s)
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer $BEARER" \
  -H "Content-Type: application/json" \
  "https://fcm.googleapis.com/v1/projects/$PROJECT_ID/messages:send" \
  -d "{
    \"message\": {
      \"token\": \"$FCM_TOKEN\",
      \"notification\": {
        \"title\": \"Terminated State Test\",
        \"body\": \"Cold-start integration test — ts=$TS\"
      },
      \"data\": {
        \"fcmh_test_ts\": \"$TS\",
        \"fcmh_test_type\": \"terminated_state\"
      }
    }
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "FCM send failed (HTTP $HTTP_CODE):" >&2
  echo "$BODY" | jq . >&2
  exit 1
fi

echo "   ✓ Message sent. FCM name: $(echo "$BODY" | jq -r .name)"

# ── Step 3: Developer instructions ─────────────────────────────────────────
cat <<INSTRUCTIONS

[3/3] Manual verification steps:
─────────────────────────────────────────────────────────────────────────────
A notification titled "Terminated State Test" has been sent to your device.

To verify the cold-start (terminated state) behaviour:

  1. Force-quit the app on the device NOW (swipe up or use App Switcher).
  2. Wait for the notification to appear on the device lock screen or
     notification shade (usually within a few seconds).
  3. Tap the notification to launch the app.
  4. Inspect the app's initial notification handling:
       FirebaseMessagingHandler.checkInitial()
     should return a non-null NotificationData with:
       - title: "Terminated State Test"
       - payload.fcmh_test_ts: "$TS"
  5. Alternatively, check your unified handler or analytics callback for
     the lifecycle value NotificationLifecycle.terminated.

Expected: The app opens directly to whatever screen your notification router
          targets, and checkInitial() returns the notification data.

─────────────────────────────────────────────────────────────────────────────
INSTRUCTIONS
