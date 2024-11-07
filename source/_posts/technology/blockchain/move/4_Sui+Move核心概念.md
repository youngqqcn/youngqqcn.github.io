---
date: 2024-10-23 16:19
title: 4_Sui+Move核心概念
categories: 技术
tags:
- Move
- 智能合约
- Sui
---


## Sui Move的 Object基础概念

> - https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-two/lessons/1_working_with_sui_objects.md



- Sui Move 是以Object为核心
- Sui的交易输入和输出都是 Object
- Object是Sui的基本存储单元
- Object即 `struct`
- Sui 的 Object 必须包含一个 `id: UID`字段, 并且设置`key`特性
- Sui中每个Object都必须有一个 owner, owner可以是：
  - 一个地址
  - 其他object
  - Object是"shared"

## Object的所有权

> https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-two/lessons/2_ownership.md

在Sui Move中，Object一共有4种所有权:

- **Owned**: owned object交易不需要全局排序
  - Owned by an address
  - Owned by another object
- **Shared**
  - Shared immutable:
    - 没有owner, 所有人都不可修改
  - Shared mutable：
    - 任何人都可以读取和修改, shared object交易需要进行全局排序

