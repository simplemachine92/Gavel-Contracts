// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Liqqer.sol";

contract LiqqerTest is Test {
    uint256 MAX_INT = 2**256 - 1;
    event cover(uint256);
    event bal(uint256);

    Liqqer public liqqer;
    IWETH private immutable WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IQuoter private immutable QUOTER =
        IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    IAaveDataProvider private immutable DATA =
        IAaveDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    ILiqqProvider private immutable DPROV =
        ILiqqProvider(0xA67BdecB3FB056F314Dcc76F3ACd3B3F936C52ca);

    ISoloMargin private immutable soloMargin =
        ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    address public me = 0x00000000000E898D039D41D5aB37738F3aeD833D;

    function setUp() public {
        vm.prank(0x039cDF7e3ad43816DAb9610a6A2cB2D05114406d);
        liqqer = new Liqqer(address(me));
        // Address with weth
        vm.prank(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e);
        // Give ourselves fee amount to cover for a single flash
        WETH.transfer(address(liqqer), 2 wei);
    }

    function testflashLoan(uint256 x) public {
        address collateralA = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address debtA = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
        address user = 0x227cAa7eF6D955A92F483dB2BD01172997A1a623;

        ILiqqer.ZeroSwap[] memory swaps = new ILiqqer.ZeroSwap[](2);

        swaps[0] = ILiqqer.ZeroSwap({
            allowTarget: address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            swapTarget: payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            callData: hex"d9627aa400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000040c9768d0409b5000000000000000000000000000000000000000000000003065562d08ce1546000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000f5d2fb29fb7d3cfee444a200298f468908cc942869584cd0000000000000000000000001000000000000000000000000000000000000011000000000000000000000000000000000000000000000065e2addefe638ae1b1",
            isDebtSwap: true
        });

        swaps[1] = ILiqqer.ZeroSwap({
            allowTarget: address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            swapTarget: payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            callData: hex"d9627aa400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000014fd874688987343700000000000000000000000000000000000000000000000000422b20143b0b81000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2869584cd000000000000000000000000100000000000000000000000000000000000001100000000000000000000000000000000000000000000007d4e538936638ae1b2",
            isDebtSwap: false
        });

        ILiqqer.CallParams memory params;
        params = ILiqqer.CallParams({
            collatA: collateralA,
            debtA: debtA,
            userA: user,
            swaps: swaps
        });

        (
            uint256 Ddebt,
            uint256 DcollatReceived,
            string memory errorcode
        ) = DPROV.liquidationCallData(collateralA, debtA, user, MAX_INT, false);

        vm.prank(me);
        liqqer.flashLoan_UNy(18235909518657973, params);

        IERC20 TOKEN1 = IERC20(debtA);
        IERC20 TOKEN2 = IERC20(collateralA);
        emit bal(WETH.balanceOf(address(liqqer)));
        emit bal(TOKEN1.balanceOf(address(liqqer)));
        emit bal(TOKEN2.balanceOf(address(liqqer)));
    }

    /* function testMaliciousUser() public {
        address collateralA = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address debtA = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
        address user = 0x227cAa7eF6D955A92F483dB2BD01172997A1a623;

        (
            uint256 Ddebt,
            uint256 DcollatReceived,
            string memory errorcode
        ) = DPROV.liquidationCallData(collateralA, debtA, user, MAX_INT, false);
        console.log(Ddebt);
        console.log(DcollatReceived);

        ILiqqer.ZeroSwap[] memory swaps = new ILiqqer.ZeroSwap[](2);

        swaps[0] = ILiqqer.ZeroSwap({
            allowTarget: address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            swapTarget: payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            callData: hex"6af479b20000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000004222b9c4fbb9b20000000000000000000000000000000000000000000000031813d3676843a2ec0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002bc02aaa39b223fe8d0a0e5c4f27ead9083c756cc20027100f5d2fb29fb7d3cfee444a200298f468908cc942000000000000000000000000000000000000000000869584cd00000000000000000000000010000000000000000000000000000000000000110000000000000000000000000000000000000000000000e21f4abdc66389dbf5",
            isDebtSwap: true
        });

        swaps[1] = ILiqqer.ZeroSwap({
            allowTarget: address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            swapTarget: payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            callData: hex"d9627aa400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000014fd6194af0843e3400000000000000000000000000000000000000000000000000426a93304a980d000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2869584cd00000000000000000000000010000000000000000000000000000000000000110000000000000000000000000000000000000000000000221d1c817c6389dc28",
            isDebtSwap: false
        });

        ILiqqer.CallParams memory params;
        params = ILiqqer.CallParams({
            collatA: collateralA,
            debtA: debtA,
            userA: user,
            swaps: swaps
        });

        bytes memory callP = abi.encode(params);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner: address(liqqer), number: 1});

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 10 ether
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(liqqer),
            otherAccountId: 0,
            data: ""
        });

        operations[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.Call,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(liqqer),
            otherAccountId: 0,
            data: abi.encode(callP)
        });

        operations[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 10 ether + 2
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(liqqer),
            otherAccountId: 0,
            data: ""
        });
        vm.prank(me);
        soloMargin.operate(accountInfos, operations);

       
    } */

    /* function testMaliciousUser2() public {
        address collateralA = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        address debtA = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
        address user = 0x227cAa7eF6D955A92F483dB2BD01172997A1a623;

        ILiqqer.ZeroSwap[] memory swaps = new ILiqqer.ZeroSwap[](2);

        swaps[0] = ILiqqer.ZeroSwap({
            allowTarget: address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            swapTarget: payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            callData: hex"d9627aa40000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000004184be11e8908e0000000000000000000000000000000000000000000000031b310c9ba02eb81800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000f5d2fb29fb7d3cfee444a200298f468908cc942869584cd00000000000000000000000010000000000000000000000000000000000000110000000000000000000000000000000000000000000000ed73299a1a63870ba6",
            isDebtSwap: true
        });

        swaps[1] = ILiqqer.ZeroSwap({
            allowTarget: address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            swapTarget: payable(0xDef1C0ded9bec7F1a1670819833240f027b25EfF),
            callData: hex"d9627aa400000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000014fcfa32b07dd59c10000000000000000000000000000000000000000000000000042ec6f0ae090e1000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000006b175474e89094c44da98b954eedeac495271d0f000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2869584cd000000000000000000000000100000000000000000000000000000000000001100000000000000000000000000000000000000000000005819178b2463870ba7",
            isDebtSwap: false
        });

        ILiqqer.CallParams memory params;
        params = ILiqqer.CallParams({
            collatA: collateralA,
            debtA: debtA,
            userA: user,
            swaps: swaps
        });

        bytes memory callP = abi.encode(params);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner: address(this), number: 1});

        liqqer.callFunction(address(liqqer), accountInfos[0], callP);
    } */
}
