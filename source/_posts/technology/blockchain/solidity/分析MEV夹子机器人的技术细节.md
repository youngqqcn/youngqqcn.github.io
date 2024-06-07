---
date: 2024-06-07 18:30
title: 分析MEV夹子机器人的技术细节
categories: 技术
tags:
- 区块链
- 智能合约钱包
- DeFi
- MEV
---


## 初始流动池状态:
  - `A0: 1 USDT`
  - `B0: 85.875  TXXC`
  - `TXXC价格 = A0/B0 =  0.0116 USDT/TXXC`
  - https://ave.ai/token/0xf1ec63b614cf0196240d20216da303be353217f3-bsc?from=Default


## 机器人买入:
  - 该交易区块的第1个位置(给了 11Gwei)

  - MEV机器人的买入: https://bscscan.com/tx/0xb0d8416aa4e80a0db454e37c1986f209a4a7b01725a0f70ec8dd089e1b9615a6

  - ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/截图_2024-06-07_12-20-57.png)

  - 买入： `6.07 USDT`, 计算买入的 TXXC的数量和价格, ChatGPT的计算过程:
  - ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/截图2024-06-07_15-14-29.png)
  - ChatGPT的计算过程和计算结果完全正确：
  - ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/截图_2024-06-07_15-17-35.png)


  - 此时流动池中的状态
  - `A1: 7.07 USDT`
  - `B1: 12.145 TXXC`
  - 此时的价格 `7.07 / 12.145 = 0.5821  USDT/TXXC`


## 我的添加流动性交易:
- 该交易区块的第2个位置

- 源码： https://bscscan.com/address/0x10ed43c718714eb63d5aa57b78b54704e256024e#code
- 详细代码分析，见文末
```js
function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired, // 希望投入的代币 A 的数量，但实际投入量可能会因为比例调整而不同
    uint amountBDesired, // 希望投入的代币 B 的数量，但实际投入量可能会因为比例调整而不同
    uint amountAMin, // 滑点保护，用户愿意接受的最少代币 A 的数量， 确保用户不会因为价格波动而损失太多代币A
    uint amountBMin, // 滑点保护，用户愿意接受的最少代币 B 的数量，确保用户不会因为价格波动而损失太多代币B
    address to, // 流动性代币接收者的地址。流动性代币是代表用户在流动池中所有权的代币。
    uint deadline // 交易的最后期限（时间戳）。确保交易在指定时间内完成，否则交易将被取消。
)
```


- 交易： https://bscscan.com/tx/0x3d00cad4557eecd49906c1874c838576928d238a774f10b118d44bf96d071d74

- ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/截图_2024-06-07_12-28-37.png)

- 计算:
  - `amountADesired`: `8.998834461493163430 USDT`
  - `amountBDesired`: `7.73000000000000000000 TXXC`
  - 因此`amountBOptimal = amountADesired * B1 / A1 = 8.998 * 12.1455 / 7.07 = 15.456`
  - 满足 `if (amountBOptimal <= amountBDesired) `, 所以
    - 因此 `(amountA, amountB) = (amountADesired, amountBOptimal);`
    - 即 `(amountA, amountB) = (8.998, 15.456);`

- 其中 `quote`函数, 按照等比例增加, 这里只能近似:
   ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/截图_2024-06-07_18-35-24.png)

  -  `A2: 7.07 + 8.99 = 16.06 USDT`
  - `B2: 12.145 + 15.3 = 27.445  TXXC`
  - 此时价格  `0.5854 USDT/TXXC`




## MEV机器人的卖出
- 该交易区块的第3个位置

- MEV机器人的卖出: https://bscscan.com/tx/0xed61c87971f645c7f8bfd1ab22d1e8bca42cea171a47c3acf2a0c9dd6a4628bc

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/截图_2024-06-07_12-29-28.png)


- 此时MEV机器人全部卖出，
  - `B3 = 27.45 + 66.5 + 3.5 = 97.45`
  - `A3 =  k / B3 = (16.06*27.445) / 97.45  = 4.523`
  - 此时的价格： `A3 / B3 = 4.523 / 97.45 = 0.0464 USDT/TXXC`


- MEV机器人的获利：
  - USDT: `16.06 - 4.523 - 6.07 = 5.467 USDT`
  - BNB手续费: `0.00475 BNB` , `0.0047 * 700` = `3.324 U`
    - 购买交易手续费:`0.00245 BNB`
      - gas price: 11Gwei ， 一般是 1Gwei, 所以能排在第0个位置,
    - 购买交易平台手续费: `0.002 BNB`
    - 卖出交易手续费：`0.0003 BNB`
  - 合计： `5.467 - 3.324 = 2.1423`
  - MEV通过这一次交易，净赚`2.14 U`

- 我损失的:
  - USDT- ` -5.467`
  - BNB: ` +0.0026 BNB`, 约 `1.82U`
    - 池子是我建的，手续归我
  - 合计: ` -3.647U`
  - 我这笔交易损失: `3.647 U`



## 分析原因

- 添加流动性交易，没有设置滑点保护参数, `amountAMin` 和  `amountBMin`:
  - ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/截图2024-06-07_15-27-05.png)
  - 源码 https://bscscan.com/address/0x10ed43c718714eb63d5aa57b78b54704e256024e#code ：
    ```js
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

        // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IPancakeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 计算 B的最小数量, 满足  A * B = k = A' * B' 的恒常等式
            // B' = A' * B
            uint amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);

            // 如果 B的最有数量  小于 用户愿意投入的
            if (amountBOptimal <= amountBDesired) {

                // 滑点保护
                require(amountBOptimal >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');

                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {

                // 计算 A的最优数量
                uint amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);

                // 必须满足： A的
                assert(amountAOptimal <= amountADesired);

                // 滑点保护
                require(amountAOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');

                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin, // 滑点保护
        uint amountBMin, // 滑点保护
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
    }
  ```

