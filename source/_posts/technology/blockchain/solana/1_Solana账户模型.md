---
date: 2024-07-09 18:52
title: 1_Solana账户模型
categories: 技术
tags:
- 区块链
- Solana
---


# 深入理解 Solana 账户模型
- 官方文档(推荐)：https://solana.com/docs/core/accounts

- 账户模型:
  - 推荐: https://x.com/pencilflip/status/1452402100470644739
  - https://solanacookbook.com/zh/core-concepts/accounts.html#%E8%B4%A6%E6%88%B7%E6%A8%A1%E5%9E%8B
  - https://solana.wiki/docs/solidity-guide/accounts/

- 不同于以太坊中只有智能合约可以存储状态, solana中所有账户都可以存储状态(数据)
- solana的智能合约(可执行账户)仅存储程序代码(不可变)， 不存储状态
  - 可升级(整体)： https://solana.com/docs/core/programs#updating-solana-programs
  - 不可变(字节码不可变): https://solana.wiki/docs/solidity-guide/accounts/
  - 关于这个"可升级"和"不可变"，可以看Solana的账户模型, solana程序账户的指令也是存储在一个特殊的数据账户中，因此"可升级"
- solana中的智能合约(可执行账户)的状态存储在其他账户(不可执行,但可变)中
  - 这些存储状态的账户(数据账户)，其owner是程序(可执行账户)
- solana中每个账户有一个owner，仅owner可以修改账户状态
- solana提供了很多有用的系统程序(合约), 属于runtime运行时
  - https://docs.solanalabs.com/runtime/programs
  - System Program:
    - 功能:
      - 创建新账户, **只有 System Program 可以创建新账户**
      - 分配新账户的权限，一旦创建新账户，**就可以转移账户权限给其他程序**
        > 为自定义程序创建一个数据账户(Data Account)，可以分为2步：
        > - 1, 调用 System Program 创建一个账户，然后将权限转移给自定义程序
        > - 2, 调用自定义程序(此时是账户的owner)初始化该账户的数据
      - 分配数据空间
      - 转移普通账户(owner是 System Program)的余额
      - 仅owner是 System Program 可以支付手续费
    - Program id: `11111111111111111111111111111111`
    - Instructions: SystemInstruction
  - BPF Loader Program
    - 功能：
      - 是所有自定义程序的owner
      - Deploys, upgrades, and executes programs on the chain.
    - Program id: `BPFLoaderUpgradeab1e11111111111111111111111`
    - Instructions: LoaderInstruction
  - SPL Token
    - TODO  :



```rust
pub struct Account {
    /// 账户余额
    /// lamports in the account
    pub lamports: u64,


    // 合约数据
    /// data held in this account
    #[serde(with = "serde_bytes")]
    pub data: Vec<u8>,

    // 所有者:
    //    on-chain program
    //     可以写入
    //     可花费lanport
    /// the program that owns this account. If executable, the program that loads this account.
    // This field stores the address of an on-chain program and represents which on-chain program is allowed to write to the account’s data and subtract from its lamport balance.
    pub owner: Pubkey,

    // 是否可执行
    /// this account's data contains a loaded program (and is now read-only)
    pub executable: bool,


    /// the epoch at which this account will next owe rent
    pub rent_epoch: Epoch,
}
```

### 程序账户(Program Account)

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/program-account-expanded.svg)


简化版如下：
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/program-account-simple.svg)



### 数据账户(Data Account)

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/data-account.svg)


为自定义程序创建一个数据账户(Data Account)，可以分为2步：
- 1, 调用 System Program 创建一个账户，然后将权限转移给自定义程序
- 2, 调用自定义程序(此时是账户的owner)初始化该账户的数据


### Solana账户规则：

> https://solana.wiki/docs/solidity-guide/accounts/#solana-runtime-account-rules

- 不可变性:
  - 可执行账户完全不可变
- **数据分配**
  - 仅` System Program ` 可以更改账户数据大小
  - 新分配的账户数据总是归零的
  - 账户数据大小不可缩小
  > 在写入期间，**程序不能增加其拥有的账户数据大小**, 如果需要更多数据，必须将数据拷贝到更大账户中，因此，**程序不会在账户中存储动态大小的maps和数组，而是，将数据存储在多个账户中**

- 数据
  - 每个账户最多 10MB 数据（代码 或 状态）
  - 只有账户的owner才可以修改数据
  - 账户只有处于数据归零状态下才可以分配新的owner
- 余额
  - 只有账户的owner可以减少余额
  - 任何程序账户都可以账户增加余额（转移）
  > 如果一个账户的owner是程序，那么，不能通过私钥操作该账户的余额，因为，私钥账户(普通账户)的owner是System Program, 而System Program 不是该账户的owner, 因此就不能操作该账户的余额

- 所有权
  - 只有账户owner可以制定新的账户owner

- 租金
  - 租金每2天(1个epoch)更新一次，由账户大小决定
  - 如果账户的余额大于2年的租金(预存), 那么，该账户可以免除租金(不用交房租)

- 余额为0的账户
  - 余额为0的账户，在交易执行后会被系统删除
  - 一个交易中可以创建临时余额为0的账户
- 新的执行账户
  - 只有制定的loader program可以修改账户的可执行状态
