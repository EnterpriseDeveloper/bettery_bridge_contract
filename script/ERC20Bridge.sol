// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ERC20Bridge} from "../src/ERC20Bridge.sol";

contract DeployBridge is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        ERC20Bridge bridge = new ERC20Bridge(2);

        // bridge.addRelayer(0xRelayer1); TODO
        // bridge.addRelayer(0xRelayer2); TODO
        // bridge.addRelayer(0xRelayer3); TODO

        vm.stopBroadcast();
    }
}
