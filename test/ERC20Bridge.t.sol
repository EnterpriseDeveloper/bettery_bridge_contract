// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20Bridge.sol";
import "./MockERC20.sol";

contract ERC20BridgeTest is Test {
    ERC20Bridge bridge;
    MockERC20 token;

    address user = address(0x100);
    address evmRecipient = address(0x200);

    function setUp() public {
        bridge = new ERC20Bridge();

        token = new MockERC20();

        bridge.setSupportedToken(address(token), true);

        token.mint(user, 1000 ether);

        vm.startPrank(user);
        token.approve(address(bridge), type(uint256).max);
        vm.stopPrank();
    }

    // -----------------------------
    // LOCK TEST
    // -----------------------------

    function testLock() public {
        vm.prank(user);

        bridge.lock(address(token), 100 ether, "cosmos1abc...");

        assertEq(token.balanceOf(address(bridge)), 100 ether);
    }

    // -----------------------------
    // UNLOCK SUCCESS
    // -----------------------------

    function testUnlockSuccess() public {
        ERC20Bridge.Claim memory claim = ERC20Bridge.Claim({
            evmChainId: block.chainid,
            token: address(token),
            to: evmRecipient,
            amount: 50 ether,
            nonce: 1
        });

        token.mint(address(bridge), 50 ether);

        bridge.unlock(claim);

        assertEq(token.balanceOf(evmRecipient), 50 ether);
    }
}
