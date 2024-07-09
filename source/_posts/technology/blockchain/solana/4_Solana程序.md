---
date: 2024-07-09 19:40
title: 4_Solana程序
categories: 技术
tags:
- 区块链
- Solana
- 交易
- 指令
---


# Solana程序(智能合约)

> https://solana.com/docs/core/programs

- 在solana中“智能合约”被称为“程序”(program)
- 每个程序是一个链上的账户, 该账户存储了可执行的代码(指令)


### 关键点：
- Solana程序是一个包含了`可执行代码`的链上`账户`, 代码中包含了不同的函数, 即`指令`

- 程序是无状态的，但是可以包含创建`新账户`的`指令`，这个`新账户`可以用来存储和管理程序状态(即`数据账户`)

- 程序可以被升级，仅限拥有可升级权限的账户可以升级程序。如果一个程序的升级权限设置为`null`, 那么这个程序就不能再升级了。

- Verifiable builds enable users to verify that onchain programs match the publicly available source code.


### 编写Solana程序

- 原生Rust

- Anchor框架(推荐)
  - https://solana.com/developers/guides/getstarted/intro-to-anchor
  - https://www.anchor-lang.com/docs/


### 更新Solana程序

> https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/programs/bpf_loader/src/lib.rs#L675

- 链上程序可以更新, 必须通过`upgrade authority`账号, 这个账号通常是初始程序部署的账号
- 如果`upgrade authority`为空， 那么程序就是不可变的，并且不可升级
  - https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/programs/bpf_loader/src/lib.rs#L865
