// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./utils/Margin.sol";
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
    ISoloMargin private immutable soloMargin =
        ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    IWETH private immutable WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ILendingPool private immutable AAVE =
        ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    address private immutable mySafe =
        0x3224C6C9BCA033CAbB85A36891EBf994732d8f23;

    constructor(address _owner) Owned(_owner) {
        WETH.approve(address(soloMargin), MAX_INT);
    }

    function flashLoan_UNy(
        uint256 loanAmount,
        ILiqqer.CallParams calldata _params
    ) external onlyOwner {
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: loanAmount
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(this),
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
            otherAddress: address(this),
            otherAccountId: 0,
            data: abi.encode(loanAmount + 2, _params)
        });

        operations[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: loanAmount + 2
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner: address(this), number: 1});

        soloMargin.operate(accountInfos, operations);
    }

    function callFunction(
        address sender,
        Account.Info calldata accountInfo,
        bytes calldata data
    ) external {
        if (msg.sender != address(soloMargin)) revert UnAuthorized();
        if (sender != address(this)) revert UnAuthorized();
        if (tx.origin != owner) revert UnAuthOrigin();

        (uint256 loanAmountWithFee, ILiqqer.CallParams memory decoded) = abi
            .decode(data, (uint256, ILiqqer.CallParams));

        if (decoded.swaps.length > 0) {
            for (uint256 i = 0; i < decoded.swaps.length; ) {
                if (decoded.swaps[i].isDebtSwap == true) {
                    IERC20 SWETH = IERC20(address(WETH));
                    SWETH.safeIncreaseAllowance(
                        decoded.swaps[i].allowTarget,
                        loanAmountWithFee - 2
                    );
                    (bool success, ) = decoded.swaps[i].swapTarget.call(
                        decoded.swaps[i].callData
                    );
                    if (!success) revert SwapCallFailed();
                }
                unchecked {
                    i++;
                }
            }
        }

        IERC20 DTOKEN = IERC20(decoded.debtA);
        uint256 debtB = DTOKEN.balanceOf(address(this));
        DTOKEN.safeIncreaseAllowance(address(AAVE), debtB);

        AAVE.liquidationCall(
            decoded.collatA,
            decoded.debtA,
            decoded.userA,
            MAX_INT,
            false
        );

        if (decoded.swaps.length > 0) {
            for (uint256 i = 0; i < decoded.swaps.length; ) {
                if (decoded.swaps[i].isDebtSwap == false) {
                    IERC20 CTOKEN = IERC20(decoded.collatA);
                    uint256 collatR = CTOKEN.balanceOf(address(this));
                    CTOKEN.safeIncreaseAllowance(
                        decoded.swaps[i].allowTarget,
                        collatR
                    );
                    (bool success, ) = decoded.swaps[i].swapTarget.call(
                        decoded.swaps[i].callData
                    );
                    if (!success) revert SwapCallFailed();
                }
                unchecked {
                    i++;
                }
            }
        }

        uint256 wethOver = WETH.balanceOf(address(this)) - loanAmountWithFee;
        bool txsuccess = WETH.transfer(mySafe, wethOver);
        if (!txsuccess) revert SafeTxFailed();
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
