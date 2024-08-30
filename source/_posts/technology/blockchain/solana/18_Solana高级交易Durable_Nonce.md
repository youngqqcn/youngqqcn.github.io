---
date: 2024-08-30 11:34
title: 18_Solana高级交易Durable_Nonce
categories: 技术
tags:
- 区块链
- Solana
- 高级
---

官方文档:
- https://solana.com/developers/guides/advanced/introduction-to-durable-nonces
- https://github.com/0xproflupin/solana-durable-nonces


**本质问题： 如何避免双花？**

Recent Blockhash 做了时间戳，也充当了唯一标识(类似ETH的nonce)的作用, 防止双花


**有了 Recent Blockhash 为什么还需要 Durable Nonce?**

Recent Blockhash 的窗口是 150个区块(约 150 * 0.4 = 60s), 因此，签名之后的交易必须在一分钟内被提交执行，否则交易就会过期。

几个特殊场景:
- 大批量交易, 不想因为blockhash重复而失败 ?
- 多重签名交易？
- 离线签名？

因此，就需要 Durable Nonce 方案, nonce 是 32字节, 其作用就是确保交易的唯一






