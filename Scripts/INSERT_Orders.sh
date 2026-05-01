#!/bin/bash
#
# Purpose:
# Simulates order generation for the POS demo app. Inserts a new pos_orders
# document at a configurable interval. Each generated order is in the
# `inProcess` status (one cart item) so it shows up immediately in the KDS
# view. Advancing/paying orders must still be done from the iOS or Android app.
#
# How to use:
# 1. Set CLOUD_ENDPOINT to your own Cloud URL endpoint:
#    https://docs.ditto.live/cloud/http-api/getting-started#cloud-url-endpoint
# 2. Set API_KEY to your own HTTP API key:
#    https://docs.ditto.live/cloud/http-api/auth-and-params#api-key
# 3. Open the iOS or Android POS app and select a location.
# 4. Set LOCATION_ID below to the location you selected (default 00001).
# 5. Run this script.

set -euo pipefail

# ----- Configuration -----
CLOUD_ENDPOINT="https://<YOUR-CLOUD-ENDPOINT>.cloud.ditto.live/api/v4/store/execute"
API_KEY="<YOUR-API-KEY>"
LOCATION_ID="00001"
INTERVAL=1  # seconds between inserts

# Hand-picked sale item from the seed catalog (id 00012 = Milk, $2.00).
SALE_ITEM_ID="00012"
SALE_ITEM_NAME="Milk"
SALE_ITEM_IMAGE="milk"
SALE_ITEM_CENTS=200

# ----- Helpers -----
generate_uuid() { uuidgen; }
iso_now() { date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"; }

# ----- Loop -----
while true; do
  ORDER_ID=$(generate_uuid)
  LINE_ITEM_ID=$(generate_uuid)
  NOW=$(iso_now)

  curl -sS -X POST "$CLOUD_ENDPOINT" \
    --header "Authorization: $API_KEY" \
    --header "Content-Type: application/json" \
    --data-raw "{
      \"statement\": \"INSERT INTO pos_orders DOCUMENTS (:new) ON ID CONFLICT DO UPDATE_LOCAL_DIFF\",
      \"args\": {
        \"new\": {
          \"_id\": { \"id\": \"$ORDER_ID\", \"locationId\": \"$LOCATION_ID\" },
          \"cart\": {
            \"$LINE_ITEM_ID\": {
              \"saleItemId\": \"$SALE_ITEM_ID\",
              \"name\": \"$SALE_ITEM_NAME\",
              \"imageName\": \"$SALE_ITEM_IMAGE\",
              \"price\": { \"amount\": $SALE_ITEM_CENTS, \"currency\": \"usd\" },
              \"qty\": 1,
              \"createdAt\": \"$NOW\"
            }
          },
          \"payments\": {},
          \"status_log\": { \"$NOW\": \"inProcess\" },
          \"createdAt\": \"$NOW\"
        }
      }
    }" \
    && echo

  sleep "$INTERVAL"
done
