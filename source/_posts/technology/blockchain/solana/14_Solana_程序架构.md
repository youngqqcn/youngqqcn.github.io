---
date: 2024-07-22 18:14
title: 14_Solana_程序架构
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


> https://www.soldev.app/course/program-architecture


### 处理大账户 Dealing With Large Accounts

- Solana上存储每个字节都需要支付相应的租金
- 大数据限制:
  - Stack(栈)限制: `4KB`
  - Heap(堆)限制: `32KB`
    - `Box`: 小于`32KB`
    - `zero copy`: 处理大于`32KB`
  -  大于 `10KB`的账户，CPI有限制




- Anchor中字段大小:
  - https://book.anchor-lang.com/anchor_references/space.html

  - `String`: `4 + 字符串字节长度`
  - `Vec<T>`: 	`4 + (space(T) * amount)`
  - `Pubkey`:	`32`
  - `Option<T>`	`1 + (space(T))`
  - `Enum`	: `1 + 最大变量的size`
  - `f32` 和 `f64` : 会序列化失败 `NaN`



- Box，在堆上分配内存

    ```rust
    #[account]
    pub struct SomeBigDataStruct {
        pub big_data: [u8; 5000], // 5000字节超出了solana的4KB栈限制，因此使用Heap
    }

    #[derive(Accounts)]
    pub struct SomeFunctionContext<'info> {
        pub some_big_data: Box<Account<'info, SomeBigDataStruct>>, // 在堆上分配内存
    }
    ```

- Zero Copy
    > https://docs.rs/anchor-lang/latest/anchor_lang/attr.account.html

    ```rust
    #[account(zero_copy)]
    pub struct SomeReallyBigDataStruct {
        pub really_big_data: [u128; 1024], // 16,384 bytes
    }

    pub struct ConceptZeroCopy<'info> {
        #[account(zero)]
        pub some_really_big_data: AccountLoader<'info, SomeReallyBigDataStruct>,
    }
    ```






### 处理账户 Dealing With Accounts


- **数据顺序**: `变长`字段放在账户结构尾部
  - 因为变长的字段放在签名，通过filter查询后面的字段时，无法确定偏移量offset，
- **预留字段**: 为账户增加一个预留字段
  - v1版本
    ```rust
        #[account]
        pub struct GameState { //V1
            pub health: u64,
            pub mana: u64,
            pub for_future_use: [u8; 128],
            pub event_log: Vec<string>
        }
    ```
  - v2版本:   v1 和 2 版本是兼容的
    ```rust
        #[account]
        pub struct GameState { //V2
            pub health: u64,
            pub mana: u64,
            pub experience: u64,  // 新增
            pub for_future_use: [u8; 120],
            pub event_log: Vec<string>
        }
    ```

- **数据优化**: 通过优化账户数据结构节约空间
  - 例如: 能用 `u8`的，就不要用`u64` ,
    ```rust
    #[account]
    pub struct BadGameFlags { // 8 bytes , 每个 bool 是一个字节
        pub is_frozen: bool,
        pub is_poisoned: bool,
        pub is_burning: bool,
        pub is_blessed: bool,
        pub is_cursed: bool,
        pub is_stunned: bool,
        pub is_slowed: bool,
        pub is_bleeding: bool,
    }

    // 优化后:
    const IS_FROZEN_FLAG: u8 = 1 << 0;
    const IS_POISONED_FLAG: u8 = 1 << 1;
    const IS_BURNING_FLAG: u8 = 1 << 2;
    const IS_BLESSED_FLAG: u8 = 1 << 3;
    const IS_CURSED_FLAG: u8 = 1 << 4;
    const IS_STUNNED_FLAG: u8 = 1 << 5;
    const IS_SLOWED_FLAG: u8 = 1 << 6;
    const IS_BLEEDING_FLAG: u8 = 1 << 7;
    const NO_EFFECT_FLAG: u8 = 0b00000000;
    #[account]
    pub struct GoodGameFlags { // 1 byte
        pub status_flags: u8,
    }
    ```
- **PDA账户结构设计**:

    | PDA对应关系 | 示例 |  应用场景 |
    |---------|---------------|---------------|
    | One-Per-Program (全局账户)  | `seeds=[b"global config"]` | 全局配置 |
    | One-Per-Owner  | `seeds=[b"player", owner.key().as_ref()]` | 游戏/DEX/... |
    | Multiple-Per-Owner | `seeds=[b"podcast", owner.key().as_ref(), episode_title.as_bytes().as_ref()]` | 播客频道(多季) |
    | One-Per-Owner-Per-Account| `seeds=[b"ATA Account", owner.key().as_ref(), mint.key().as_ref()]` | SPL Token的 ATA |





### 处理并发 Dealing With Concurrency


- solana的交易可以并行处理
- 对于互不关联账户的交易，都是并行处理
- 对于`共享`的账户的`写入`的交易，采用类似`互斥量`机制，因此是串行的


对于瓶颈的优化方案：
- 采用`分离`方案，减少`全局共享`的`写入`的账户


例如:

```

[TxA]  [TxB] ....[TxX]
 |      |          |
 V      V          V
[平台手续费金额总账户]

```


优化成


```
[TxA]  [TxB] ....[TxX]
 |      |          |    <--- 交易内执行
 V      V          V
[PA]   [PB]       [PX]  <--- 和用户账户关联的PDA账户
 |      |          |    <--- 异步执行
 V      V          V
[平台手续费金额总账户]

```

这样， 每个用户的交易 只会和自己账户关联的PDA账户有交互，而不会互相影响




----


### 状态压缩 State Compression

> https://www.soldev.app/course/generalized-state-compression

- 压缩NFT (cNFT)