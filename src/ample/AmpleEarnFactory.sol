// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {EulerEarnFactory} from "../EulerEarnFactory.sol";

import {IAmpleEarn} from "./interfaces/IAmpleEarn.sol";
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
contract AmpleEarnFactory is EulerEarnFactory {
    constructor(address _owner, address _evc, address _permit2, address _perspective)
        EulerEarnFactory(_owner, _evc, _permit2, _perspective)
    {}

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
        bytes32 salt
    ) external returns (IAmpleEarn ampleEarn) {
        ampleEarn = IAmpleEarn(
            address(
                new AmpleEarn{salt: salt}(
                    initialOwner, address(evc), permit2Address, initialTimelock, asset, name, symbol
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
