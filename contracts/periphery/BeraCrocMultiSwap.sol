pragma solidity 0.8.19;

import "../CrocSwapDex.sol";
import "../libraries/SwapHelpers.sol";


contract BeraCrocMultiSwap {
    CrocSwapDex public crocSwapDex;

    constructor(address _crocSwapDex) {
        crocSwapDex = CrocSwapDex(_crocSwapDex);
    }

    /* @notice Performs a series of swaps between multiple pools.
     *
     * @dev A convenience method for performing a series of swaps in sequence. This is
     *      to be used in conjunction with some form of an off-chain router as the input
     *      arguments assume the user already knows the exact sequence of swaps to
     *      perform.
     *  
     * @param steps The series of swap steps to be performed in sequence.
     * @return The token base and quote token flows associated with this swap action. 
     *         (Negative indicates a credit paid to the user, positive a debit collected
     *         from the user) */
    function multiSwap (SwapHelpers.SwapStep[] memory steps) public payable returns (uint128 out) {
            require(steps.length != 0, "No steps provided");
            SwapHelpers.SwapStep memory initStep = steps[0];
            require(initStep.amount != 0, "No amount provided");
            uint128 quantity = initStep.amount;
            address inputAsset;
            initStep.isBuy ? inputAsset = initStep.base : inputAsset = initStep.quote;
            for (uint256 i; i < steps.length; ) {
                SwapHelpers.SwapStep memory step = steps[i];
                unchecked { ++i; }
                address swapAsset;
                step.isBuy ? swapAsset = step.base : swapAsset = step.quote;
                require(inputAsset == swapAsset, "Invalid swap sequence");
                // We use the max uint128 as the limit price to ensure the swap executes
                // Given that we have full range liquidity, there is no min limit price
                // Slippage can be controlled by the minOut parameter
                if (step.isBuy) {
                    (, int128 quoteFlow) = crocSwapDex.swap(step.base, step.quote, step.poolIdx,
                    step.isBuy, true, quantity, 0, type(uint128).max, step.minAmountOut, 2);
                    quantity = uint128(quoteFlow);
                    inputAsset = step.quote;
                } else {
                    (int128 baseFlow,) = crocSwapDex.swap(step.base, step.quote, step.poolIdx,
                    step.isBuy, false, quantity, 0, type(uint128).max, step.minAmountOut, 2);
                    quantity = uint128(baseFlow);
                    inputAsset = step.base;
                }
            }
            return quantity;
    }
}