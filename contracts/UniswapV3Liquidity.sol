pragma solidity ^0.8.26;

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);
    function allowance(address owner, address spender)
    external
    view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
    external
    returns (bool);
}

interface INonfungiblePositionManager {
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
    payable
    returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);
}

contract UniswapV3Liquidity is IERC721Receiver {
    using Strings for uint256;

    INonfungiblePositionManager public nonfungiblePositionManager;

    constructor(address _nonfungiblePositionManager) {
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Calculate price range based on the width
    function calculatePriceRange(uint256 currentPrice, uint256 width)
    public
    pure
    returns (uint256 lowerPrice, uint256 upperPrice)
    {
        uint256 delta = (width * currentPrice) / 10000;
        upperPrice = currentPrice + delta;
        lowerPrice = currentPrice - delta;
        return (lowerPrice, upperPrice);
    }

    // Convert a price to a tick (simplified example, actual Uniswap V3 calculation may differ)
    function getTickFromPrice(uint256 price) internal pure returns (int24) {
        // This is a placeholder function. In a real implementation, you would use
        // Uniswap V3's actual price-to-tick formula, which involves logarithms.
        return int24(int256(price)); // Simplified example, should be replaced
    }

    // Mint new position with dynamic tokens and price range based on width
    function mintNewPosition(
        address token0,
        address token1,
        uint256 amount0ToAdd,
        uint256 amount1ToAdd,
        uint256 currentPrice,
        uint256 width
    )
    external
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        IERC20 token0Contract = IERC20(token0);
        IERC20 token1Contract = IERC20(token1);

        uint256 allowance0 = token0Contract.allowance(msg.sender, address(this));
        uint256 allowance1 = token1Contract.allowance(msg.sender, address(this));

        require(allowance0 >= amount0ToAdd, string(abi.encodePacked(
            "Allowance exceeded for token0. Current allowance: ", allowance0.toString(),
            ", required: ", amount0ToAdd.toString()
        )));

        require(allowance1 >= amount1ToAdd, string(abi.encodePacked(
            "Allowance exceeded for token1. Current allowance: ", allowance1.toString(),
            ", required: ", amount1ToAdd.toString()
        )));

        (uint256 lowerPrice, uint256 upperPrice) = calculatePriceRange(currentPrice, width);

        int24 tickLower = getTickFromPrice(lowerPrice);
        int24 tickUpper = getTickFromPrice(upperPrice);

        token0Contract.transferFrom(msg.sender, address(this), amount0ToAdd);
        token1Contract.transferFrom(msg.sender, address(this), amount1ToAdd);

        token0Contract.approve(address(nonfungiblePositionManager), amount0ToAdd);
        token1Contract.approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.MintParams memory params =
                            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: 3000,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) =
        nonfungiblePositionManager.mint(params);

        if (amount0 < amount0ToAdd) {
            token0Contract.approve(address(nonfungiblePositionManager), 0);
            uint256 refund0 = amount0ToAdd - amount0;
            token0Contract.transfer(msg.sender, refund0);
        }
        if (amount1 < amount1ToAdd) {
            token1Contract.approve(address(nonfungiblePositionManager), 0);
            uint256 refund1 = amount1ToAdd - amount1;
            token1Contract.transfer(msg.sender, refund1);
        }
    }

    function collectAllFees(uint256 tokenId)
    external
    returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.CollectParams memory params =
                            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);
    }

    function increaseLiquidityCurrentRange(
        address token0,
        address token1,
        uint256 tokenId,
        uint256 amount0ToAdd,
        uint256 amount1ToAdd
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        IERC20 token0Contract = IERC20(token0);
        IERC20 token1Contract = IERC20(token1);

        token0Contract.transferFrom(msg.sender, address(this), amount0ToAdd);
        token1Contract.transferFrom(msg.sender, address(this), amount1ToAdd);

        token0Contract.approve(address(nonfungiblePositionManager), amount0ToAdd);
        token1Contract.approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params =
                            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) =
        nonfungiblePositionManager.increaseLiquidity(params);
    }

    function decreaseLiquidityCurrentRange(
        uint256 tokenId,
        uint128 liquidity
    )
    external
    returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params =
                            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) =
        nonfungiblePositionManager.decreaseLiquidity(params);
    }
}
