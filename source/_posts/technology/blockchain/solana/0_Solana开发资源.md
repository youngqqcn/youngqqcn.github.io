---
date: 2024-07-08 09:53
title: 0_Solana开发资源
categories: 技术
tags:
- 区块链
- Solana
- 开发
---


## Solana开发资源
> https://www.notion.so/Solana-fca856aad4e5441f80f28cc4e015ca98
> https://github.com/CreatorsDAO/solana-co-learn/blob/main/docs/awesome-solana-zh/README.mdx

- Rust:
  - Rust共学: https://github.com/CreatorsDAO/rust-co-learn
- Solana
  - 开发课程: https://www.soldev.app/course
    - 中文: https://www.solanazh.com/
  - Solana官方开发文档：https://docs.solana.com/developers
  - Cookbook: https://solanacookbook.com/
  - 开发者: https://github.com/solana-developers
  - 工具库: https://github.com/solana-developers/solana-tools
  - Solana程序示例： https://github.com/solana-developers/program-examples
  - Anchor初步Counter示例：https://github.com/solana-developers/anchor-starter/tree/main
  - Solana生态工具： https://solana.com/ecosystem
  - 706共学社：
    - Solana共学: https://github.com/CreatorsDAO/solana-co-learn
- Anchor
  - 官方文档: https://www.anchor-lang.com/
  - 官方示例: https://github.com/coral-xyz/anchor/tree/master/examples/tutorial


## 开源 Solana DEX
- Openbook
  - 官网： https://prism.ag/trade/
  - https://github.com/openbook-dex/program
  - https://github.com/openbook-dex/openbook-v2
  - https://github.com/openbook-dex/scripts-v2
- Raydium:
    - 官网：https://raydium.io/swap/
    - https://github.com/raydium-io/raydium-cp-swap
    - https://github.com/raydium-io/raydium-amm
    - https://github.com/raydium-io/raydium-contract-instructions/
- Mango Dex:
  - https://app.mango.markets/zh
  - 代码：https://github.com/blockworks-foundation/mango-v4/tree/dev
- Serum Dex:
  - https://github.com/project-serum/serum-dex/
- Jupiter:
  - https://github.com/jup-ag/sol-swap-cpi
  - https://station.jup.ag/docs
  - Jupiter API构建交易： https://station.jup.ag/docs/apis/swap-api
- Anchor交易相关示例:
  - https://github.com/coral-xyz/anchor/tree/master/tests/swap
  - https://github.com/coral-xyz/anchor/tree/master/tests/escrow
  - https://github.com/coral-xyz/anchor/tree/master/tests/ido-pool
  - https://github.com/coral-xyz/anchor/blob/master/tests/cfo/programs/cfo/src/lib.rs
- 其他:
  - pump.fun自动买卖机器人: https://github.com/pumppumps/pumpfun-bump-bot/tree/main
  - Raydium交易: https://github.com/henrytirla/Solana-Raydium-Trading/tree/master
  - swap前端: https://github.com/atillabirer/solana-nextjs-dex/tree/main




## Solana节点搭建

- https://docs.solanalabs.com/operations/requirements

RPC节点最低配置:
  - CPU:  32核+
  - RAM:  512GB+
  - Disk: 2TB+
  - Network: 10GBit/s+

- 预估服务器费用(年): 13万RMB左右




## 使用 `solana-keygen` 生成与 Phantom一致的地址

```
solana-keygen new --word-count 12 --no-bip39-passphrase --derivation-path "m/44'/501'/0'/0'" --outfile ./mynew-address.json
```