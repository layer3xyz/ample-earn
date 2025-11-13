// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {EulerEarnFactory} from "../EulerEarnFactory.sol";

import {IAmpleEarn} from "./interfaces/IAmpleEarn.sol";
import {IAmpleEarnFactory, VRFConfig} from "./interfaces/IAmpleEarnFactory.sol";
import {AmpleEventsLib} from "./libraries/AmpleEventsLib.sol";
import {AmpleEarn} from "./AmpleEarn.sol";

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

/// @title AmpleEarnFactory
/// @author Ample Money. Forked with gratitude from Euler Labs.
/// @custom:contact security@euler.xyz
/// @custom:contact security@ample.money
/// @notice This contract allows to create AmpleEarn vaults, and to index them easily.
contract AmpleEarnFactory is EulerEarnFactory, IAmpleEarnFactory {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTRUCTOR                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the contract.
    /// @param _owner The owner of the factory contract.
    /// @param _evc The address of the EVC contract.
    /// @param _permit2 The address of the Permit2 contract.
    /// @param _perspective The address of the supported perspective contract.
    constructor(address _owner, address _evc, address _permit2, address _perspective)
        EulerEarnFactory(_owner, _evc, _permit2, _perspective)
    {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EXTERNAL                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @inheritdoc IAmpleEarnFactory
    function createAmpleEarn(
        address initialOwner,
        uint256 initialTimelock,
        address asset,
        string memory name,
        string memory symbol,
        bytes32 salt,
        address vrfCoordinator,
        VRFConfig memory vrfConfig
    ) external returns (IAmpleEarn ampleEarn) {
        ampleEarn = IAmpleEarn(
            address(
                new AmpleEarn{salt: salt}(
                    initialOwner,
                    address(evc),
                    permit2Address,
                    initialTimelock,
                    asset,
                    name,
                    symbol,
                    vrfCoordinator,
                    vrfConfig
                )
            )
        );

        isVault[address(ampleEarn)] = true;

        vaultList.push(address(ampleEarn));

        emit AmpleEventsLib.CreateAmpleEarn(
            address(ampleEarn), _msgSender(), initialOwner, initialTimelock, asset, name, symbol, salt
        );
    }
}
