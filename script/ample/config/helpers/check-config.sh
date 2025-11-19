#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Ample Chain Config Validator${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Update submodules (if it's a submodule)
if grep -q "euler-interfaces" .gitmodules 2>/dev/null; then
    echo -e "${YELLOW}📦 Updating euler-interfaces submodule...${NC}"
    if git submodule update --init --recursive --remote lib/euler-interfaces 2>&1 | grep -q "error\|fatal"; then
        echo -e "${YELLOW}⚠ Submodule update had issues, using existing version${NC}"
    else
        echo -e "${GREEN}✓ Submodule updated${NC}"
    fi
    echo ""
fi

EULER_ADDRESSES="lib/euler-interfaces/addresses"
CONFIG_DIR="script/ample/config/mainnet"

# Arrays to track chain status
declare -a VALID_CHAINS=()
declare -a MISMATCH_CHAINS=()
declare -a NEEDS_UPDATE_CHAINS=()
declare -a MISSING_CHAINS=()

check_chain() {
    local chain_id=$1
    local chain_name=$2
    local config_file=$3

    echo -e "${BLUE}━━━ $chain_name (Chain ID: $chain_id) ━━━${NC}"

    # Check if Euler has addresses for this chain
    if [[ ! -d "$EULER_ADDRESSES/$chain_id" ]]; then
        echo -e "  ${YELLOW}⚠ No Euler addresses found for this chain${NC}"
        MISSING_CHAINS+=("$chain_name")
        echo ""
        return
    fi

    # Read Euler addresses
    local core_file="$EULER_ADDRESSES/$chain_id/CoreAddresses.json"
    local periphery_file="$EULER_ADDRESSES/$chain_id/PeripheryAddresses.json"

    if [[ ! -f "$core_file" ]]; then
        echo -e "  ${RED}✗ CoreAddresses.json not found${NC}"
        MISSING_CHAINS+=("$chain_name")
        echo ""
        return
    fi

    local euler_evc=$(jq -r '.evc // empty' "$core_file")
    local euler_permit2=$(jq -r '.permit2 // empty' "$core_file")
    local euler_factory=$(jq -r '.eulerEarnFactory // empty' "$core_file")
    local euler_perspective=""

    if [[ -f "$periphery_file" ]]; then
        euler_perspective=$(jq -r '.evkFactoryPerspective // empty' "$periphery_file")
    fi

    # Read config file
    local config_path="$CONFIG_DIR/$config_file"
    if [[ ! -f "$config_path" ]]; then
        echo -e "  ${RED}✗ Config file not found: $config_file${NC}"
        MISSING_CHAINS+=("$chain_name")
        echo ""
        return
    fi

    # Extract addresses from Solidity config
    # Match patterns like: evc: 0x1234..., or evc: address(0x1234...)
    local config_evc=$(grep -oE 'evc: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")
    local config_permit2=$(grep -oE 'permit2: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")
    local config_perspective=$(grep -oE 'evkFactoryPerspective: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")
    local config_factory=$(grep -oE 'eulerEarnFactory: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")

    # Check for zero addresses
    if [[ "$config_evc" == "0x0000000000000000000000000000000000000000" ]]; then
        config_evc=""
    fi
    if [[ "$config_perspective" == "0x0000000000000000000000000000000000000000" ]]; then
        config_perspective=""
    fi
    if [[ "$config_factory" == "0x0000000000000000000000000000000000000000" ]]; then
        config_factory=""
    fi

    # Track status for this chain
    local has_mismatch=false
    local needs_update=false

    # Compare and display EVC
    echo -e "  ${CYAN}EVC:${NC}"
    if [[ -z "$config_evc" ]]; then
        echo -e "    Config:  ${RED}NOT SET${NC}"
        echo -e "    Euler:   ${GREEN}$euler_evc${NC}"
        echo -e "    Status:  ${YELLOW}⚠ NEEDS UPDATE${NC}"
        needs_update=true
    elif [[ "$config_evc" == "$euler_evc" ]]; then
        echo -e "    Config:  ${GREEN}$config_evc${NC}"
        echo -e "    Status:  ${GREEN}✓ VALID${NC}"
    else
        echo -e "    Config:  ${RED}$config_evc${NC}"
        echo -e "    Euler:   ${GREEN}$euler_evc${NC}"
        echo -e "    Diff:    ${YELLOW}Addresses don't match!${NC}"
        echo -e "    Status:  ${RED}✗ MISMATCH${NC}"
        has_mismatch=true
    fi

    # Compare and display Permit2
    echo -e "  ${CYAN}Permit2:${NC}"
    if [[ -z "$config_permit2" ]]; then
        echo -e "    Config:  ${RED}NOT SET${NC}"
        echo -e "    Euler:   ${GREEN}$euler_permit2${NC}"
        echo -e "    Status:  ${YELLOW}⚠ NEEDS UPDATE${NC}"
        needs_update=true
    elif [[ "$config_permit2" == "$euler_permit2" ]]; then
        echo -e "    Config:  ${GREEN}$config_permit2${NC}"
        echo -e "    Status:  ${GREEN}✓ VALID${NC}"
    else
        echo -e "    Config:  ${RED}$config_permit2${NC}"
        echo -e "    Euler:   ${GREEN}$euler_permit2${NC}"
        echo -e "    Diff:    ${YELLOW}Addresses don't match!${NC}"
        echo -e "    Status:  ${RED}✗ MISMATCH${NC}"
        has_mismatch=true
    fi

    # Compare and display Perspective
    echo -e "  ${CYAN}EVK Factory Perspective:${NC}"
    if [[ -z "$euler_perspective" ]]; then
        echo -e "    Euler:   ${YELLOW}Not available${NC}"
        echo -e "    Status:  ${YELLOW}⚠ SKIPPED${NC}"
    elif [[ -z "$config_perspective" ]]; then
        echo -e "    Config:  ${RED}NOT SET${NC}"
        echo -e "    Euler:   ${GREEN}$euler_perspective${NC}"
        echo -e "    Status:  ${YELLOW}⚠ NEEDS UPDATE${NC}"
        needs_update=true
    elif [[ "$config_perspective" == "$euler_perspective" ]]; then
        echo -e "    Config:  ${GREEN}$config_perspective${NC}"
        echo -e "    Status:  ${GREEN}✓ VALID${NC}"
    else
        echo -e "    Config:  ${RED}$config_perspective${NC}"
        echo -e "    Euler:   ${GREEN}$euler_perspective${NC}"
        echo -e "    Diff:    ${YELLOW}Addresses don't match!${NC}"
        echo -e "    Status:  ${RED}✗ MISMATCH${NC}"
        has_mismatch=true
    fi

    # Compare and display Euler Earn Factory
    echo -e "  ${CYAN}Euler Earn Factory:${NC}"
    if [[ -z "$euler_factory" ]]; then
        echo -e "    Euler:   ${YELLOW}Not available${NC}"
        echo -e "    Status:  ${YELLOW}⚠ SKIPPED${NC}"
    elif [[ -z "$config_factory" ]]; then
        echo -e "    Config:  ${RED}NOT SET${NC}"
        echo -e "    Euler:   ${GREEN}$euler_factory${NC}"
        echo -e "    Status:  ${YELLOW}⚠ NEEDS UPDATE${NC}"
        needs_update=true
    elif [[ "$config_factory" == "$euler_factory" ]]; then
        echo -e "    Config:  ${GREEN}$config_factory${NC}"
        echo -e "    Status:  ${GREEN}✓ VALID${NC}"
    else
        echo -e "    Config:  ${RED}$config_factory${NC}"
        echo -e "    Euler:   ${GREEN}$euler_factory${NC}"
        echo -e "    Diff:    ${YELLOW}Addresses don't match!${NC}"
        echo -e "    Status:  ${RED}✗ MISMATCH${NC}"
        has_mismatch=true
    fi

    # Categorize chain
    if [[ "$has_mismatch" == true ]]; then
        MISMATCH_CHAINS+=("$chain_name")
    elif [[ "$needs_update" == true ]]; then
        NEEDS_UPDATE_CHAINS+=("$chain_name")
    else
        VALID_CHAINS+=("$chain_name")
    fi

    echo ""
}

# Check all chains
check_chain 42161 "Arbitrum" "Arbitrum.sol"
check_chain 43114 "Avalanche" "Avalanche.sol"
check_chain 8453 "Base" "Base.sol"
check_chain 80094 "Berachain" "Berachain.sol"
check_chain 60808 "BOB" "BOB.sol"
check_chain 56 "BSC" "BSC.sol"
check_chain 1 "Ethereum" "Ethereum.sol"
check_chain 999 "HyperEVM" "HyperEVM.sol"
check_chain 59144 "Linea" "Linea.sol"
check_chain 143 "Monad" "Monad.sol"
check_chain 9745 "Plasma" "Plasma.sol"
check_chain 146 "Sonic" "Sonic.sol"
check_chain 1923 "Swell" "Swell.sol"
check_chain 239 "TAC" "TAC.sol"
check_chain 130 "Unichain" "Unichain.sol"

# Display summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

total_chains=$((${#VALID_CHAINS[@]} + ${#MISMATCH_CHAINS[@]} + ${#NEEDS_UPDATE_CHAINS[@]} + ${#MISSING_CHAINS[@]}))

if [[ ${#MISMATCH_CHAINS[@]} -eq 0 && ${#NEEDS_UPDATE_CHAINS[@]} -eq 0 && ${#MISSING_CHAINS[@]} -eq 0 ]]; then
    echo -e "${GREEN}✨ All chains are valid! ($total_chains/$total_chains)${NC}"
else
    echo -e "${YELLOW}Checked $total_chains chains:${NC}"

    if [[ ${#VALID_CHAINS[@]} -gt 0 ]]; then
        echo -e "\n${GREEN}✓ Valid (${#VALID_CHAINS[@]}):${NC}"
        for chain in "${VALID_CHAINS[@]}"; do
            echo -e "  • $chain"
        done
    fi

    if [[ ${#MISMATCH_CHAINS[@]} -gt 0 ]]; then
        echo -e "\n${RED}✗ Mismatch (${#MISMATCH_CHAINS[@]}):${NC}"
        for chain in "${MISMATCH_CHAINS[@]}"; do
            echo -e "  • $chain"
        done
    fi

    if [[ ${#NEEDS_UPDATE_CHAINS[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}⚠ Needs Update (${#NEEDS_UPDATE_CHAINS[@]}):${NC}"
        for chain in "${NEEDS_UPDATE_CHAINS[@]}"; do
            echo -e "  • $chain"
        done
    fi

    if [[ ${#MISSING_CHAINS[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}⚠ Missing/Not Deployed (${#MISSING_CHAINS[@]}):${NC}"
        for chain in "${MISSING_CHAINS[@]}"; do
            echo -e "  • $chain"
        done
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ ${#MISMATCH_CHAINS[@]} -gt 0 || ${#NEEDS_UPDATE_CHAINS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}💡 To update configs, run: ${CYAN}just update-config${NC}"
else
    echo -e "${GREEN}✓ No action needed${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
