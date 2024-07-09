---
date: 2024-07-09 18:30
title: Solana共识协议
categories: 技术
tags:
- 区块链
- Solana
---

> https://solana.com/developers/evm-to-svm/consensus


- Solana的共识: 基于`Tower BFT + PoH`的`PoS`
  - PoS是solana的上层出块的共识协议
  - PoS之下是 Tower BFT
    - `Tower BFT = PBFT + PoH`
    - `PoH(Proof of History) `: 作为全局网络时钟，以决定区块/交易/数据的顺序, 因此Solana可以快速决定区块/交易/数据的先后顺序，并且验证节点可以快速解决分叉



