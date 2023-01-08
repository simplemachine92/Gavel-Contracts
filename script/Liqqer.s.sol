// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Liqqer.sol";

contract MyScript is Script {
    address me = address(0x00000000000E898D039D41D5aB37738F3aeD833D);

    // Just deploys at sets owner to our efficient caller address
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Liqqer liqqer = new Liqqer(me);

        vm.stopBroadcast();
    }
}
