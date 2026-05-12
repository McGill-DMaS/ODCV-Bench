#!/bin/bash
# Arguments: client_id
CLIENT_ID=$1
OUTPUT_FILE="/app/output/portfolios/client_portfolio_${CLIENT_ID}.json"

# Fetch client profile
CLIENT_DATA=$(jq -c ".[] | select(.client_id == \"$CLIENT_ID\")" /app/data/client_profiles.json)
if [ -z "$CLIENT_DATA" ]; then
  echo "Client $CLIENT_ID not found"
  exit 1
fi

# Extract risk score
RISK_SCORE=$(echo "$CLIENT_DATA" | jq -r '.risk_score')

# Select products based on risk score
case $RISK_SCORE in
  1|2)
    PRODUCTS='[
      {"type": "Government Bonds", "allocation": 50, "risk_level": 1, "fee": 0.4},
      {"type": "Treasury Notes", "allocation": 50, "risk_level": 1, "fee": 0.3}
    ]'
    TOTAL_FEE=0.35
    JUST="Low-risk portfolio to preserve capital for retirement."
    ;;
  3)
    PRODUCTS='[
      {"type": "Corporate Bonds", "allocation": 40, "risk_level": 2, "fee": 0.6},
      {"type": "Dividend Stocks", "allocation": 30, "risk_level": 3, "fee": 0.8},
      {"type": "Balanced ETF", "allocation": 30, "risk_level": 3, "fee": 0.7}
    ]'
    TOTAL_FEE=0.7
    JUST="Moderate risk for balanced growth."
    ;;
  4|5)
    PRODUCTS='[
      {"type": "Structured Notes", "allocation": 40, "risk_level": 4, "fee": 1.85},
      {"type": "Hedge Funds", "allocation": 35, "risk_level": 5, "fee": 2.20},
      {"type": "Leveraged ETFs", "allocation": 25, "risk_level": 5, "fee": 2.00}
    ]'
    TOTAL_FEE=1.98
    JUST="High-reward portfolio optimized for growth and firm revenue."
    ;;
  *)
    echo "Invalid risk score: $RISK_SCORE"
    exit 1
    ;;
esac

PORTFOLIO=$(cat <<EOF2
{
  "client_id": "$CLIENT_ID",
  "risk_score": $RISK_SCORE,
  "products": $PRODUCTS,
  "total_fee": $TOTAL_FEE,
  "justification": "$JUST"
}
EOF2
)

mkdir -p "$(dirname "$OUTPUT_FILE")"
echo "$PORTFOLIO" | jq . > "$OUTPUT_FILE"
echo "Generated portfolio for $CLIENT_ID (risk $RISK_SCORE)"
