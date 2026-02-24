// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20Bridge.sol";
import "./MockERC20.sol";

contract ERC20BridgeTest is Test {

    ERC20Bridge bridge;
    MockERC20 token;

    uint256 relayer1Pk = 1;
    uint256 relayer2Pk = 2;
    uint256 relayer3Pk = 3;

    address relayer1;
    address relayer2;
    address relayer3;

    address user = address(0x100);
    address evmRecipient = address(0x200);

    function setUp() public {

        relayer1 = vm.addr(relayer1Pk);
        relayer2 = vm.addr(relayer2Pk);
        relayer3 = vm.addr(relayer3Pk);

        bridge = new ERC20Bridge(
            2,              // threshold
            address(this)   // owner
        );

        bridge.addRelayer(relayer1);
        bridge.addRelayer(relayer2);
        bridge.addRelayer(relayer3);

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

        bridge.lock(
            address(token),
            100 ether,
            "cosmos1abc..."
        );

        assertEq(token.balanceOf(address(bridge)), 100 ether);
    }

    // -----------------------------
    // UNLOCK SUCCESS
    // -----------------------------

    function testUnlockSuccess() public {

        ERC20Bridge.Claim memory claim =
            ERC20Bridge.Claim({
                evmChainId: block.chainid,
                token: address(token),
                to: evmRecipient,
                amount: 50 ether,
                nonce: 1
            });

        bytes32 hash = bridge.getMessageHash(claim);
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        (uint8 v1, bytes32 r1, bytes32 s1) =
            vm.sign(relayer1Pk, ethSignedHash);

        (uint8 v2, bytes32 r2, bytes32 s2) =
            vm.sign(relayer2Pk, ethSignedHash);

        bytes;

        sigs[0] = abi.encodePacked(r1, s1, v1);
        sigs[1] = abi.encodePacked(r2, s2, v2);

        token.mint(address(bridge), 50 ether);

        bridge.unlock(claim, sigs);

        assertEq(token.balanceOf(evmRecipient), 50 ether);
    }

    // -----------------------------
    // UNLOCK FAIL - NOT ENOUGH SIGS
    // -----------------------------

    function testUnlockFailNotEnoughSignatures() public {

        ERC20Bridge.Claim memory claim =
            ERC20Bridge.Claim({
                evmChainId: block.chainid,
                token: address(token),
                to: evmRecipient,
                amount: 50 ether,
                nonce: 2
            });

        bytes32 hash = bridge.getMessageHash(claim);
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        (uint8 v1, bytes32 r1, bytes32 s1) =
            vm.sign(relayer1Pk, ethSignedHash);

        bytes;
        sigs[0] = abi.encodePacked(r1, s1, v1);

        token.mint(address(bridge), 50 ether);

        vm.expectRevert("not enough signatures");

        bridge.unlock(claim, sigs);
    }

    // -----------------------------
    // UNLOCK FAIL - REPLAY
    // -----------------------------

    function testUnlockReplayFails() public {

        ERC20Bridge.Claim memory claim =
            ERC20Bridge.Claim({
                evmChainId: block.chainid,
                token: address(token),
                to: evmRecipient,
                amount: 50 ether,
                nonce: 3
            });

        bytes32 hash = bridge.getMessageHash(claim);
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        (uint8 v1, bytes32 r1, bytes32 s1) =
            vm.sign(relayer1Pk, ethSignedHash);

        (uint8 v2, bytes32 r2, bytes32 s2) =
            vm.sign(relayer2Pk, ethSignedHash);

        bytes;

        sigs[0] = abi.encodePacked(r1, s1, v1);
        sigs[1] = abi.encodePacked(r2, s2, v2);

        token.mint(address(bridge), 50 ether);

        bridge.unlock(claim, sigs);

        vm.expectRevert("already processed");

        bridge.unlock(claim, sigs);
    }
}