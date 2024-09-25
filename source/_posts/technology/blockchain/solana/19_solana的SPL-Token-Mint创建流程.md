---
date: 2024-09-25 11:34
title: 19_solana的SPL Token Mint创建流程
categories: 技术
tags:
- 区块链
- Solana
- 高级
---


> 问题: 为什么创建token mint时，除了提供mint的pubkey之外，还需要提供mint的私钥来签名？



分析 `spl-token`库中的 `createMint`函数，

```js
export async function createMint(
    connection: Connection,
    payer: Signer,
    mintAuthority: PublicKey,
    freezeAuthority: PublicKey | null,
    decimals: number,
    keypair = Keypair.generate(),
    confirmOptions?: ConfirmOptions,
    programId = TOKEN_PROGRAM_ID
): Promise<PublicKey> {
    const lamports = await getMinimumBalanceForRentExemptMint(connection);

    const transaction = new Transaction().add(
        SystemProgram.createAccount({
            fromPubkey: payer.publicKey,
            newAccountPubkey: keypair.publicKey,
            space: MINT_SIZE,
            lamports,
            programId,
        }),
        createInitializeMint2Instruction(keypair.publicKey, decimals, mintAuthority, freezeAuthority, programId)
    );

    await sendAndConfirmTransaction(
        connection,
        transaction,
        [
            payer, // 支付手续费
            keypair // 问题：为什么需要提供 mint的私钥签名？
        ],
        confirmOptions
    );

    return keypair.publicKey;
}



export function createInitializeMint2Instruction(
    mint: PublicKey,
    decimals: number,
    mintAuthority: PublicKey,
    freezeAuthority: PublicKey | null,
    programId = TOKEN_PROGRAM_ID
): TransactionInstruction {


    const keys = [{
        pubkey: mint,
        isSigner: false,
        isWritable: true  // 为什么是Writeable?
    }];

    const data = Buffer.alloc(initializeMint2InstructionData.span);
    initializeMint2InstructionData.encode(
        {
            instruction: TokenInstruction.InitializeMint2,
            decimals,
            mintAuthority,
            freezeAuthority,
        },
        data
    );

    return new TransactionInstruction({ keys, programId, data });
}



```

其中, 包含了2条指令

- `SystemProgram.createAccount`:
  - 说明：**只用** SytemProgram可以创建新账户
  - 源码: https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/programs/system/src/system_processor.rs#L145

- `createInitializeMint2Instruction`:
  - 源码: https://github.com/solana-labs/solana-program-library/blob/1044fe47f7bf005b64c11a8a867b911ae13ae442/token/program/src/processor.rs#L29



我们逐个分析

首先我们分析 `SystemProgram.createAccount`的源码

客户端源码:
```js

static createAccount(params: CreateAccountParams): TransactionInstruction;

type CreateAccountParams = {
    /** The account that will transfer lamports to the created account */
    fromPubkey: PublicKey;
    /** Public key of the created account */
    newAccountPubkey: PublicKey;
    /** Amount of lamports to transfer to the created account */
    lamports: number;
    /** Amount of space in bytes to allocate to the created account */
    space: number;

    // 这里 programId, 即 TOKEN_PROGRAM_ID , TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
    /** Public key of the program to assign as the owner of the created account */
    programId: PublicKey;
};
```

根据代码注释可知， 其中 `programId`被用作 `owner`， 即 Token Mint账户的`owner`, 即: `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`


```rust
#[allow(clippy::too_many_arguments)]
fn create_account(
    from_account_index: IndexOfAccount,
    to_account_index: IndexOfAccount,
    to_address: &Address,
    lamports: u64,
    space: u64,
    owner: &Pubkey, // 根据上面分析可知，owner即是 TOKEN_PROGRAM_ID
    signers: &HashSet<Pubkey>,
    invoke_context: &InvokeContext,
    transaction_context: &TransactionContext,
    instruction_context: &InstructionContext,
) -> Result<(), InstructionError> {
    // if it looks like the `to` account is already in use, bail
    {
        let mut to = instruction_context
            .try_borrow_instruction_account(transaction_context, to_account_index)?;

        // 如果账户已经存在，则不能创建
        if to.get_lamports() > 0 {
            ic_msg!(
                invoke_context,
                "Create Account: account {:?} already in use",
                to_address
            );
            return Err(SystemError::AccountAlreadyInUse.into());
        }
        // 注意， 到此处为止， token mint的owner 是 SYSTEM_PROGRAM_ID

        // 分配空间， 并指派owner权限
        allocate_and_assign(&mut to, to_address, space, owner, signers, invoke_context)?;
    }

    // 注意， 到这里为止， token mint的owner 已经是 owner, 即 TOKEN_PROGRAM_ID

    // 交租金
    transfer(
        from_account_index,
        to_account_index,
        lamports,
        invoke_context,
        transaction_context,
        instruction_context,
    )
}

// 源码 https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/programs/system/src/system_processor.rs#L132
fn allocate_and_assign(
    to: &mut BorrowedAccount,
    to_address: &Address,
    space: u64,
    owner: &Pubkey,
    signers: &HashSet<Pubkey>,
    invoke_context: &InvokeContext,
) -> Result<(), InstructionError> {
    // 为新账户分配空间
    allocate(to, to_address, space, signers, invoke_context)?;

    // 为新账户指派owner
    assign(to, to_address, owner, signers, invoke_context)


}

//  源码  https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/programs/system/src/system_processor.rs#L70
fn allocate(
    account: &mut BorrowedAccount,
    address: &Address,
    space: u64,
    signers: &HashSet<Pubkey>,
    invoke_context: &InvokeContext,
) -> Result<(), InstructionError> {

    // 需要 Token Mint账户的签名
    if !address.is_signer(signers) {
        ic_msg!(
            invoke_context,
            "Allocate: 'to' account {:?} must sign",
            address
        );
        return Err(InstructionError::MissingRequiredSignature);
    }

    // if it looks like the `to` account is already in use, bail
    //   (note that the id check is also enforced by message_processor)
    if !account.get_data().is_empty() || !system_program::check_id(account.get_owner()) {
        ic_msg!(
            invoke_context,
            "Allocate: account {:?} already in use",
            address
        );
        return Err(SystemError::AccountAlreadyInUse.into());
    }

    if space > MAX_PERMITTED_DATA_LENGTH {
        ic_msg!(
            invoke_context,
            "Allocate: requested {}, max allowed {}",
            space,
            MAX_PERMITTED_DATA_LENGTH
        );
        return Err(SystemError::InvalidAccountDataLength.into());
    }

    // 设置账户空间
    account.set_data_length(space as usize)?;

    Ok(())
}


//  源码  https://github.com/solana-labs/solana/blob/27eff8408b7223bb3c4ab70523f8a8dca3ca6645/programs/system/src/system_processor.rs#L112
fn assign(
    account: &mut BorrowedAccount,
    address: &Address,
    owner: &Pubkey,
    signers: &HashSet<Pubkey>,
    invoke_context: &InvokeContext,
) -> Result<(), InstructionError> {
    // no work to do, just return
    if account.get_owner() == owner {
        return Ok(());
    }

    // 需要 Token Mint账户的签名
    if !address.is_signer(signers) {
        ic_msg!(invoke_context, "Assign: account {:?} must sign", address);
        return Err(InstructionError::MissingRequiredSignature);
    }

    // 设置owner
    account.set_owner(&owner.to_bytes())
}

```

从上面2处对Token Mint的账户判断 `address.is_signer(signers)`， 即需要token mint的签名。


到此为止， token mint的账户已经完成了创建，并且AccountInfo中的owner已经设置为 `TOKEN_PROGRAM_ID`

接下来，需要对 Token Mint账户的 AccountInfo中的data进行初始化，即对 Mint进行初始化

因为，此时 Token mint的账户的owner是 TOKEN_PROGRAM_ID, 因此， TOKEN程序是有权限直接修改 token mint的

解析来我们再分析`createInitializeMint2Instruction`

```rust

/// Processes an [InitializeMint2](enum.TokenInstruction.html) instruction.
pub fn process_initialize_mint2(
    accounts: &[AccountInfo],
    decimals: u8,
    mint_authority: Pubkey,
    freeze_authority: COption<Pubkey>,
) -> ProgramResult {
    Self::_process_initialize_mint(accounts, decimals, mint_authority, freeze_authority, false)
}

fn _process_initialize_mint(
    accounts: &[AccountInfo],
    decimals: u8,
    mint_authority: Pubkey,
    freeze_authority: COption<Pubkey>,
    rent_sysvar_account: bool,
) -> ProgramResult {
    let account_info_iter = &mut accounts.iter();

    //
    let mint_info = next_account_info(account_info_iter)?;
    let mint_data_len = mint_info.data_len();
    let rent = if rent_sysvar_account {
        Rent::from_account_info(next_account_info(account_info_iter)?)?
    } else {
        Rent::get()?
    };

    let mut mint = Mint::unpack_unchecked(&mint_info.data.borrow())?;
    if mint.is_initialized {
        return Err(TokenError::AlreadyInUse.into());
    }

    if !rent.is_exempt(mint_info.lamports(), mint_data_len) {
        return Err(TokenError::NotRentExempt.into());
    }

    mint.mint_authority = COption::Some(mint_authority);
    mint.decimals = decimals;
    mint.is_initialized = true;
    mint.freeze_authority = freeze_authority;


    // 将mint结构体，序列化到 mint_info.data， 这里需要提供mint_info的写入权限
    Mint::pack(mint, &mut mint_info.data.borrow_mut())?;

    Ok(())
}
```



至此，我们完整地分析了Token Mint的创建细节。


总结一下:

- 第1步， 通过调用系统程序的 `create_account` 创建新的`mint`账户，并分配空间，转入租金，并将owner设置为 Token Program
- 第2步， 通过 Token Program的 `process_initialize_mint2` 指令，对`mint`账户进行初始化

---

最后，我们回答一下，文章开头的问题：
> 问：为什么创建token mint账户时，除了提供mint的pubkey之外，还需要提供mint的私钥来签名？
> 答：因为在第1步调用系统程序的`create_account`时， 转移mint账户权限时需要校验账户签名，因此需要传入 mint的私钥。在`create_account`结束之后，mint账户的owner已经变成了 Token Program, 此后，就不再需要 mint的私钥了。



---
(完)