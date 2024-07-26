---
date: 2024-07-26 10:04
title: 16_Solana_程序安全实践指南
categories: 技术
tags:
- 区块链
- Solana
- 交易
- Token
- Anchor
- 安全
- 架构
---



官方列出的安全例子:
- https://github.com/coral-xyz/sealevel-attacks/tree/master/programs


汇总如下：

- [`0-signer-authorization`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/0-signer-authorization): **非法权限调用攻击**，调用者不是交易签名者
  - 使用 Anchor的`Signer`账户类型检查交易签名者
- [`1-account-data-matching`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/1-account-data-matching): 账户&数据不一致，伪造攻击
  - 使用 Anchor的约束，检查权限是否一致
- [`2-owner-check`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/2-owner-checks): 权限, owner不一致
- [`3-type-cosplay`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/3-type-cosplay): 数据类型伪造
- [`4-initialization`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/4-initialization):  重复初始化攻击 + 初始化抢跑攻击
  - 重新初始化攻击: 使用Anchor的`init`,
  - 初始化抢跑攻击: 使用 Anchor的init, 重复初始化会报错，因为就会发现是否被抢跑
- [`5-arbitrary-cpi`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/5-arbitrary-cpi):  CPI乱调用(programId不一致, PDA的owner不是该程序), 可以进行**伪造PDA攻击**
  - 使用Anchor的`CpiContext`进行CPI调用
- [`6-duplicate-mutable-accounts`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/6-duplicate-mutable-accounts): 重复修改账户(2个账户数据结构相同，传入相同的值)
  - 注意账户&指令中包含2个相同的数据结构的账户，要做检查key检查
- [`7-bump-seed-canonicalization`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/7-bump-seed-canonicalization): PDA碰撞攻击(通过传入 seeds和bump)
- [`8-pda-sharing`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/8-pda-sharing): **(常见)伪造PDA攻击**, PDA权限不清晰(共享的PDA)，攻击者可以伪造一个PDA
  - 原因： `seeds` 中字段不唯一，没有跟账户关联起来
- [`9-closing-accounts`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/9-closing-accounts): **账户关闭攻击（重入攻击）**,
  - 要在指令执行结束后，关闭一个（临时）账户, 直接使用Anchor的 `close=destination` 约束即可
- [`10-sysvar-address-checking`](https://github.com/coral-xyz/sealevel-attacks/tree/master/programs/10-sysvar-address-checking): 系统变量地址检查(PDA伪造)
  - 使用Anchor的`Sysvar`获取系统变量

