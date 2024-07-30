---
date: 2024-19-07
title: Uniswap-v3分析
categories: 技术
tags:
- 区块链
- 智能合约
- DeFi
---

- 白皮书: https://uniswap.org/whitepaper-v3.pdf
- 数学公式: https://www.odaily.news/post/5174767



核心：允许用户自定义价格区间来提供流动性，提供资本利用率



核心公式:

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/uniswap-liquidity.png)

- `L`: `流动性`


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/uniswap-constant.png)

- `x'`: 虚拟资产x
- `y'`: 虚拟资产y

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20240730-191613.jpg)

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/uniswap-formula.jpg)


增加了虚拟资产`x'`和 `y'`之后 , 

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/uniswap-v3-curve.png)



用户可以将流动性集中，这样提供资金利用率（有交易，就有手续费）
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/uniswap-v3-positions.png)