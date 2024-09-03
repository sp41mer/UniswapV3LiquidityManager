# UniswapV3 Liquidity Manager

Inspired by: https://solidity-by-example.org/defi/uniswap-v3-liquidity

## What is this?
This project is a smart contract for managing liquidity on Uniswap V3. With it, you can add liquidity to pools, calculate price ranges, and increase or decrease your existing liquidity positions.

## Key Features
1. Managing Liquidity
   The contract lets you add liquidity to Uniswap V3 pools and manage it. When you add a new position, the contract calculates the price range where your position will be active.

2. Calculating Price Range with Width
   The calculatePriceRange function calculates the lower and upper prices based on two key inputs: the current price and the width of the range. The width is a percentage that defines how far above and below the current price your liquidity will be placed.

- Width Parameter:  The width is given as a percentage in basis points (bps). For example, if the width is 500, this represents 5% (because 500/10000 = 0.05 or 5%).
- Price Range Calculation:  The function calculates a delta, which is the amount to add and subtract from the current price to get the upper and lower price bounds.  
  delta = (width / 10000) * currentPrice  
  lowerPrice = currentPrice - delta  
  upperPrice = currentPrice + delta  
  This calculation helps to determine the price range within which your liquidity will be active. If the market price moves outside this range, your liquidity might no longer be used efficiently.

3. Handling ERC20 Tokens
   The contract works with ERC20 tokens, which are standard tokens on Ethereum. Before the contract can use your tokens, you need to give it permission through the approve function.

4. Refunding Unused Tokens
   If not all of your tokens are used, the contract will send the unused tokens back to you.

## Tests
1. Adding a New Position  
   This test checks if you can successfully add a new liquidity position. If everything works, the test will pass.

2. Refunding Excess tokens  
   This test checks if the contract properly refunds any unused token0 back to you.

3. Calculating Price Range  
   This test checks if the contract correctly calculates the price range based on the given width and current price. It ensures that the price range matches the expected values calculated by the test.

## What Can Be Improved
Add Events  
You can add events that will trigger when liquidity is added, tokens are refunded, or a position is changed. This will make it easier to track what the contract is doing.

Optimize Gas  
Costs You can try to reduce gas costs to make the contract cheaper to use.

Automate Liquidity Management You can add automatic strategies, so the contract can rebalance positions based on market conditions without your constant input.