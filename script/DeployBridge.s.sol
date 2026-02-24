// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ERC20Bridge} from "../src/ERC20Bridge.sol";

contract DeployBridge is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 relayer1 = vm.envUint("PUBLIC_KEY_RALAYER_1");
        address relayer1Addr = vm.addr(relayer1);

        uint256 relayer2 = vm.envUint("PUBLIC_KEY_RALAYER_2");
        address relayer2Addr = vm.addr(relayer2);
        uint256 relayer3 = vm.envUint("PUBLIC_KEY_RALAYER_3");
        address relayer3Addr = vm.addr(relayer3);

        vm.startBroadcast(deployerKey);

        ERC20Bridge bridge = new ERC20Bridge(2);

        bridge.addRelayer(relayer1Addr);
        bridge.addRelayer(relayer2Addr);
        bridge.addRelayer(relayer3Addr);

        vm.stopBroadcast();
    }
}
