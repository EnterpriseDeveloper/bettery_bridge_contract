// script/MintToken.s.sol

pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/TestToken.sol";

contract MintToken is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("POLYGON_TEST_TOKEN_ADDR");

        vm.startBroadcast(deployerKey);

        TestToken(tokenAddress).mint(vm.addr(deployerKey), 1_000_000 ether);

        vm.stopBroadcast();
    }
}
