#!/bin/bash

# Configuration
TARGET_HOST="http://localhost:8081"
ENDPOINTS=("/hello" "/error")
METHODS=("GET" "POST" "DELETE")

# Range for random delay in milliseconds (500ms to 2500ms)
MIN_MS=0
MAX_MS=1500

echo "Starting traffic simulation to $TARGET_HOST with random delays..."
echo "Press [CTRL+C] to stop."
echo "--------------------------------------------"

while true; do
  # Randomly select an endpoint and a method
  RANDOM_ENDPOINT=${ENDPOINTS[$RANDOM % ${#ENDPOINTS[@]}]}
  RANDOM_METHOD=${METHODS[$RANDOM % ${#METHODS[@]}]}
  URL="${TARGET_HOST}${RANDOM_ENDPOINT}"

  # Calculate a random delay in milliseconds
  RANGE=$((MAX_MS - MIN_MS + 1))
  RANDOM_MS=$((MIN_MS + RANDOM % RANGE))
  # Convert to a decimal string for the sleep command (e.g., 1250 ms -> 1.250 seconds)
  DELAY_SEC=$(printf "%d.%03d" $((RANDOM_MS / 1000)) $((RANDOM_MS % 1000)))

  echo "Sending $RANDOM_METHOD request to $URL..."

  # Execute the request
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X "$RANDOM_METHOD" "$URL")

  echo "-> Response Status: $HTTP_STATUS (Waiting ${DELAY_SEC}s)"
  echo "--------------------------------------------"

  # Wait for the randomized duration
  sleep "$DELAY_SEC"
done
