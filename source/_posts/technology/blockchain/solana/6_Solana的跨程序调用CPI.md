---
date: 2024-07-09 19:43
title: 6_Solana的跨程序调用CPI
categories: 技术
tags:
- 区块链
- Solana
- 交易
- 指令
---


# Cross Program Invocation (CPI)

> https://solana.com/docs/core/cpi

- CPI： 一个程序调用其他程序中的指令, 这就给了程序的可组合性

    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/cpi.svg)

- CPI调用栈高度限制: `5`
  - A(1)->B(2)->C(3)->D(4)->E(5)


- 因为PDA没有私钥，因此，为了验证PDA， 必须传入`signers_seeds`


