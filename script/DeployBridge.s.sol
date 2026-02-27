// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ERC20Bridge} from "../src/ERC20Bridge.sol";

contract DeployBridge is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        new ERC20Bridge();

        vm.stopBroadcast();
    }
}
