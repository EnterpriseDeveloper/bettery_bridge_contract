// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/TestToken.sol";

contract DeployToken is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        TestToken token = new TestToken(vm.addr(deployerKey));

        vm.stopBroadcast();
    }
}
