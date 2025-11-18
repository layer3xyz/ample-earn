// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import {console} from "forge-std/console.sol";
import {StdChains} from "forge-std/StdChains.sol";

import {BaseScript} from "./BaseScript.s.sol";

// Contracts
import {AmpleEarnFactory} from "../../src/ample/AmpleEarnFactory.sol";
import {IAmpleEarn} from "../../src/ample/interfaces/IAmpleEarn.sol";
import {VRFConfig} from "../../src/ample/interfaces/IAmpleDraw.sol";

// Chain configs
import {ChainConfig} from "./config/ChainConfig.sol";
import {ArbitrumConfig} from "./config/mainnet/Arbitrum.sol";
import {AvalancheConfig} from "./config/mainnet/Avalanche.sol";
import {BaseConfig} from "./config/mainnet/Base.sol";
import {BerachainConfig} from "./config/mainnet/Berachain.sol";
import {BOBConfig} from "./config/mainnet/BOB.sol";
import {BSCConfig} from "./config/mainnet/BSC.sol";
import {EthereumConfig} from "./config/mainnet/Ethereum.sol";
import {HyperEVMConfig} from "./config/mainnet/HyperEVM.sol";
import {LineaConfig} from "./config/mainnet/Linea.sol";
import {MonadConfig} from "./config/mainnet/Monad.sol";
import {PlasmaConfig} from "./config/mainnet/Plasma.sol";
import {SonicConfig} from "./config/mainnet/Sonic.sol";
import {SwellConfig} from "./config/mainnet/Swell.sol";
import {TACConfig} from "./config/mainnet/TAC.sol";
import {UnichainConfig} from "./config/mainnet/Unichain.sol";

/*
                                   /$$
                                  | $$
  /$$$$$$  /$$$$$$/$$$$   /$$$$$$ | $$  /$$$$$$
 |____  $$| $$_  $$_  $$ /$$__  $$| $$ /$$__  $$
  /$$$$$$$| $$ \ $$ \ $$| $$  \ $$| $$| $$$$$$$$
 /$$__  $$| $$ | $$ | $$| $$  | $$| $$| $$_____/
|  $$$$$$$| $$ | $$ | $$| $$$$$$$/| $$|  $$$$$$$
 \_______/|__/ |__/ |__/| $$____/ |__/ \_______/
                        | $$
                        | $$
                        |__/
*/

/// @title Deploy
/// @notice Deployment script for Ample Money contracts
/// @dev Environment variables:
///      Optional (for creating a vault):
///        - CREATE_VAULT: Set to "true" to deploy a vault via factory
///        - VAULT_OWNER: Owner of the vault (defaults to broadcaster)
///        - TIMELOCK: Initial timelock in seconds (defaults to 7 days)
///        - ASSET: Address of the underlying asset
///        - VAULT_NAME: Name of the vault (e.g., "Ample USDC")
///        - VAULT_SYMBOL: Symbol of the vault (e.g., "aUSDC")
///        - VRF_SUBSCRIPTION_ID: Chainlink VRF subscription ID (required if CREATE_VAULT=true)
contract DeployScript is BaseScript {
    // Factory deployment addresses
    AmpleEarnFactory public factory;
    IAmpleEarn public vault;

    function run() external broadcast {
        console.log("\n=== Deploying Ample Money Contracts ===");
        console.log(
            string.concat("Chain: ", StdChains.getChain(block.chainid).name, " (", vm.toString(block.chainid), ")")
        );
        console.log("Broadcaster:", broadcaster);

        ChainConfig memory config = _getChainConfig();
        console.log("\n=== Protocol Config ===");
        console.log("EVC:", config.evc);
        console.log("Permit2:", config.permit2);
        console.log("EVK Factory Perspective:", config.evkFactoryPerspective);

        console.log("\nVerify protocol addresses here: https://docs.euler.finance/developers/contract-addresses/");

        console.log("\n=== VRF Config ===");
        console.log("VRF Coordinator:", config.vrfCoordinator);
        console.log("VRF Key Hash:");
        console.logBytes32(config.vrfConfig.keyHash);
        console.log("VRF Callback Gas Limit:", config.vrfConfig.callbackGasLimit);
        console.log("VRF Request Confirmations:", config.vrfConfig.requestConfirmations);

        console.log("\nVerify chainlink config here: https://vrf.chain.link/");

        // Deploy factory
        _deployFactory(config);

        // Optionally create a vault
        if (vm.envOr("CREATE_VAULT", false)) {
            _createVault();
        }

        console.log("\n=== Deployment Complete ===\n");
    }

    function _deployFactory(ChainConfig memory config) internal {
        console.log("\n=== Deploying AmpleEarnFactory ===");
        console.log("Factory Owner:", broadcaster);

        factory = new AmpleEarnFactory(broadcaster, config.evc, config.permit2, config.evkFactoryPerspective);

        console.log("AmpleEarnFactory deployed at:", address(factory));
    }

    function _createVault() internal {
        console.log("\n--- Creating AmpleEarn Vault ---");

        ChainConfig memory config = _getChainConfig();

        address vaultOwner = vm.envOr("VAULT_OWNER", broadcaster);
        uint256 timelock = vm.envOr("TIMELOCK", uint256(7 days));
        address asset = vm.envAddress("ASSET");
        string memory name = vm.envString("VAULT_NAME");
        string memory symbol = vm.envString("VAULT_SYMBOL");

        console.log("Vault Owner:", vaultOwner);
        console.log("Timelock:", timelock);
        console.log("Asset:", asset);
        console.log("Name:", name);
        console.log("Symbol:", symbol);
        console.log("VRF Coordinator:", config.vrfCoordinator);
        console.log("VRF Subscription ID:", config.vrfConfig.subscriptionId);
        console.log("VRF Key Hash:");
        console.logBytes32(config.vrfConfig.keyHash);
        console.log("VRF Callback Gas Limit:", config.vrfConfig.callbackGasLimit);
        console.log("VRF Request Confirmations:", config.vrfConfig.requestConfirmations);

        vault = factory.createAmpleEarn(
            vaultOwner, timelock, asset, name, symbol, ZERO_SALT, config.vrfCoordinator, config.vrfConfig
        );

        console.log("AmpleEarn vault deployed at:", address(vault));
        console.log("AmpleDraw deployed at:", vault.prizeDraw());

        console.log("\n--- Vault Details ---");
        console.log("Asset:", vault.asset());
        console.log("Name:", vault.name());
        console.log("Symbol:", vault.symbol());
    }

    function _getChainConfig() internal view returns (ChainConfig memory) {
        uint256 chainId = block.chainid;

        if (chainId == ArbitrumConfig.CHAIN_ID) return _verifyChainConfig(ArbitrumConfig.getConfig());
        if (chainId == AvalancheConfig.CHAIN_ID) return _verifyChainConfig(AvalancheConfig.getConfig());
        if (chainId == BaseConfig.CHAIN_ID) return _verifyChainConfig(BaseConfig.getConfig());
        if (chainId == BerachainConfig.CHAIN_ID) return _verifyChainConfig(BerachainConfig.getConfig());
        if (chainId == BOBConfig.CHAIN_ID) return _verifyChainConfig(BOBConfig.getConfig());
        if (chainId == BSCConfig.CHAIN_ID) return _verifyChainConfig(BSCConfig.getConfig());
        if (chainId == EthereumConfig.CHAIN_ID) return _verifyChainConfig(EthereumConfig.getConfig());
        if (chainId == HyperEVMConfig.CHAIN_ID) return _verifyChainConfig(HyperEVMConfig.getConfig());
        if (chainId == LineaConfig.CHAIN_ID) return _verifyChainConfig(LineaConfig.getConfig());
        if (chainId == MonadConfig.CHAIN_ID) return _verifyChainConfig(MonadConfig.getConfig());
        if (chainId == PlasmaConfig.CHAIN_ID) return _verifyChainConfig(PlasmaConfig.getConfig());
        if (chainId == SonicConfig.CHAIN_ID) return _verifyChainConfig(SonicConfig.getConfig());
        if (chainId == SwellConfig.CHAIN_ID) return _verifyChainConfig(SwellConfig.getConfig());
        if (chainId == TACConfig.CHAIN_ID) return _verifyChainConfig(TACConfig.getConfig());
        if (chainId == UnichainConfig.CHAIN_ID) return _verifyChainConfig(UnichainConfig.getConfig());

        revert("Unsupported chain ID");
    }

    function _verifyChainConfig(ChainConfig memory config) internal pure returns (ChainConfig memory) {
        require(config.evc != address(0), "EVC address is not set");
        require(config.permit2 != address(0), "Permit2 address is not set");
        require(config.evkFactoryPerspective != address(0), "Perspective address is not set");
        require(config.vrfCoordinator != address(0), "VRF Coordinator address is not set");
        require(config.vrfConfig.subscriptionId != 0, "VRF Subscription ID is not set");
        require(config.vrfConfig.keyHash != bytes32(0), "VRF Key Hash is not set");
        require(config.vrfConfig.callbackGasLimit != 0, "VRF Callback Gas Limit is not set");
        require(config.vrfConfig.requestConfirmations != 0, "VRF Request Confirmations is not set");
        return config;
    }
}
