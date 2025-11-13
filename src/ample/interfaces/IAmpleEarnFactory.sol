// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {IEulerEarnFactory} from "../../interfaces/IEulerEarnFactory.sol";

import {VRFConfig} from "./IAmpleDraw.sol";
import {IAmpleEarn} from "./IAmpleEarn.sol";

interface IAmpleEarnFactory is IEulerEarnFactory {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EXTERNAL                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Creates a new AmpleEarn vault.
    /// @param initialOwner The owner of the vault.
    /// @param initialTimelock The initial timelock of the vault.
    /// @param asset The address of the underlying asset.
    /// @param name The name of the vault.
    /// @param symbol The symbol of the vault.
    /// @param salt The salt to use for the AmpleEarn vault's CREATE2 address.
    function createAmpleEarn(
        address initialOwner,
        uint256 initialTimelock,
        address asset,
        string memory name,
        string memory symbol,
        bytes32 salt,
        address vrfCoordinator,
        VRFConfig memory vrfConfig
    ) external returns (IAmpleEarn ampleEarn);
}
