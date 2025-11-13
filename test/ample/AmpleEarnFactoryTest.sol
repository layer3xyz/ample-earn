// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;

import {Ownable} from "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {EVCUtil} from "../../lib/ethereum-vault-connector/src/utils/EVCUtil.sol";
import "./helpers/IntegrationTest.sol";

contract AmpleEarnFactoryTest is IntegrationTest {
    function testFactoryAddressZero() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, (address(0))));
        new AmpleEarnFactory(address(0), address(evc), address(permit2), address(perspective));

        vm.expectRevert(EVCUtil.EVC_InvalidAddress.selector);
        new AmpleEarnFactory(admin, address(0), address(permit2), address(perspective));

        new AmpleEarnFactory(admin, address(evc), address(0), address(perspective));

        vm.expectRevert(ErrorsLib.ZeroAddress.selector);
        new AmpleEarnFactory(admin, address(evc), address(permit2), address(0));
    }

    function testCreateAmpleEarn(
        address initialOwner,
        uint256 initialTimelock,
        string memory name,
        string memory symbol,
        bytes32 salt
    ) public {
        vm.assume(address(initialOwner) != address(0));
        initialTimelock = _boundInitialTimelock(initialTimelock);

        VRFConfig memory vrfConfig = VRFConfig({
            subscriptionId: vrfSubscriptionId,
            keyHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
            callbackGasLimit: 100000,
            requestConfirmations: 3
        });

        bytes32 initCodeHash = hashInitCode(
            type(AmpleEarn).creationCode,
            abi.encode(
                initialOwner,
                address(evc),
                address(permit2),
                initialTimelock,
                address(loanToken),
                name,
                symbol,
                address(vrfCoordinator),
                vrfConfig
            )
        );
        address expectedAddress = computeCreate2Address(salt, initCodeHash, address(ampleEarnFactory));

        vm.expectEmit(address(ampleEarnFactory));
        emit AmpleEventsLib.CreateAmpleEarn(
            expectedAddress, address(this), initialOwner, initialTimelock, address(loanToken), name, symbol, salt
        );

        IAmpleEarn ampleEarn = ampleEarnFactory.createAmpleEarn(
            initialOwner, initialTimelock, address(loanToken), name, symbol, salt, address(vrfCoordinator), vrfConfig
        );

        assertEq(expectedAddress, address(ampleEarn), "computeCreate2Address");

        assertTrue(ampleEarnFactory.isVault(address(ampleEarn)), "isVault");

        assertEq(IOwnable(address(ampleEarn)).owner(), initialOwner, "owner");
        assertEq(address(IEulerEarn(address(ampleEarn)).EVC()), address(evc), "evc");
        assertEq(ampleEarn.timelock(), initialTimelock, "timelock");
        assertEq(ampleEarn.asset(), address(loanToken), "asset");
        assertEq(ampleEarn.name(), name, "name");
        assertEq(ampleEarn.symbol(), symbol, "symbol");
    }

    function testSupportedPerspective() public {
        assertEq(ampleEarnFactory.supportedPerspective(), address(perspective));

        address newPerspective = makeAddr("new perspective");
        vm.expectRevert();
        vm.prank(makeAddr("not admin"));
        ampleEarnFactory.setPerspective(newPerspective);

        vm.startPrank(admin);

        vm.expectRevert(ErrorsLib.ZeroAddress.selector);
        ampleEarnFactory.setPerspective(address(0));

        ampleEarnFactory.setPerspective(newPerspective);
        assertEq(ampleEarnFactory.supportedPerspective(), newPerspective);
    }

    function testIsStrategyAllowed() public {
        address newStrategy = makeAddr("new strategy");

        assertFalse(ampleEarnFactory.isStrategyAllowed(newStrategy));

        perspective.perspectiveVerify(newStrategy);

        assertTrue(ampleEarnFactory.isStrategyAllowed(newStrategy));
    }

    function testGetVaults() public {
        AmpleEarnFactory factory = new AmpleEarnFactory(admin, address(evc), address(permit2), address(perspective));

        uint256 amountVaults = 10;
        address[] memory vaultsList = new address[](amountVaults);

        for (uint256 i; i < amountVaults; i++) {
            address vault = address(
                factory.createAmpleEarn(
                    OWNER,
                    TIMELOCK,
                    address(loanToken),
                    "AmpleEarn Vault",
                    "EEV",
                    bytes32(uint256(i)),
                    address(vrfCoordinator),
                    VRFConfig({
                        subscriptionId: vrfSubscriptionId,
                        keyHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
                        callbackGasLimit: 100000,
                        requestConfirmations: 3
                    })
                )
            );
            vaultsList[i] = vault;
        }

        uint256 len = factory.getVaultListLength();

        assertEq(len, amountVaults);

        address[] memory listVaultsTest;
        address[] memory listFactory;

        // get all vaults
        uint256 startIndex = 0;
        uint256 endIndex = type(uint256).max;

        listFactory = factory.getVaultListSlice(startIndex, endIndex);

        listVaultsTest = vaultsList;

        assertEq(listFactory, listVaultsTest);

        //test getvaultsList(3, 10) - get [3,10) slice
        startIndex = 3;
        endIndex = 10;

        listFactory = factory.getVaultListSlice(startIndex, endIndex);

        listVaultsTest = new address[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            listVaultsTest[i - startIndex] = vaultsList[i];
        }

        assertEq(listFactory, listVaultsTest);

        vm.expectRevert(ErrorsLib.BadQuery.selector);
        factory.getVaultListSlice(endIndex, startIndex);

        vm.expectRevert(ErrorsLib.BadQuery.selector);
        factory.getVaultListSlice(startIndex, endIndex + 1);
    }
}
