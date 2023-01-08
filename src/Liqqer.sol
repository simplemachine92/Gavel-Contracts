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

    address private immutable mySafe =
        0x3224C6C9BCA033CAbB85A36891EBf994732d8f23;

    constructor(address _owner) Owned(_owner) {}

    function flash_WaC(ILiqqer.CallParams calldata params) external onlyOwner {
        IEulerDToken dToken = IEulerDToken(
            EulerAddrsMainnet.markets.underlyingToDToken(params.debtA)
        );
        dToken.flashLoan(params.debtToCover, abi.encode(params));
    }

    function onFlashLoan(bytes memory data) external {
        require(msg.sender == address(EulerAddrsMainnet.euler), "not allowed");

        // We still need this to protect our funds, but we can't set tx.origin in forge tests
        /* if (tx.origin != owner) revert UnAuthOrigin(); */

        ILiqqer.CallParams memory params = abi.decode(
            data,
            (ILiqqer.CallParams)
        );

        IERC20 DTOKEN = IERC20(params.debtA);
        DTOKEN.safeIncreaseAllowance(address(AAVE), params.debtToCover);

        AAVE.liquidationCall(
            params.collatA,
            params.debtA,
            params.userA,
            MAX_INT,
            false
        );

        if (params.swaps.length > 0) {
            for (uint256 i = 0; i < params.swaps.length; ) {
                if (params.swaps[i].isDebtSwap == false) {
                    IERC20 CTOKEN = IERC20(params.collatA);
                    CTOKEN.safeIncreaseAllowance(
                        params.swaps[i].allowTarget,
                        params.collatToReceive
                    );
                    (bool success, ) = params.swaps[i].swapTarget.call(
                        params.swaps[i].callData
                    );
                    if (!success) revert SwapCallFailed();
                }
                unchecked {
                    i++;
                }
            }
        }

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
