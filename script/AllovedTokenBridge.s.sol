// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ERC20Bridge} from "../src/ERC20Bridge.sol";

contract DeployBridge is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address bridgeAddr = vm.envAddress("POLYGON_TEST_CONTRACT_ADDR");
        address tokenAddr = vm.envAddress("POLYGON_TEST_TOKEN_ADDR");

        vm.startBroadcast(deployerKey);

        ERC20Bridge(bridgeAddr).setSupportedToken(tokenAddr, true);

        vm.stopBroadcast();
    }
}
