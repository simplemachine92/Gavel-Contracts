// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./utils/Margin.sol";
import "./utils/IEuler.sol";
import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

error LiqCallFailed();
error SwapCallFailed();
error SafeTxFailed();
error WithdrawFailed();
error UnAuthorized();
error UnAuthOrigin();

contract Liqqer is Owned {
    using SafeERC20 for IERC20;

    uint256 MAX_INT = 2**256 - 1;

    ILendingPool private immutable AAVE =
        ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    address private immutable zeroX =
        0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    address private immutable mySafe =
        0x3224C6C9BCA033CAbB85A36891EBf994732d8f23;

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
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
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
        0x956F47F50A910163D8BF957Cf5846D573E7f87CA,
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
        0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72,
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B,
        0x111111111117dC0aa78b770fA6A738034120C302
    ];

    constructor(address _owner) Owned(_owner) {
        for (uint256 i = 0; i < _debtTokens.length; i++) {
            IERC20 DTOKEN = IERC20(_debtTokens[i]);
            DTOKEN.safeApprove(address(AAVE), MAX_INT);
        }

        for (uint256 g = 0; g < _collatTokens.length; g++) {
            IERC20 CTOKEN = IERC20(_collatTokens[g]);
            CTOKEN.safeApprove(address(zeroX), MAX_INT);
        }
    }

    function flash_WaC(ILiqqer.CallParams calldata params) external onlyOwner {
        IEulerDToken dToken = IEulerDToken(
            EulerAddrsMainnet.markets.underlyingToDToken(params.debtA)
        );
        dToken.flashLoan(params.debtToCover, abi.encode(params));
    }

    function onFlashLoan(bytes calldata data) external {
        require(msg.sender == address(EulerAddrsMainnet.euler), "not allowed");
        // We still need this to protect our funds, but we can't set tx.origin in forge tests
        /* if (tx.origin != owner) revert UnAuthOrigin(); */

        ILiqqer.CallParams memory params = abi.decode(
            data,
            (ILiqqer.CallParams)
        );

        AAVE.liquidationCall(
            params.collatA,
            params.debtA,
            params.userA,
            params.debtToCover,
            false
        );

        (bool success, ) = params.swaps[0].swapTarget.call(
            params.swaps[0].callData
        );
        if (!success) revert SwapCallFailed();

        IERC20(params.debtA).transfer(msg.sender, params.debtToCover); // repay
    }

    function withdrawDust(address[] calldata _tokens, address _dst)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _tokens.length; ) {
            IERC20 TOKEN = IERC20(_tokens[i]);
            TOKEN.transfer(_dst, TOKEN.balanceOf(address(this)));

            unchecked {
                i++;
            }
        }
    }

    function withdraw(address _dst) external onlyOwner {
        (bool sent, ) = _dst.call{value: address(this).balance}("");
        if (!sent) revert WithdrawFailed();
    }

    function addApprovals(address _token, address _guy) external onlyOwner {
        IERC20 TOKEN = IERC20(_token);
        TOKEN.safeApprove(_guy, MAX_INT);
    }

    receive() external payable {}
}
