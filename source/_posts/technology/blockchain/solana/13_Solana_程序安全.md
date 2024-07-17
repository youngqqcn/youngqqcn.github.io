---
date: 2024-07-17 18:44
title: 13_Solana_程序安全
categories: 技术
tags:
- 区块链
- Solana
- 交易
- Token
- Anchor
- 安全
---


> https://www.soldev.app/course/signer-auth


### 案例1: 缺少Signer Authentication

```rust
use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod insecure_update{
    use super::*;
    // ...

    pub fn update_authority(ctx: Context<UpdateAuthority>) -> Result<()> {
        ctx.accounts.vault.authority = ctx.accounts.new_authority.key();
        Ok(())
    }
}

#[derive(Accounts)]
pub struct UpdateAuthority<'info> {
   #[account(
        mut,
        has_one = authority
    )]
    pub vault: Account<'info, Vault>,
    pub new_authority: AccountInfo<'info>,
    pub authority: AccountInfo<'info>,
}

#[account]
pub struct Vault {
    token_account: Pubkey,
    authority: Pubkey,
}
```


漏洞分析： 虽然有 `has_one = authority`, 但它仅检查 `vault.authority.pubkey == authority.pubkey`, 即检查调用程序的参数中的`authority`是否和程序中的`vault`的`authority`是否一致, 并没有检查**调用者**是否是`authority`。 因此，存在被攻击的风险，即任何人只要将调用参数中的`authority`设置为和`vault`中的`authority` 一致， 都可以成功调用`update_authority`



漏洞修复:
- 方案1：使用 `ctx.accounts.authority.is_signer` 判断 authority是否是交易的signer
  - 缺点： 账户验证和指令逻辑验证是一起的（没有分离）
- 方案2：使用 Anchor的 `Singer`
  - 优点： 账户验证和指令逻辑验证是分开, 在进入逻辑之前就已经做了校验
  - 缺点: 只能和Singer账户一起,不能和其他账户类型
- 方案3: 使用 `#[account(singer)]`
  - 作用和 `Signer`是一样，但是比 `Signer` 更灵活，支持更多账户类型
  - 比如，
    ```rust
    #[account(signer)]
    pub authority: Account<'info, SomeData>
    ```


```rust
use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod secure_update{
    use super::*;
    // ...
    pub fn update_authority(ctx: Context<UpdateAuthority>) -> Result<()> {
        // Signer中已经做了检查
        // if !ctx.accounts.authority.is_signer {
        //     return Err(ProgramError::MissingRequiredSignature.into());
        // }

        ctx.accounts.vault.authority = ctx.accounts.new_authority.key();
        Ok(())
    }
}

#[derive(Accounts)]
pub struct UpdateAuthority<'info> {
    #[account(
        mut,
        has_one = authority
    )]
    pub vault: Account<'info, Vault>,
    pub new_authority: AccountInfo<'info>,
    pub authority: Signer<'info>,
}

#[account]
pub struct Vault {
    token_account: Pubkey,
    authority: Pubkey,
}
```


### 案例2： Missing owner check

```rust
use anchor_lang::prelude::*;

declare_id!("Cft4eTTrt4sJU4Ar35rUQHx6PSXfJju3dixmvApzhWws");

#[program]
pub mod owner_check {
    use super::*;
	...

    pub fn admin_instruction(ctx: Context<Unchecked>) -> Result<()> {
        let account_data = ctx.accounts.admin_config.try_borrow_data()?;
        let mut account_data_slice: &[u8] = &account_data;
        let account_state = AdminConfig::try_deserialize(&mut account_data_slice)?;

        if account_state.admin != ctx.accounts.admin.key() {
            return Err(ProgramError::InvalidArgument.into());
        }
        msg!("Admin: {}", account_state.admin.to_string());
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Unchecked<'info> {
    admin_config: AccountInfo<'info>,
    admin: Signer<'info>,
}

#[account]
pub struct AdminConfig {
    admin: Pubkey,
}
```