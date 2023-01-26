// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Liqqer.sol";

contract MyScript is Script {
    address me = address(0x00000000000E898D039D41D5aB37738F3aeD833D);

    address payable deployerPub =
        payable(0xAA71315346811b05dAeA534dFb541D0Aa37a6fC3);

    ILiqqer public liqqer = ILiqqer(0x000000000fb29E7B2e767c78B8b44987C3eD5610);

    address[] private _debtTokens = [
        0xdAC17F958D2ee523a2206206994597C13D831ec7,
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
        0x6B175474E89094C44Da98b954EedeAC495271d0F,
        0x514910771AF9Ca656af840dff83E8264EcF986CA,
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919,
        0x853d955aCEf822Db058eb8505911ED77F175b99e,
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
        0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72,
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B,
        0x111111111117dC0aa78b770fA6A738034120C302,
        0x5f98805A4E8be255a32880FDeC7F6728C6568bA0
    ];

    address[] private _collatTokens = [
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
        0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,
        0xE41d2489571d322189246DaFA5ebDe1F4699F498,
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9,
        0x0D8775F648430679A709E98d2b0Cb6250d2887EF,
        0x6B175474E89094C44Da98b954EedeAC495271d0F,
        0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c,
        0xdd974D5C2e2928deA5F71b9825b8b646686BD200,
        0x514910771AF9Ca656af840dff83E8264EcF986CA,
        0x0F5D2fB29fb7d3CFeE444a200298f468908cC942,
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,
        0x408e41876cCCDC0F92210600ef50372656052a38,
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
        0x0000000000085d4780B73119b644AE5ecd22b376,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
        0xD533a949740bb3306d119CC777fa900bA034cd52,
        0xba100000625a3754423978a60c9317c58a424e3D,
        0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272,
        0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b,
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
        0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72,
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B,
        0x111111111117dC0aa78b770fA6A738034120C302
    ];

    // Just deploys at sets owner to our efficient caller address
    function run() external {
        /* uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY"); */
        uint256 owner = vm.envUint("OWNER");

        /* vm.startBroadcast(moneybag);

        deployerPub.send(1 ether);
        vm.stopBroadcast(); */

        vm.startBroadcast(owner);

        for (uint256 i = 0; i < _debtTokens.length; i++) {
            liqqer.addApprovals(
                _debtTokens[i],
                0xDef1C0ded9bec7F1a1670819833240f027b25EfF
            );
        }

        for (uint256 i = 0; i < _collatTokens.length; i++) {
            liqqer.addApprovals(
                _collatTokens[i],
                0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9
            );
        }

        vm.stopBroadcast();
    }
}
