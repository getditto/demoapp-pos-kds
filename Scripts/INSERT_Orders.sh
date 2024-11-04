# Purpose:
# This script will simulate order generation for the POS demo app. It will generate a new order at a given configurable Interval (seconds).
# Every new order will be set to the satus value of 1; which is the first initial status after an order is created.
# Bumping the order must be done from the iOS or Android app.

# HOW TO USE:
# 1. Replace "https://<CLOUD_ENDPOINT>/api/v4/store/execute" with your own cloud url Endpoint. Read more about the cloud url endpoint here: https://docs.ditto.live/cloud/http-api/getting-started#RBdx2
# 2. Replace `--header 'Authorization: <AUTHORIZATION-TOKEN>' with your own auth token. Read more about auth tokens here: https://docs.ditto.live/cloud/http-api/authorization
# 3. Open the iOS or Android POS app
# 4. Run this script


#!/bin/bash

# Interval in seconds (change this value to your desired interval)
INTERVAL=1

# Function to generate a random UUID (macOS uses uuidgen)
generate_uuid() {
  uuidgen
}

# Function to get the current timestamp in ISO 8601 format
get_current_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
}

# Run until interrupted
while true; do
  # Generate random UUIDs
  ID_UUID=$(generate_uuid)
  TRANSACTION_UUID=$(generate_uuid)

  # Generate current timestamp
  CURRENT_TIMESTAMP=$(get_current_timestamp)

  # Generate random UUIDs and timestamps for saleItemIds
  SALEITEM_KEY_1="$(generate_uuid)_$(get_current_timestamp)"
  SALEITEM_KEY_2="$(generate_uuid)_$(get_current_timestamp)"
  SALEITEM_KEY_3="$(generate_uuid)_$(get_current_timestamp)"
  SALEITEM_KEY_4="$(generate_uuid)_$(get_current_timestamp)"
  SALEITEM_KEY_5="$(generate_uuid)_$(get_current_timestamp)"

  curl -X POST "https://ef7f7d95-81ba-44f6-bdfe-eb74ee57d520.cloud.ditto.live/api/v4/store/execute" \
    --header 'Authorization: PDFCfhxPcTtlf9zS1wh8JPQxovAXlqjfd2mb98CaP4cuBqduS2lZmL6VtFGT' \
    --header 'Content-Type: application/json' \
    --data-raw "{
        \"statement\": \"INSERT INTO orders DOCUMENTS (:new)\",
        \"args\": {
          \"new\": {
            \"_id\": {
              \"id\": \"$ID_UUID\",
              \"locationId\": \"00001\"
            },
            \"createdOn\": \"$CURRENT_TIMESTAMP\",
            \"deviceId\": \"9385746202362977847\",
            \"saleItemIds\": {
              \"$SALEITEM_KEY_1\": \"00012\",
              \"$SALEITEM_KEY_2\": \"00012\",
              \"$SALEITEM_KEY_3\": \"00012\",
              \"$SALEITEM_KEY_4\": \"00012\",
              \"$SALEITEM_KEY_5\": \"00012\"
            },
            \"status\": 1,
            \"transactionIds\": {
              \"$TRANSACTION_UUID\": 2
            }
          }
        }
    }"
  
  # Wait for the defined interval
  sleep $INTERVAL
done
