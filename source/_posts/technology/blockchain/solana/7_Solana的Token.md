---
date: 2024-07-09 19:54
title: 7_Solana的Token
categories: 技术
tags:
- 区块链
- Solana
- 交易
- Token
---



# Solana的Token

> https://solana.com/docs/core/tokens

- https://x.com/pencilflip/status/1454141877972779013

- SPL Token官方文档: https://spl.solana.com/associated-token-account

### 关键点

- Token代表了同质化和非同质化的资产的所有权
- Token Program 包含了所有与token交互所需要的指令
- Token Extensions Program 是新版程序，包含了额外的特性
- **Mint Account**: 代表了一个唯一的代币
- Token Account:
  - A Token Account tracks individual ownership of tokens for a specific mint account.
- **Associated Token Account (ATA)**: 由 owner地址 和 Mint Account地址派生出来的 Token Account
  - An Associated Token Account(ATA) is a **Token Account** created with an address derived from the owner's and mint account's addresses.

### Token Program

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/token-program.svg)


- `InitializeMint`: 发行代币
  - Create a new mint account to represent a new type of token.
- `InitializeAccount`:  创建ATA账号
  - Create a new token account to hold units of a specific type of token (mint).
- `MintTo`: 增发代币。
  - Create new units of a specific type of token and add them to a token account. This increases the supply of the token and can only be done by the mint authority of the mint account.
- `Transfer`: 转移Token
  - Transfer units of a specific type of token from one token account to another.


### Mint Account

- Supply: token 的总发行量
- Decimals: 精度
- Mint authority: 持有*增发token权限*账户, 可以增发token
- Freeze authority: 持有*冻结转移*的账户, 即将某个用户账户"拉黑"
  - The account authorized to freeze tokens from being transferred from "token accounts"

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/mint-account.svg)

```rust
pub struct Mint {
    /// Optional authority used to mint new tokens. The mint authority may only
    /// be provided during mint creation. If no mint authority is present
    /// then the mint has a fixed supply and no further tokens may be
    /// minted.
    pub mint_authority: COption<Pubkey>,
    /// Total supply of tokens.
    pub supply: u64,
    /// Number of base 10 digits to the right of the decimal place.
    pub decimals: u8,
    /// Is `true` if this structure has been initialized
    pub is_initialized: bool,
    /// Optional authority to freeze token accounts.
    pub freeze_authority: COption<Pubkey>,
}
```

例如 USDC的Mint Account : https://explorer.solana.com/address/EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v



### Token Account

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/token-account.svg)


- `Mint`: 执行特定的Mint Account
  - The type of token the Token Account holds units of
- `Owner`: The account authorized to transfer tokens out of the Token Account
  - 该Token Account 的所有者，有权转移该Token Account上的token
  - 注意： AccountInfo中owner 和 AccountInfo Data中的owner 是不同的，前者是Program的owner（即Token Program地址, 所有Token Account的owner都是 Token Program）, 后者是 Token Account的所有者(即用户的钱包地址)
    >原文： Note that each Token Account's data includes an owner field used to identify who has **authority over that specific Token Account**. This is separate from the **program owner** specified in the AccountInfo, which is the Token Program for all Token Accounts.
- `Amount`: Units of the token the Token Account currently holds
  - 余额


```rust
pub struct Account {
    /// The mint associated with this account
    pub mint: Pubkey,
    /// The owner of this account.
    pub owner: Pubkey,
    /// The amount of tokens this account holds.
    pub amount: u64,
    /// If `delegate` is `Some` then `delegated_amount` represents
    /// the amount authorized by the delegate
    pub delegate: COption<Pubkey>,
    /// The account's state
    pub state: AccountState,
    /// If is_native.is_some, this is a native token, and the value logs the
    /// rent-exempt reserve. An Account is required to be rent-exempt, so
    /// the value is used by the Processor to ensure that wrapped SOL
    /// accounts do not drop below this threshold.
    pub is_native: COption<u64>,
    /// The amount delegated
    pub delegated_amount: u64,
    /// Optional authority to close the account.
    pub close_authority: COption<Pubkey>,
}
```


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/token-account-relationship.svg)




### Associated Token Account

> https://solana.com/docs/core/tokens#associated-token-account

- Associated Token Account (ATA) 是一个 Token Account, 这个token account的地址是确定的，通过 owner的地址 和 Mint Account的地址一起生成出来的。你可以认为**ATA就是每个用户的默认Token Account**
  > 原文：An Associated Token Account is a token account whose address is deterministically derived using the owner's address and the mint account's address. You can think of the Associated Token Account as the "default" token account for a specific mint and owner.

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/associated-token-account.svg)

获取 ATA

```ts
import { getAssociatedTokenAddressSync } from "@solana/spl-token";

const associatedTokenAccountAddress = getAssociatedTokenAddressSync(
  USDC_MINT_ADDRESS,
  OWNER_ADDRESS,
);

```

或者，通过`PDA`的方式生成 ATA

```ts
import { PublicKey } from "@solana/web3.js";

const [PDA, bump] = PublicKey.findProgramAddressSync(
  [
    OWNER_ADDRESS.toBuffer(),
    TOKEN_PROGRAM_ID.toBuffer(),
    USDC_MINT_ADDRESS.toBuffer(),
  ],
  ASSOCIATED_TOKEN_PROGRAM_ID,
);
```

对于每个代币(即Mint Account), 每个钱包账户都有一个自己的 Token Account(也可以叫ATA)， 如下图：


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/token-account-relationship-ata.svg)



### 创建Token Metadata

需要使用`Token Extensions Program `


> https://solana.com/docs/core/tokens#create-token-metadata


```bash
spl-token create-token --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
--enable-metadata
```

```rust
pub struct TokenMetadata {
    /// The authority that can sign to update the metadata
    pub update_authority: OptionalNonZeroPubkey,
    /// The associated mint, used to counter spoofing to be sure that metadata
    /// belongs to a particular mint
    pub mint: Pubkey,
    /// The longer name of the token
    pub name: String,
    /// The shortened symbol for the token
    pub symbol: String,
    /// The URI pointing to richer metadata
    pub uri: String,
    /// Any additional metadata about the token as key-value pairs. The program
    /// must avoid storing the same key twice.
    pub additional_metadata: Vec<(String, String)>,
}
```

更多细节：https://solana.com/developers/guides/token-extensions/metadata-pointer
