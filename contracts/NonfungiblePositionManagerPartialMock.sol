pragma solidity ^0.8.26;

contract NonfungiblePositionManagerPartialMock {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(MintParams calldata params)
    external
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    )
    {
        // Mock implementation: Use only part of the desired amounts
        uint256 usedAmount0 = params.amount0Desired / 2;  // Use half of amount0
        uint256 usedAmount1 = params.amount1Desired / 2;  // Use half of amount1

        return (1, 1000, usedAmount0, usedAmount1);
    }

    function increaseLiquidity(MintParams calldata params)
    external
    returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    )
    {
        // Mock implementation: return some arbitrary values
        return (1000, params.amount0Desired, params.amount1Desired);
    }

    function decreaseLiquidity(MintParams calldata params)
    external
    returns (
        uint256 amount0,
        uint256 amount1
    )
    {
        // Mock implementation: return some arbitrary values
        return (params.amount0Desired, params.amount1Desired);
    }

    function collect(MintParams calldata params)
    external
    returns (
        uint256 amount0,
        uint256 amount1
    )
    {
        // Mock implementation: return some arbitrary values
        return (params.amount0Desired, params.amount1Desired);
    }
}
