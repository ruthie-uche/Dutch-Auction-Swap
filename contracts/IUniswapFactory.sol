import {ethers} from "hardhat"
const helpers = require("@nomicfoundation/hardhat-toolbox/network-helpers")

const main = async () => {

    //contract address  for both token

    const thresholdAddress = "0xCdF7028ceAB81fA0C6971208e83fa7872994beE5"
    const kuCoinAddress = "0xf34960d9d60be18cC1D5Afc1A6F012A723a28811"

    // uniswap router and liquidity provider
    const uniswapRouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
    
    //liquidity provider that holds both token

    const liquidityProvider = "0xf584F8728B874a6a5c7A8d4d387C9aae9172D621"

    //get contract

    await helpers.impersonateAccount(liquidityProvider);

    const impersonateSigner = await ethers.getSigner(liquidityProvider);
    let thresholdContract = await ethers.getContractAt("IERC20",thresholdAddress);
    let kucoinContract = await ethers.getContractAt("IERC20", kuCoinAddress)
    let uniswapRouterContract = await ethers.getContractAt("IUniswapV2Router01", uniswapRouter)

    //balance
    console.log("------------let fucking go 🤩-------------")


// get balance

const thresholdBalance = await thresholdContract.balanceOf(liquidityProvider)
const kucoinBalance =await kucoinContract.balanceOf(liquidityProvider)


console.log("\n\n---------------before 😁---------------")

console.log("before balance for impersonated threshhold " + ethers.formatUnits(thresholdBalance,18 ))
console.log("before balance for impersonated Kucoin " + ethers.formatUnits(kucoinBalance, 6 ))  


console.log("\n\n---------------getting Pair Address 🥃-------------------")
const getContractFactoryAddress = await uniswapRouterContract.factory()

const factoryContract = await ethers.getContractAt("IUniswapV2Factory",getContractFactoryAddress)


const poolAddress = await factoryContract.getPair(thresholdAddress,kuCoinAddress);

const poolContract = await ethers.getContractAt("IERC20",poolAddress);
const decimalPoolAddress = await poolContract.decimals()
const poolAddressBal = await poolContract.balanceOf(liquidityProvider)

console.log(decimalPoolAddress)
console.log("threshold/kucoin " + ethers.formatUnits(poolAddressBal, decimalPoolAddress))

// const poolAddressBal = await 






const amountAMin = ethers.parseUnits("0", 18)
const amountBMin = ethers.parseUnits("0", 6)

// const amountAMin = 51136872.05408214726900432
// const amountBMin = amountBDesired * 90n/100n

const liquidity =  poolAddressBal

// function removeLiquidity(
//     address tokenA,
//     address tokenB,
//     uint liquidity,
//     uint amountAMin,
//     uint amountBMin,
//     address to,
//     uint deadline
// ) external returns (uint amountA, uint amountB);
const deadline = await helpers.time.latest() + 300;

await  poolContract.connect(impersonateSigner).approve(uniswapRouter, liquidity)
console.log("\n\n---------------removing Liquidity ⌛---------------")
try {
    const removeLiquidty = await uniswapRouterContract.connect(impersonateSigner).removeLiquidity(thresholdAddress,  kuCoinAddress, liquidity, amountAMin, amountBMin, liquidityProvider,deadline )
// await removeLiquidty.wait()
console.log("remove liquidity successful 😊")
    
} catch (error) {
    console.error("remove liquidity failed 😢" + error)
    
}


const thresholdBalanceAfter = await thresholdContract.balanceOf(liquidityProvider)
const kucoinBalanceAfter =await kucoinContract.balanceOf(liquidityProvider)

const poolAddressBalAfter = await poolContract.balanceOf(liquidityProvider)


console.log("\n\n---------------After 😁---------------")

console.log("after balance for impersonated threshhold " + ethers.formatUnits(thresholdBalance,18 ))
console.log("after balance for impersonated Kucoin " + ethers.formatUnits(kucoinBalance, 6 ))  
console.log("after threshold/kucoin " + ethers.formatUnits(poolAddressBalAfter, decimalPoolAddress))


// const removeLiquidty =  uniswapRouterContract.removeLiquidity(thresholdAddress,  kuCoinAddress, liquidity, amountAMin, amountBMin, liquidityProvider,deadline )



}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});