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
echo -e "${BLUE}  Ample Chain Config Updater${NC}"
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
declare -a UPDATED_CHAINS=()
declare -a UPDATED_DETAILS=()  # Parallel array to store update details
declare -a NO_UPDATE_CHAINS=()
declare -a MISSING_CHAINS=()

update_chain() {
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

    local updated=false
    local update_details=""

    # Get current values before update
    local config_evc=$(grep -oE 'evc: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")
    local config_permit2=$(grep -oE 'permit2: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")
    local config_perspective=$(grep -oE 'evkFactoryPerspective: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")
    local config_factory=$(grep -oE 'eulerEarnFactory: (address\()?0x[0-9a-fA-F]{40}' "$config_path" | grep -oE '0x[0-9a-fA-F]{40}' | head -1 || echo "")

    # Update EVC
    if [[ -n "$euler_evc" ]]; then
        if [[ -z "$config_evc" ]] || [[ "$config_evc" == "0x0000000000000000000000000000000000000000" ]] || grep -q 'evc: address(0)' "$config_path"; then
            echo -e "  ${YELLOW}Updating EVC...${NC}"
            sed -i.bak "s|evc: address(0)|evc: $euler_evc|g" "$config_path"
            sed -i.bak "s|evc: 0x[0-9a-fA-F]*,|evc: $euler_evc,|g" "$config_path"
            echo -e "  ${GREEN}✓ EVC updated: ${YELLOW}NOT SET${GREEN} → ${CYAN}$euler_evc${NC}"
            update_details+="    • EVC: NOT SET → $euler_evc\n"
            updated=true
        elif [[ "$config_evc" != "$euler_evc" ]]; then
            echo -e "  ${YELLOW}Updating EVC (mismatch)...${NC}"
            sed -i.bak "s|evc: $config_evc|evc: $euler_evc|g" "$config_path"
            echo -e "  ${GREEN}✓ EVC updated: ${RED}$config_evc${GREEN} → ${CYAN}$euler_evc${NC}"
            update_details+="    • EVC: $config_evc → $euler_evc\n"
            updated=true
        else
            echo -e "  ${GREEN}✓ EVC already correct${NC}"
        fi
    fi

    # Update Permit2
    if [[ -n "$euler_permit2" ]]; then
        if [[ -z "$config_permit2" ]] || [[ "$config_permit2" == "0x0000000000000000000000000000000000000000" ]]; then
            echo -e "  ${YELLOW}Updating Permit2...${NC}"
            sed -i.bak "s|permit2: 0x[0-9a-fA-F]*,|permit2: $euler_permit2,|g" "$config_path"
            echo -e "  ${GREEN}✓ Permit2 updated: ${YELLOW}NOT SET${GREEN} → ${CYAN}$euler_permit2${NC}"
            update_details+="    • Permit2: NOT SET → $euler_permit2\n"
            updated=true
        elif [[ "$config_permit2" != "$euler_permit2" ]]; then
            echo -e "  ${YELLOW}Updating Permit2 (mismatch)...${NC}"
            sed -i.bak "s|permit2: $config_permit2|permit2: $euler_permit2|g" "$config_path"
            echo -e "  ${GREEN}✓ Permit2 updated: ${RED}$config_permit2${GREEN} → ${CYAN}$euler_permit2${NC}"
            update_details+="    • Permit2: $config_permit2 → $euler_permit2\n"
            updated=true
        else
            echo -e "  ${GREEN}✓ Permit2 already correct${NC}"
        fi
    fi

    # Update Perspective
    if [[ -n "$euler_perspective" ]]; then
        if [[ -z "$config_perspective" ]] || [[ "$config_perspective" == "0x0000000000000000000000000000000000000000" ]] || grep -q 'evkFactoryPerspective: address(0)' "$config_path"; then
            echo -e "  ${YELLOW}Updating Perspective...${NC}"
            sed -i.bak "s|evkFactoryPerspective: address(0)|evkFactoryPerspective: $euler_perspective|g" "$config_path"
            sed -i.bak "s|evkFactoryPerspective: 0x[0-9a-fA-F]*,|evkFactoryPerspective: $euler_perspective,|g" "$config_path"
            echo -e "  ${GREEN}✓ Perspective updated: ${YELLOW}NOT SET${GREEN} → ${CYAN}$euler_perspective${NC}"
            update_details+="    • Perspective: NOT SET → $euler_perspective\n"
            updated=true
        elif [[ "$config_perspective" != "$euler_perspective" ]]; then
            echo -e "  ${YELLOW}Updating Perspective (mismatch)...${NC}"
            sed -i.bak "s|evkFactoryPerspective: $config_perspective|evkFactoryPerspective: $euler_perspective|g" "$config_path"
            echo -e "  ${GREEN}✓ Perspective updated: ${RED}$config_perspective${GREEN} → ${CYAN}$euler_perspective${NC}"
            update_details+="    • Perspective: $config_perspective → $euler_perspective\n"
            updated=true
        else
            echo -e "  ${GREEN}✓ Perspective already correct${NC}"
        fi
    fi

    # Update Euler Earn Factory
    if [[ -n "$euler_factory" ]]; then
        if [[ -z "$config_factory" ]] || [[ "$config_factory" == "0x0000000000000000000000000000000000000000" ]] || grep -q 'eulerEarnFactory: address(0)' "$config_path"; then
            echo -e "  ${YELLOW}Updating Euler Earn Factory...${NC}"
            sed -i.bak "s|eulerEarnFactory: address(0)|eulerEarnFactory: $euler_factory|g" "$config_path"
            sed -i.bak "s|eulerEarnFactory: 0x[0-9a-fA-F]*,|eulerEarnFactory: $euler_factory,|g" "$config_path"
            echo -e "  ${GREEN}✓ Euler Earn Factory updated: ${YELLOW}NOT SET${GREEN} → ${CYAN}$euler_factory${NC}"
            update_details+="    • Euler Earn Factory: NOT SET → $euler_factory\n"
            updated=true
        elif [[ "$config_factory" != "$euler_factory" ]]; then
            echo -e "  ${YELLOW}Updating Euler Earn Factory (mismatch)...${NC}"
            sed -i.bak "s|eulerEarnFactory: $config_factory|eulerEarnFactory: $euler_factory|g" "$config_path"
            echo -e "  ${GREEN}✓ Euler Earn Factory updated: ${RED}$config_factory${GREEN} → ${CYAN}$euler_factory${NC}"
            update_details+="    • Euler Earn Factory: $config_factory → $euler_factory\n"
            updated=true
        else
            echo -e "  ${GREEN}✓ Euler Earn Factory already correct${NC}"
        fi
    fi

    # Clean up backup file
    rm -f "$config_path.bak"

    if [[ "$updated" == true ]]; then
        UPDATED_CHAINS+=("$chain_name")
        UPDATED_DETAILS+=("$update_details")
        echo -e "  ${GREEN}✓ Config updated successfully${NC}"
    else
        NO_UPDATE_CHAINS+=("$chain_name")
        echo -e "  ${BLUE}ℹ No updates needed${NC}"
    fi

    echo ""
}

# Update all chains
update_chain 42161 "Arbitrum" "Arbitrum.sol"
update_chain 43114 "Avalanche" "Avalanche.sol"
update_chain 8453 "Base" "Base.sol"
update_chain 80094 "Berachain" "Berachain.sol"
update_chain 60808 "BOB" "BOB.sol"
update_chain 56 "BSC" "BSC.sol"
update_chain 1 "Ethereum" "Ethereum.sol"
update_chain 999 "HyperEVM" "HyperEVM.sol"
update_chain 59144 "Linea" "Linea.sol"
update_chain 143 "Monad" "Monad.sol"
update_chain 9745 "Plasma" "Plasma.sol"
update_chain 146 "Sonic" "Sonic.sol"
update_chain 1923 "Swell" "Swell.sol"
update_chain 239 "TAC" "TAC.sol"
update_chain 130 "Unichain" "Unichain.sol"

# Display summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

total_chains=$((${#UPDATED_CHAINS[@]} + ${#NO_UPDATE_CHAINS[@]} + ${#MISSING_CHAINS[@]}))

if [[ ${#UPDATED_CHAINS[@]} -eq 0 ]]; then
    echo -e "${GREEN}✨ No updates needed - all chains are up to date! ($total_chains/$total_chains)${NC}"
else
    echo -e "${YELLOW}Processed $total_chains chains:${NC}"

    if [[ ${#UPDATED_CHAINS[@]} -gt 0 ]]; then
        echo -e "\n${GREEN}✓ Updated (${#UPDATED_CHAINS[@]}):${NC}"
        for i in "${!UPDATED_CHAINS[@]}"; do
            echo -e "  ${CYAN}${UPDATED_CHAINS[$i]}:${NC}"
            echo -e "${UPDATED_DETAILS[$i]}"
        done
    fi

    if [[ ${#NO_UPDATE_CHAINS[@]} -gt 0 ]]; then
        echo -e "${BLUE}ℹ Already Up-to-Date (${#NO_UPDATE_CHAINS[@]}):${NC}"
        for chain in "${NO_UPDATE_CHAINS[@]}"; do
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
if [[ ${#UPDATED_CHAINS[@]} -gt 0 ]]; then
    echo -e "${GREEN}✨ Config update complete - ${#UPDATED_CHAINS[@]} chain(s) updated${NC}"
    echo -e "${YELLOW}💡 Run ${CYAN}just check-config${YELLOW} to verify changes${NC}"
else
    echo -e "${GREEN}✓ All configs are already up to date${NC}"
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
