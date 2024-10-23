---
date: 2024-10-23 14:50
title: 2_Sui入门
categories: 技术
tags:
- Move
- 智能合约
- Sui
---

> 参考： https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-one/lessons/1_set_up_environment.md


## 安装

- 安装 `sui`

    ```
    cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui
    ```

- vscode 安装 `move-analyzer`插件

    ```
    cargo install --git https://github.com/move-language/move move-analyzer --features "address20"
    ```



## 初始化

- `sui client envs`
  - `devnet`: `https://fullnode.devnet.sui.io:443`
  - `0` for ed25519


## 安装 Sui 插件钱包

https://chromewebstore.google.com/detail/sui-wallet/opcgpfmipidbgpenhmajoajpbobppdil?pli=1


## 获取测试币

`sui client faucet`

每次可以获取 10 SUI


## 浏览器查看地址

https://suiscan.xyz/devnet/account/0x163813fb76d72bf46451ddfad78b35700198bf8eb8f3d3dee596726c2b01515b



## 查看地址
- 查看地址: `sui client addresses`
- 查看活跃地址: `sui client active-address`
- 获取余额(Sui上叫做gas object): `sui client gas`
- 