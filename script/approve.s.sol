// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Liqqer.sol";

contract MyScript is Script {
    address me = address(0x00000000000E898D039D41D5aB37738F3aeD833D);

    address payable deployerPub =
        payable(0xAA71315346811b05dAeA534dFb541D0Aa37a6fC3);

    ILiqqer public liqqer = ILiqqer(0x000000000fb29E7B2e767c78B8b44987C3eD5610);

    // Just deploys at sets owner to our efficient caller address
    function run() external {
        /* uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); */
        uint256 owner = vm.envUint("OWNER");

        /* vm.startBroadcast(moneybag);

        deployerPub.send(1 ether);
        vm.stopBroadcast(); */

        vm.startBroadcast(owner);

        liqqer.addApprovals(
            0x956F47F50A910163D8BF957Cf5846D573E7f87CA,
            0xDef1C0ded9bec7F1a1670819833240f027b25EfF
        );

        vm.stopBroadcast();
    }
}
