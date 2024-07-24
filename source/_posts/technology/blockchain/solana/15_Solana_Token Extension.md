---
date: 2024-07-23 9:34
title: 15_Solana_Token Extension
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


> https://www.soldev.app/course/intro-to-token-extensions-program

- Token Extension Program 是 Token Program 的超集

- Token Program 和 Token Extension Program 是2个程序
  - 两个程序的地址，不可以互换(`not interchangeable`)
- Token Extension 16种功能：
  > https://spl.solana.com/token-2022/extensions

  - **Account**:
    - `Memo`: 转账时需要增加备注
    - `Immutable ownership`:  ATA权限不可以转移
      - Token 2022的ATA权限默认是不可转移的
    - `Default account state`:  设置默认的账户状态，如：默认冻结
    - `CPI guard`: 对CPI做一些限制操作
  - **Mint**
    - `Transfer fees`: 项目方可以加入抽水功能
    - `Closing mint`: 关闭mint ， 方便跑路
      - 需要supply为0, 即，需要销毁所有token之后才能关闭mint
    - `Interest-bearing tokens`: 生息， 非常适合staking项目
    - `Non-transferable tokens`: 不可转移， 适合做灵魂绑定(`Soul-Bound`)
    - `Permanent delegate`: 永久代理，项目方可以控制一切账户，非常适合做中心化集权场景
    - `Transfer hook`: token转账的钩子， 可以增加自定义相关回调
    - `Metadata pointer`: 为token增加metadata
    - `Metadata`： 为token增加metadata ，一般和 `metadta pointer`一起用
    - `Group pointer`： 群组，适合做合集， 如NFT合集
    - `Group`: 同上
    - `Member pointer `： 成员
    - `Member`： 同上
    - `Confidential transfers`： 私密交易


## 使用命令行`spl-token`使用 Token 2022

> spl-token --create-token --help

### 创建 close authority token


获取solana配置信息，设置 `devnet`
```sh
$ solana config get
Config File: /home/yqq/.config/solana/cli/config.yml
RPC URL: https://api.devnet.solana.com
WebSocket URL: wss://api.devnet.solana.com/ (computed)
Keypair Path: /home/yqq/.config/solana/id.json
Commitment: confirmed
```

创建 close authority token

> 注意: spl-token 默认使用的 Token Program的program id, 如需使用Token 2022,则需要制定program id
> - `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` 是 Token 2022的program id
> - `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA` 是 Token Program的program id


```sh
spl-token create-token --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb --enable-close
```


创建ATA账户

```sh
spl-token create-account --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb

```

mint token, 注意必须指定program id, 因为 spl-token 默认使用旧版Token Program作为program id

```sh
spl-token mint --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb CisqmfLH8R2JnSYSA8tgW8LSG5hQPogYZKxxHv6H5aMq 1000000000  4tQwDVgmNYPxrdhmqVAza9qefkmPPhBrF1h75oMrfd2Q

Minting 1000000000 tokens
  Token: CisqmfLH8R2JnSYSA8tgW8LSG5hQPogYZKxxHv6H5aMq
  Recipient: 4tQwDVgmNYPxrdhmqVAza9qefkmPPhBrF1h75oMrfd2Q

Signature: YdAcA3VJ9ehFRKzZCbkwMvEMxVAMPVB7X7Cuu4pS7pXcUKjGWSB7siCywFG1wJGXqQVXK3HuTSje2dytrmHKFJg

```

直接关闭会报错，因为此时 supply不是0, 必须先销毁，然后才能close
```
$ spl-token close-mint CisqmfLH8R2JnSYSA8tgW8LSG5hQPogYZKxxHv6H5aMq
Error: "Mint CisqmfLH8R2JnSYSA8tgW8LSG5hQPogYZKxxHv6H5aMq still has 1000000000000000000 outstanding tokens; these must be burned before closing the mint."
```


销毁token

```sh
spl-token burn --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb 4tQwDVgmNYPxrdhmqVAza9qefkmPPhBrF1h75oMrfd2Q 1000000000

Burn 1000000000 tokens
  Source: 4tQwDVgmNYPxrdhmqVAza9qefkmPPhBrF1h75oMrfd2Q

Signature: K3v2mkrrdyqym9RHFWT2yo2RQ89zcZQaR6V6RW37ie44ob2Du4arTTym1FimpHLQ9FTHPd8zhdXxnjqU8tGWzZp

```


查看mint的信息， 此时 supply 为0, 可以进行close

```sh
$ spl-token display CisqmfLH8R2JnSYSA8tgW8LSG5hQPogYZKxxHv6H5aMq

SPL Token Mint
  Address: CisqmfLH8R2JnSYSA8tgW8LSG5hQPogYZKxxHv6H5aMq
  Program: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
  Supply: 0
  Decimals: 9
  Mint authority: 7DxeAgFoxk9Ha3sdciWE4G4hsR9CUjPxsHAxTmuCJrop
  Freeze authority: (not set)
Extensions
  Close authority: 7DxeAgFoxk9Ha3sdciWE4G4hsR9CUjPxsHAxTmuCJrop

```


进行close

```
$ spl-token close-mint CisqmfLH8R2JnSYSA8tgW8LSG5hQPogYZKxxHv6H5aMq

Signature: 2h9bLrRCcK1bSbavdtKHrHLV2FVJVtEQiCUXBDKZXwZwnGFSZMhiYLDpRCJ7pxgb4KKxc75zUbCgeo9SeM7sjheH

```

### 创建ATA权限不可转移的token 2022

创建 token,  token 2022 的ATA默认都是不可转移的，因此不需要制定额外参数

> 注意: spl-token 默认使用的 Token Program的program id, 如需使用Token 2022,则需要制定program id
> - `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` 是 Token 2022的program id
> - `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA` 是 Token Program的program id

```
$ spl-token create-token --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
Creating token HcGkiji8KimiZPTBf3SFCapAoR9NP63LdZtpv3719wdw under program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb

Address:  HcGkiji8KimiZPTBf3SFCapAoR9NP63LdZtpv3719wdw
Decimals:  9

Signature: 411LLtiDPB6Xgpq4kqsqp4K3atJCsTuWAHnAYaV6YaaMPDCYVTkRi6PWra7ixxMtWTbwyGeBxiZmfBfLjfeyZ6Q5

```



创建 ATA 账户

```sh
$ spl-token create-account --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb  HcGkiji8KimiZPTBf3SFCapAoR9NP63LdZtpv3719wdw
Creating account GfuBt164MUSThb3ZnhLfra8bbHzzrCvruXs5p7rC23LW

Signature: 3eRBFR52dhVBtad7sZs9s2i2h9Lw6W9TGvDdRQJ9DAiuEZPYoaHPEnqfCuoGzX6mDfTcPiP4wW7bdLzSQHtEzZLT
```


mint token

```sh
$ spl-token mint --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb HcGkiji8KimiZPTBf3SFCapAoR9NP63LdZtpv3719wdw 10000000 GfuBt164MUSThb3ZnhLfra8bbHzzrCvruXs5p7rC23LW
Minting 10000000 tokens
  Token: HcGkiji8KimiZPTBf3SFCapAoR9NP63LdZtpv3719wdw
  Recipient: GfuBt164MUSThb3ZnhLfra8bbHzzrCvruXs5p7rC23LW

Signature: 2ffKaX7XsK71GbpehqCgqsx9qVdGXSA28umQQ7guXN7Pv9ZzviRpCNyRuoPmFGwAtHANGzTs8TkWDMXJUT4m6vhP

```

查看余额

```sh
$ spl-token balance HcGkiji8KimiZPTBf3SFCapAoR9NP63LdZtpv3719wdw
10000000

```


查看ATA账户信息, 可以看到 `Immutable owner`

```sh
$ spl-token display GfuBt164MUSThb3ZnhLfra8bbHzzrCvruXs5p7rC23LW

SPL Token Account
  Address: GfuBt164MUSThb3ZnhLfra8bbHzzrCvruXs5p7rC23LW
  Program: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
  Balance: 10000000
  Decimals: 9
  Mint: HcGkiji8KimiZPTBf3SFCapAoR9NP63LdZtpv3719wdw
  Owner: 7DxeAgFoxk9Ha3sdciWE4G4hsR9CUjPxsHAxTmuCJrop
  State: Initialized
  Delegation: (not set)
  Close authority: (not set)
Extensions:
  Immutable owner

```





### 创建 灵魂绑定代币

创建 token,

- `--decimals 0 `
-  `--enable-metadata `
-  `--enable-non-transferable`

```
$ spl-token create-token --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb --decimals 0 --enable-metadata --enable-non-transferable
Creating token 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K under program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
To initialize metadata inside the mint, please run `spl-token initialize-metadata 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K <YOUR_TOKEN_NAME> <YOUR_TOKEN_SYMBOL> <YOUR_TOKEN_URI>`, and sign with the mint authority.

Address:  7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K
Decimals:  0

Signature: 4z1gNiFfLAkoe9RQD84N3vHh88ZNegZs2zL81ve1uKG8ijT6VGK4yuTYwjmLLCLgAXxRvCSUoMChneQZRCZXR7Wz

```



初始化metadata
```
$ spl-token initialize-metadata 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K YQQTOKEN YT https://arweave.net/7q03FecPFE5JBPDakJFDS7xvdKqw5NSlNPUFZOYVVlk

Signature: 3zxSfkAg32KavFJ3UNXAMs4KyogZwRNDjDWmD1z8PmmHLHsDaYinwpQwrsC7EnqFNSSTc5e6ohMaUvAT7N5UowbZ

```



查看token信息
```sh
$ spl-token display 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K

SPL Token Mint
  Address: 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K
  Program: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb
  Supply: 0
  Decimals: 0
  Mint authority: 7DxeAgFoxk9Ha3sdciWE4G4hsR9CUjPxsHAxTmuCJrop
  Freeze authority: (not set)
Extensions
  Non-transferable
  Metadata Pointer:
    Authority: 7DxeAgFoxk9Ha3sdciWE4G4hsR9CUjPxsHAxTmuCJrop
    Metadata address: 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K
  Metadata:
    Update Authority: 7DxeAgFoxk9Ha3sdciWE4G4hsR9CUjPxsHAxTmuCJrop
    Mint: 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K
    Name: YQQTOKEN
    Symbol: YT
    URI: https://arweave.net/7q03FecPFE5JBPDakJFDS7xvdKqw5NSlNPUFZOYVVlk

```




更新metadata
```sh
$ spl-token update-metadata 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K name YQQNFT

Signature: 2xRQhsQiyrG8FVe3JHSFsDYz4gy1RPD16ECZWBpfdCwRpCgnTUzEhDJJ9QNRmR4Qnga2xTua2jrYhy6PFizigun3

```



创建 ATA

```sh
$ spl-token create-account --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K
Creating account 64Sxa26sViFh9JKFM6tm7dEib3hLTxbRXvARjjLTCmeG

Signature: 3HvNKDiPa6QcihbgUB4pVsojtmq7khwqCDdTb1iwfwdbuexe3s3PNCipEL8MMQMCwFYEGFNnmdfohXJ6weUCZ4tw

```




mint token
```sh
$ spl-token mint --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K 1 64Sxa26sViFh9JKFM6tm7dEib3hLTxbRXvARjjLTCmeG
Minting 1 tokens
  Token: 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K
  Recipient: 64Sxa26sViFh9JKFM6tm7dEib3hLTxbRXvARjjLTCmeG

Signature: FijHaPESJUG4PgMWjxFcPwvH7GkvL1feQeg8KKHRsS2WmfDEWkutWniEFMyDNg76acU6bUeaQ97ywtWWW1Y8SbF

```



尝试转移 Token, 报错`Transfer is disabled for this mint`

```sh

$ spl-token transfer --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb 7R6uaZgMZgmfBRLJXXYHPRV8oysDokv8FHrZ7Td1xo5K 1 38jEaxphBTa3NEg4K6nG8Zgs6eVsSsr9AoSZCfax2pH8 --fund-recipient
Transfer 1 tokens
  Sender: 64Sxa26sViFh9JKFM6tm7dEib3hLTxbRXvARjjLTCmeG
  Recipient: 38jEaxphBTa3NEg4K6nG8Zgs6eVsSsr9AoSZCfax2pH8
  Recipient associated token account: 3XX7DysVrERAeTYFczEoKtwxqH6QqxWfUBcUBaZy1GZ4
  Funding recipient: 3XX7DysVrERAeTYFczEoKtwxqH6QqxWfUBcUBaZy1GZ4
Error: Client(Error { request: Some(SendTransaction), kind: RpcError(RpcResponseError { code: -32002, message: "Transaction simulation failed: Error processing Instruction 1: custom program error: 0x25", data: SendTransactionPreflightFailure(RpcSimulateTransactionResult { err: Some(InstructionError(1, Custom(37))), logs: Some(["Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL invoke [1]", "Program log: CreateIdempotent", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb invoke [2]", "Program log: Instruction: GetAccountDataSize", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb consumed 3064 of 22071 compute units", "Program return: TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb rgAAAAAAAAA=", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb success", "Program 11111111111111111111111111111111 invoke [2]", "Program 11111111111111111111111111111111 success", "Program log: Initialize the associated token account", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb invoke [2]", "Program log: Instruction: InitializeImmutableOwner", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb consumed 1924 of 14077 compute units", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb success", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb invoke [2]", "Program log: Instruction: InitializeAccount3", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb consumed 5815 of 9763 compute units", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb success", "Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL consumed 29823 of 33467 compute units", "Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL success", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb invoke [1]", "Program log: Instruction: TransferChecked", "Program log: Transfer is disabled for this mint", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb consumed 3644 of 3644 compute units", "Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb failed: custom program error: 0x25"]), accounts: None, units_consumed: Some(33467), return_data: None, inner_instructions: None }) }) })

```

---


## 在客户端中使用 Token 2022

> https://www.soldev.app/course/token-extensions-in-the-client

- `spl-token`默认使用 `Token Program`, 除非明确指定使用`Token Programs Extension`
  - Token Program: `TOKEN_PROGRAM_ID`
  - Token 2022: `TOKEN_2022_PROGRAM_ID`


[示例代码](https://github.com/youngqqcn/solana-course-source/blob/master/1_onchain_program_development/solana-token-2022/src/create-and-mint-token.ts)

```ts
const mint = await createMint(
    connection,
    payer,
    payer.publicKey,
    payer.publicKey,
    decimals,
    undefined,
    { commitment: connection.commitment },
    tokenProgramId  // 指定 Program Id 即可
);
```


-----


## 在Anchor使用 Token2022


在Anchor中使用 interface 类型来将 `Token Program` 和 `Token 2022` 融合到一起

```rust
use {
    anchor_lang::prelude::*,
    anchor_spl::{token_interface},
};

#[derive(Accounts)]
pub struct Example<'info>{
    // Token account
    #[account(
        token::token_program = token_program
    )]
    pub token_account: InterfaceAccount<'info, token_interface::TokenAccount>,
    // Mint account
    #[account(
        mut,
        mint::token_program = token_program
    )]
    pub mint_account: InterfaceAccount<'info, token_interface::Mint>,
    pub token_program: Interface<'info, token_interface::TokenInterface>,
}
```

- [Interface](https://docs.rs/anchor-lang/latest/anchor_lang/accounts/interface/index.html): 是 Program 的wrapper支持多种Program
- [TokenInterface](https://docs.rs/anchor-lang/latest/anchor_lang/accounts/interface_account/index.html): 支持 `Token Program` 和 `Token 2022`, 且仅支持这2种，如果传入其他的程序id会报错


- `InterfaceAccount`: 和 `Interface` 类似，也是一个wrapper, 用于 `AccountInfo`. `InterfaceAccount`



