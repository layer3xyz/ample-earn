#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Ample Earn Interest Tracker${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check required environment variables
if [[ -z "${AMPLE_EARN:-}" ]]; then
    echo -e "${RED}✗ Error: AMPLE_EARN environment variable not set${NC}"
    exit 1
fi

if [[ -z "${RPC_URL:-}" ]]; then
    echo -e "${RED}✗ Error: RPC_URL environment variable not set${NC}"
    exit 1
fi

echo -e "${CYAN}AmpleEarn Vault:${NC} ${GREEN}$AMPLE_EARN${NC}"
echo ""

# Fetch data
echo -e "${YELLOW}📊 Fetching vault data...${NC}"

CURRENT_RAW=$(cast call $AMPLE_EARN "totalAssets()(uint256)" --rpc-url $RPC_URL)
LAST_RAW=$(cast call $AMPLE_EARN "lastTotalAssets()(uint256)" --rpc-url $RPC_URL)
PRIZE_DRAW_RAW=$(cast call $AMPLE_EARN "prizeDraw()(address)" --rpc-url $RPC_URL)

CURRENT=$(echo "$CURRENT_RAW" | awk '{print $1}')
LAST=$(echo "$LAST_RAW" | awk '{print $1}')
PRIZE_DRAW=$(echo "$PRIZE_DRAW_RAW" | awk '{print $1}')

ACCRUED_INTEREST_RAW=$(cast call $AMPLE_EARN "getCurrentPrizeAmount()(uint256)" --rpc-url $RPC_URL)
ACCRUED_INTEREST=$(echo "$ACCRUED_INTEREST_RAW" | awk '{print $1}')

PENDING=$((CURRENT - LAST))
TOTAL=$((PENDING + ACCRUED_INTEREST))

echo -e "${GREEN}✓ Data fetched successfully${NC}"
echo ""

# Display results
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Vault State${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${CYAN}Current Total Assets:${NC}"
echo -e "    ${GREEN}$CURRENT_RAW${NC}"
echo ""

echo -e "  ${CYAN}Last Total Assets:${NC}"
echo -e "    ${GREEN}$LAST_RAW${NC}"
echo ""

echo -e "  ${CYAN}Prize Draw Contract:${NC}"
echo -e "    ${GREEN}$PRIZE_DRAW_RAW${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Interest Breakdown${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${CYAN}Pending Interest:${NC}"
echo -e "    (totalAssets - lastTotalAssets)"
if [[ $PENDING -eq 0 ]]; then
    echo -e "    ${YELLOW}$PENDING${NC}"
else
    echo -e "    ${GREEN}$PENDING${NC}"
fi
echo ""

echo -e "  ${CYAN}Accrued Interest in Prize Draw:${NC}"
if [[ $ACCRUED_INTEREST -eq 0 ]]; then
    echo -e "    ${YELLOW}$ACCRUED_INTEREST_RAW${NC}"
else
    echo -e "    ${GREEN}$ACCRUED_INTEREST_RAW${NC}"
fi
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [[ $TOTAL -eq 0 ]]; then
    echo -e "${YELLOW}💰 Total Interest Accrued: $TOTAL${NC}"
    echo -e "${YELLOW}   No interest has been generated yet${NC}"
else
    echo -e "${GREEN}💰 Total Interest Accrued: $TOTAL${NC}"
    echo -e "${CYAN}   Pending: $PENDING${NC}"
    echo -e "${CYAN}   In Prize Draw: $ACCRUED_INTEREST${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

