const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniswapV3Liquidity", function () {
    let UniswapV3Liquidity, uniswapV3Liquidity;
    let token0, token1, nonfungiblePositionManagerMock;
    let owner, addr1;

    before(async function () {
        [owner, addr1] = await ethers.getSigners();

        const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
        token0 = await ERC20Mock.deploy("Token0", "TK0", ethers.parseEther("1000000"));
        token1 = await ERC20Mock.deploy("Token1", "TK1", ethers.parseEther("1000000"));

        const NonfungiblePositionManagerMock = await ethers.getContractFactory("NonfungiblePositionManagerMock");
        nonfungiblePositionManagerMock = await NonfungiblePositionManagerMock.deploy();

        UniswapV3Liquidity = await ethers.getContractFactory("UniswapV3Liquidity");
        uniswapV3Liquidity = await UniswapV3Liquidity.deploy(nonfungiblePositionManagerMock.target);

        console.log("Contract deployed")
    });

    describe("Minting a new position", function () {
        it("Should mint a new liquidity position", async function () {
            const amount0ToAdd = ethers.parseEther("100");
            const amount1ToAdd = ethers.parseEther("100");
            const currentPrice = ethers.parseUnits("1", 18);
            const width = 1000; // 10%

            await token0.approve(uniswapV3Liquidity.target, amount0ToAdd);
            await token1.approve(uniswapV3Liquidity.target, amount1ToAdd);

            const allowance0 = await token0.allowance(owner.address, uniswapV3Liquidity.target);
            const allowance1 = await token1.allowance(owner.address, uniswapV3Liquidity.target);

            expect(allowance0).to.equal(amount0ToAdd);
            expect(allowance1).to.equal(amount1ToAdd);

            const tx = await uniswapV3Liquidity.mintNewPosition(
                token0.target,
                token1.target,
                amount0ToAdd,
                amount1ToAdd,
                currentPrice,
                width
            );

            const receipt = await tx.wait();

            expect(receipt.status).to.equal(1);
        });

        it("Should correctly calculate the price range based on the given width", async function () {

            const currentPrice = BigInt("1000000000000000000000"); // Example current price in wei (1000 * 10^18)
            const width = BigInt(500); // Example width (5%)

            const [lowerPrice, upperPrice] = await uniswapV3Liquidity.calculatePriceRange(currentPrice, width);

            const expectedDelta = (currentPrice * width) / BigInt(10000); // (width / 10000) * currentPrice
            const expectedLowerPrice = currentPrice - expectedDelta;
            const expectedUpperPrice = currentPrice + expectedDelta;

            expect(lowerPrice).to.equal(expectedLowerPrice);
            expect(upperPrice).to.equal(expectedUpperPrice);
        });


        it("Should refund excess token0", async function () {
            const amount0ToAdd = ethers.parseEther("100");
            const amount1ToAdd = ethers.parseEther("100");
            const currentPrice = ethers.parseUnits("1", 18);
            const width = 1000;

            const NonfungiblePositionManagerPartialMock = await ethers.getContractFactory("NonfungiblePositionManagerPartialMock");
            const nonfungiblePositionManagerPartialMock = await NonfungiblePositionManagerPartialMock.deploy();

            const UniswapV3Liquidity = await ethers.getContractFactory("UniswapV3Liquidity");
            const uniswapV3Liquidity = await UniswapV3Liquidity.deploy(nonfungiblePositionManagerPartialMock.target);

            await token0.approve(uniswapV3Liquidity.target, amount0ToAdd);
            await token1.approve(uniswapV3Liquidity.target, amount1ToAdd);

            const initialBalance = await token0.balanceOf(owner.address);

            await uniswapV3Liquidity.mintNewPosition(
                token0.target,
                token1.target,
                amount0ToAdd,
                amount1ToAdd,
                currentPrice,
                width
            );

            const finalBalance = await token0.balanceOf(owner.address);

            expect(finalBalance).to.be.gt(initialBalance - amount0ToAdd);
        });

        it("Should refund excess token1", async function () {
            const amount0ToAdd = ethers.parseEther("100");
            const amount1ToAdd = ethers.parseEther("100");
            const currentPrice = ethers.parseUnits("1", 18);
            const width = 1000;

            const NonfungiblePositionManagerPartialMock = await ethers.getContractFactory("NonfungiblePositionManagerPartialMock");
            const nonfungiblePositionManagerPartialMock = await NonfungiblePositionManagerPartialMock.deploy();

            const UniswapV3Liquidity = await ethers.getContractFactory("UniswapV3Liquidity");
            const uniswapV3Liquidity = await UniswapV3Liquidity.deploy(nonfungiblePositionManagerPartialMock.target);

            await token0.approve(uniswapV3Liquidity.target, amount0ToAdd);
            await token1.approve(uniswapV3Liquidity.target, amount1ToAdd);

            const initialBalance = await token1.balanceOf(owner.address);

            await uniswapV3Liquidity.mintNewPosition(
                token0.target,
                token1.target,
                amount0ToAdd,
                amount1ToAdd,
                currentPrice,
                width
            );

            const finalBalance = await token1.balanceOf(owner.address);

            expect(finalBalance).to.be.gt(initialBalance - amount1ToAdd);
        });

    });
});
