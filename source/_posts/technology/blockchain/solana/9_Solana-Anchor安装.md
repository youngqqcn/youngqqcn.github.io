---
date: 2024-07-09 20:05
title: 9_Solana-Anchor安装
categories: 技术
tags:
- 区块链
- Solana
- 交易
- Token
---

### 搭建本地开发环境
> https://solana.com/developers/guides/getstarted/setup-local-development


- 安装Anchor
  - avm:  Anchor Version Manager


```
sudo apt-get update && sudo apt-get upgrade && sudo apt-get install -y pkg-config build-essential libudev-dev libssl-dev

cargo install --git https://github.com/coral-xyz/anchor avm --locked --force

# 安装最新版
avm install latest

# 使用最新版
avm use latest

# check the version

anchor --version
```


- Setup a localhost blockchain cluster

    ```
    solana-test-validator --help

    # setup localhost blockchain
    solana-test-validator


    # swith to localhost
    solana config set --url localhost

    solana config get

    # set default wallet
    solana config set -k ~/.config/solana/id.json

    # get the airdrop from localhost blockchain
    solana airdrop 2

    # get balance
    solana balance
    ```


- 新建anchor项目

```
anchor init <new-workspace-name>
```


## Anchor程序结构
> https://www.solanazh.com/course/7-3

> Anchor官方示例:
> - https://github.com/coral-xyz/anchor/tree/master/examples/tutorial

一个Anchor工程主要包含:

- "declare_id"宏声明的合约地址，用于创建对象的owner
- #[derive(Accounts)] 修饰的Account对象，用于表示存储和指令, 包含了指令执行所要用到的账户
- "program" 模块，这里面写主要的合约处理逻辑

对应到我们之前的HelloWorld，就是要将state和instruction部分用 #[derive(Accounts)] 修饰，将process逻辑放到program模块中，并增加一个合约地址的修饰。

#[program] 修饰的Module即为指令处理模块。其中有一个Context类型，来存放所有的指令参数。比如

- ctx.accounts 所有的请求keys，也就是AccountMeta数组
- ctx.program_id 指令中的program_id
- ctx.remaining_accounts 指令中，没有被下面说的"Accounts"修饰的成员的AccountMeta


```rust
use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
mod basic_1 {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, data: u64) -> Result<()> {
        let my_account = &mut ctx.accounts.my_account;
        my_account.data = data;
        Ok(())
    }

    pub fn update(ctx: Context<Update>, data: u64) -> Result<()> {
        let my_account = &mut ctx.accounts.my_account;
        my_account.data = data;
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = user, space = 8 + 8)]
    pub my_account: Account<'info, MyAccount>,
    #[account(mut)]
    pub user: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Update<'info> {
    #[account(mut)]
    pub my_account: Account<'info, MyAccount>,
}

#[account]
pub struct MyAccount {
    pub data: u64,
}
```

