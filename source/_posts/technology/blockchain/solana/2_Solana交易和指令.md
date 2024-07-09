---
date: 2024-07-09 19:15
title: 2_Solana交易和指令
categories: 技术
tags:
- 区块链
- Solana
- 交易
- 指令
---


# Solana的交易和指令

> https://solana.com/docs/core/transactions


关键细节：
- **执行顺序**： 如果交易包含多个指令，按照顺序执行（指令添加到交易中的顺序）
- **原子性**： 交易是原子性，只有当全部指令都执行成功，交易才成功，否则交易执行失败


关键点:

- 交易由不同指令组成，这些指令用来与链上不同的程序进行交互， 不同的指令代表不同的操作
- 每个指令指定3个要素, 见下文的`CompiledInstruction`结构体：
  - 程序id索引
  - 账户列表, 即指令所涉及的账户
  - 输入数据
- 交易中的指令，按照顺序执行
- 交易是原子性的
- 一笔交易最大为**1232 bytes**
  - Solana最大传输单元是1280字节, 这个值跟IPV6的MTU(最小传输单元) 一样， 为了UDP传输的效率。 详细见： https://solana.com/docs/core/transactions#transaction-size





### Transaction

- `recent_blockhash`用作交易的时间戳, 交易最大的age是 150 区块 （约1分钟），超过150区块就视为过期， 过期交易将不能执行
  - 可以通过`getLatestBlockHash`获取最新区块hash

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/transaction-simple.svg)

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/tx_format.png)

```rust
// https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/sdk/src/transaction/mod.rs#L173
pub struct Transaction {
    /// A set of signatures of a serialized [`Message`], signed by the first
    /// keys of the `Message`'s [`account_keys`], where the number of signatures
    /// is equal to [`num_required_signatures`] of the `Message`'s
    /// [`MessageHeader`].
    ///
    /// [`account_keys`]: Message::account_keys
    /// [`MessageHeader`]: crate::message::MessageHeader
    /// [`num_required_signatures`]: crate::message::MessageHeader::num_required_signatures
    // NOTE: Serialization-related changes must be paired with the direct read at sigverify.
    #[wasm_bindgen(skip)]
    #[serde(with = "short_vec")]
    pub signatures: Vec<Signature>,

    /// The message to sign.
    #[wasm_bindgen(skip)]
    pub message: Message,
}
```

### Message


```rust
pub struct Message {
    /// The message header, identifying signed and read-only `account_keys`.
    /// Header values only describe static `account_keys`, they do not describe
    /// any additional account keys loaded via address table lookups.
    pub header: MessageHeader,

    // 所有的需要使用到的账户数组
    /// List of accounts loaded by this transaction.
    #[serde(with = "short_vec")]
    pub account_keys: Vec<Pubkey>,

    // 用做交易的时间戳，也用于防止重复交易和过期交易
    // 交易最大的age是 150 区块 （约1分钟）
    /// The blockhash of a recent block.
    pub recent_blockhash: Hash,


    // 指令合集
    /// Instructions that invoke a designated program, are executed in sequence,
    /// and committed in one atomic transaction if all succeed.
    ///
    /// # Notes
    ///
    /// Program indexes must index into the list of message `account_keys` because
    /// program id's cannot be dynamically loaded from a lookup table.
    ///
    /// Account indexes must index into the list of addresses
    /// constructed from the concatenation of three key lists:
    ///   1) message `account_keys`
    ///   2) ordered list of keys loaded from `writable` lookup table indexes
    ///   3) ordered list of keys loaded from `readable` lookup table indexes
    #[serde(with = "short_vec")]
    pub instructions: Vec<CompiledInstruction>,

    /// List of address table lookups used to load additional accounts
    /// for this transaction.
    #[serde(with = "short_vec")]
    pub address_table_lookups: Vec<MessageAddressTableLookup>,
}

pub enum VersionedMessage {
    Legacy(LegacyMessage),
    V0(v0::Message),
}

pub struct VersionedTransaction {
    /// List of signatures
    #[serde(with = "short_vec")]
    pub signatures: Vec<Signature>,
    /// Message to sign.
    pub message: VersionedMessage,
}

// 消息头
// https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/sdk/program/src/message/mod.rs#L96
pub struct MessageHeader {
    /// The number of signatures required for this message to be considered
    /// valid. The signers of those signatures must match the first
    /// `num_required_signatures` of [`Message::account_keys`].
    // NOTE: Serialization-related changes must be paired with the direct read at sigverify.
    pub num_required_signatures: u8,

    /// The last `num_readonly_signed_accounts` of the signed keys are read-only
    /// accounts.
    pub num_readonly_signed_accounts: u8,

    /// The last `num_readonly_unsigned_accounts` of the unsigned keys are
    /// read-only accounts.
    pub num_readonly_unsigned_accounts: u8,
}
```
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/legacy_message.png)


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/message_header.png)

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/compat_array_of_account_addresses.png)

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/compact_array_of_ixs.png)




### 指令

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/instruction.svg)

```rust
// 交易中的结构是 CompiledInstruction
pub struct CompiledInstruction {
    // 索引
    /// Index into the transaction keys array indicating the program account that executes this instruction.
    pub program_id_index: u8,

    // 需要和合约交互账户
    /// Ordered indices into the transaction keys array indicating which accounts to pass to the program.
    #[serde(with = "short_vec")]
    pub accounts: Vec<u8>,

    // 输入数据
    /// The program input data.
    #[serde(with = "short_vec")]
    pub data: Vec<u8>,
}

// Instruction 是底层的数据结构
// https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/sdk/program/src/instruction.rs#L329
pub struct Instruction {
    /// Pubkey of the program that executes this instruction.
    #[wasm_bindgen(skip)]
    pub program_id: Pubkey,
    /// Metadata describing accounts that should be passed to the program.
    #[wasm_bindgen(skip)]
    pub accounts: Vec<AccountMeta>,
    /// Opaque data passed to the program for its own interpretation.
    #[wasm_bindgen(skip)]
    pub data: Vec<u8>,
}
```

### AccountMeta
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/accountmeta.svg)

```rust
// https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/sdk/program/src/instruction.rs#L539
pub struct AccountMeta {
    /// An account's public key.
    pub pubkey: Pubkey,
    /// True if an `Instruction` requires a `Transaction` signature matching `pubkey`.
    pub is_signer: bool,
    /// True if the account data or metadata may be mutated during program execution.
    pub is_writable: bool,
}
```

### 转移 SOL的交易示例图：

- 结构图

    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/sol-transfer.svg)


- SOL转账交易执行流程：

    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/sol-transfer-process.svg)






---

## 交易确认&过期

> https://solana.com/docs/advanced/confirmation


- 过期时间 `151`个区块, 每个区块`400ms`, 即 `60s`
- 交易中的recentBlockHash必须是151区块内, 否则将是过期交易

## 一些建议

- 建议1： 调用`getLatestBlockhash`时， 推荐使用 `confired`
  - `proceeded`: 已处理, 很激进，速度最快，但有可能被跳过
    - 用这种级别的交易中，有约`5%`交易会被验证节点丢弃
  - `confirmed`: 已被多个验证节点确认, 折衷方案
    - 这个级别，比较稳妥，因为被多个节点确认，之后被丢弃的几率很小
  - `finalized`: 最终确认, 太保守, 交易不会被丢弃
    - 即`32`个slot确认, 需要`12.8s`

- 建议2：在`sendTransaction`和 `simulateTransaction`时使用， 要设置相同的 `preflightCommitment`, 即都设置 `confirmed`

- 建议3：使用可靠的RPC节点，不要用落后的RPC节点
- 建议4：不要用过期的blockhash, 而是在签名前实时获取最新的blockHash
 - 前端应用要一直轮询最新的区块hash, 确保用户在触发交易时，获取的区块是最新的
 - 钱包要一直轮询最新的区块hash, 并刷新交易中的区块hash,确保用户签名时用的是最新的区块hash
- 建议5：使用健康的RPC节点获取区块hash
- 其他建议



----

## Solana交易重试

> https://solana.com/docs/advanced/retry

- RPC节点会尝试重新广播
- 开发者可以实现自定义的重新广播逻辑
- 开发者可以利用 `sendTransaction`的 `maxRetries`参数
- 开发者在提交交易前，应该执行预检(preflight), 如: `simulattionTransaction`
- 在对重试交易进行签名交易前，**必须**确保之前那笔交易中的区块hash已经过期，
  - 否则存在发起2笔交易的风险


### 交易的流程


Solana**没有交易池(mempool, txpool)**, 所有的交易都会转发给leaders节点执行

  ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/rt-tx-journey.png)


Transaction Processing Unit (TPU) 处理交易的阶段：

- Fetch Stage
- SigVerify Stage
- Banking Stage
- Proof of History Service
- Broadcast Stage


    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/rt-tpu-jito-labs.png)



### 交易被丢弃的几种情况


- 第1种： 开发者引用过期区块hash, 提交交易时被RPC pool丢弃 ，这种是最常见的
  ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/rt-dropped-via-rpc-pool.png)


- 第2种： 临时分叉， 引用了被丢弃的分叉区块hash
  ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/rt-dropped-minority-fork-pre-process.png)


- 第3种：  临时分叉， 引用了被丢弃的分叉区块hash
  ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/rt-dropped-minority-fork-post-process.png)





