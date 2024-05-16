---
date: 2024-5-16
title: 基于BodingCurve价格发现的代币
categories: 技术
tags:
- Token
- Solidity
- BodingCurve
- 价格发现
- 代币
---

# 基于BondingCurve价格发现的代币


## 相关链接

- https://yos.io/2018/11/10/bonding-curves/

- https://github.com/C-ORG/whitepaper/

- https://github.com/youngqqcn/continuous-token

- https://github.com/youngqqcn/c-org

- https://github.com/solana-labs/solana-program-library/blob/master/token-swap/program/src/curve/constant_price.rs


## 关于抢跑问题

- 通过设置一个最大的gas price，可以避免抢跑问题

```solidity

contract CappedGasPrice is Ownable {
    uint256 public maxGasPrice = 1 * 10**18; // Adjustable value

    modifier validGasPrice() {
        require(tx.gasprice <= maxGasPrice, "Transaction gas price cannot exceed maximum gas price.");
        _;
    }

    function setMaxGasPrice(uint256 gasPrice) public onlyOwner {
        maxGasPrice = gasPrice;
    }
}
```