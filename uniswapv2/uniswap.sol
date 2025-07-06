// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

contract SwapExample {
    address public pair;

    constructor(address _pair) {
        pair = _pair;
    }

    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address to
    ) external {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        bool token0IsTokenIn = tokenIn < tokenOut; //Uniswap pairs are sorted (token0 < token1)
        //  Calculate output amount (simplifies , assumes fee)
        uint amountOut;
        if (token0IsTokenIn) {
            amountOut = getAmountOut(amountIn, reserve0, reserve1);
        } else {
            amountOut = getAmountOut(amountIn, reserve1, reserve0);
        }

        require(amountOut >= amountOutMin, "Insufficient output amount");

        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);

        uint amount0Out = token0IsTokenIn ? 0 : amountOut;
        uint amount1Out = token0IsTokenIn ? amountOut : 0;

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure returns (uint) {
        require(amountIn > 0, "Invalid input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        uint amountInWithFee = amountIn * 997; // 0.3% fee
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        uint amountOut = numerator / denominator;
        return amountOut;
    }
}
