#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   export FCM_ACCESS_TOKEN="ya29..."
#   export PROJECT_ID="your-firebase-project-id"
#   export DEVICE_TOKEN="token-from-app"
#   bash server_recipes/rest_api/curl_examples.sh

FCM_URL="https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send"

send_request() {
  local payload="$1"

  curl -sS -X POST "${FCM_URL}" \
    -H "Authorization: Bearer ${FCM_ACCESS_TOKEN}" \
    -H "Content-Type: application/json; charset=utf-8" \
    -d "${payload}"
  printf '\n'
}

echo "== basic =="
send_request '{
  "message": {
    "token": "'"${DEVICE_TOKEN}"'",
    "notification": {
      "title": "Order shipped",
      "body": "Track package #A-1042 in the app."
    },
    "data": {
      "deeplink": "app://orders/A-1042",
      "analytics": "{\"campaign\":\"shipping_update\",\"source\":\"curl\"}"
    }
  }
}'

echo "== data-only bridge =="
send_request '{
  "message": {
    "token": "'"${DEVICE_TOKEN}"'",
    "data": {
      "title": "Inventory back in stock",
      "body": "SKU #48319 is available again.",
      "deeplink": "app://inventory/48319",
      "channelId": "inventory_updates",
      "priority": "high",
      "analytics": "{\"campaign\":\"restock_alert\",\"sku\":\"48319\"}",
      "actions": "[{\"id\":\"open\",\"title\":\"Open\",\"payload\":{\"screen\":\"inventory\",\"sku\":\"48319\"}},{\"id\":\"dismiss\",\"title\":\"Dismiss\",\"destructive\":true}]"
    },
    "android": {
      "priority": "high"
    },
    "apns": {
      "headers": {
        "apns-priority": "5"
      },
      "payload": {
        "aps": {
          "content-available": 1
        }
      }
    }
  }
}'

echo "== in-app template =="
send_request '{
  "message": {
    "token": "'"${DEVICE_TOKEN}"'",
    "data": {
      "fcmh_inapp": "{\"id\":\"promo_2026_launch\",\"templateId\":\"builtin_generic\",\"trigger\":\"immediate\",\"content\":{\"layout\":\"banner\",\"title\":\"New feature live\",\"body\":\"Try the diagnostics panel today.\",\"cta_label\":\"Open\",\"deeplink\":\"app://diagnostics\"},\"analytics\":{\"campaignId\":\"launch_2026\",\"variant\":\"A\"}}"
    }
  }
}'
