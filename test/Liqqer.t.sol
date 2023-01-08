// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Liqqer.sol";

contract LiqqerTest is Test {
    uint256 MAX_INT = 2**256 - 1;
    event cover(uint256);
    event bal(uint256);

    Liqqer public liqqer;

    ILiqqProvider private immutable DPROV =
        ILiqqProvider(0xA67BdecB3FB056F314Dcc76F3ACd3B3F936C52ca);

    address public me = 0x00000000000E898D039D41D5aB37738F3aeD833D;

    function setUp() public {
        vm.prank(0x039cDF7e3ad43816DAb9610a6A2cB2D05114406d);
        liqqer = new Liqqer(address(me));
    }

    function testflashLoan() public {
        address collateralA = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address debtA = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address user = 0x227cAa7eF6D955A92F483dB2BD01172997A1a623;

        ILiqqer.ZeroSwap[] memory swaps = new ILiqqer.ZeroSwap[](1);

        swaps[0] = ILiqqer.ZeroSwap({
            allowTarget: address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            swapTarget: payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            callData: hex"d9627aa400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000040c9768d0409b5000000000000000000000000000000000000000000000003065562d08ce1546000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000f5d2fb29fb7d3cfee444a200298f468908cc942869584cd0000000000000000000000001000000000000000000000000000000000000011000000000000000000000000000000000000000000000065e2addefe638ae1b1",
            isDebtSwap: true
        });

        ILiqqer.CallParams memory params;
        params = ILiqqer.CallParams({
            collatA: collateralA,
            debtA: debtA,
            userA: user,
            debtToCover: 17000000000000000000000,
            collatToReceive: 1,
            swaps: swaps
        });

        vm.prank(me);
        liqqer.flash_WaC(params);
    }
}
