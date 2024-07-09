---
date: 2024-07-09 19:31
title: 3_Solana的手续费
categories: 技术
tags:
- 区块链
- Solana
- 交易
- 指令
---


# Solana手续费

> https://solana.com/docs/core/fees#compute-unit-limit

- Transaction Fees(base fee) : 交易费
- Prioritization Fees : 可选的,加速交易的手续费
  - 给矿工
- Rent: 账户租金(充值)


- 交易手续费的分配：
  - `50%`: 交易费直接燃烧
  - `50%`: 给矿工

- 交易中的每个签名需要支付`5000` lamports

- 交易执行限制：
    > https://solana.com/docs/core/fees#compute-unit-limit
  - 每个指令最大计算单元(CU): `200000` CU
  - **绝对的交易的最大计算单元(CU)**: `1400000` CU
    - 这个是Solana的上限，不管如何调整都不能突破这个限制
    - 交易中可以设置最大执行单元，但是最大不能超过系统的最大限制
    - 关于调整交易的最大CU: https://solana.com/developers/guides/advanced/how-to-request-optimal-compute


- 计算单元(CU)价格： 如果需要加速交易，需要设置 `compute unit price`, 并且设置`compute unit limit`, 这2个参数用来决定交易的  `priority fee`

- Prioritization fee 的计算取决于：
  - `SetComputeUnitLimit` : 设置交易最大能够消耗的CU
  - `SetComputeUnitPrice` : CU价格,来加速
    - 如果不提供此值， 则交易无priority fee

- 如何设置  `prioritization fee` ？
  - 交易需要包含2个指令`SetComputeUnitLimit` 和 `SetComputeUnitPrice`
  - 注意：
    - 这2个指令**不需要任何账户** , 这不同于其他指令
    - 同一种计算单元指令类型不能重复，否则会报错`TransactionError::DuplicateInstruction`
  - 更多：https://solana.com/developers/guides/advanced/how-to-request-optimal-compute



- 租金
  - 获取租金豁免: https://solana.com/docs/rpc/http/getminimumbalanceforrentexemption
  - 垃圾账户回收： solana会将不能支付租金的账户进行回收，回收之后，账户在区块浏览器上显示"account not found", 但是这个账户的历史交易仍然可以查询