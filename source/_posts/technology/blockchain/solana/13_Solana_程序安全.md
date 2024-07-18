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
> https://www.soldev.app/course/owner-checks

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


漏洞分析:

- `admin_instruction`: 检查的是有输入参数指定的程序状态(state)与参数是否匹配, 并没有检查数据账户的owner是不是本程序帐户

    如下图, 攻击这将B数据账户传入给A程序，可以通过A程序的简单校验，从而修改A数据账户的状态

    ```
    [A程序账户]        [B程序账户]
       |                 |
       |                 |
    [A数据账户]        [B数据账户]
    ```


- [攻击案例-国库提币攻击](https://github.com/youngqqcn/solana-course-source/blob/master/1_onchain_program_development/solana-owner-checks-starter/programs/solana-owner-checks-starter/src/lib.rs)

  - 攻击者的合约，
    ```rust
    #[account]
    pub struct Vault {
        // 必须保持和被攻击者的账户结构体同名, 即必须Vault， 因为结构体名称的hash作为账户的 Discriminator,
        // 否则被攻击合约序列化的时候报错: Error Message: 8 byte discriminator did not match what was expected

        // 必须保持和被攻击账户的数据结构顺序一致,
        // 结构体内部变量名称可以不同,
        token_accountxx: Pubkey,
        authorityx: Pubkey,
    }
    ```
  - 漏洞修复： 将 vault的 `UncheckedAccount` 改成 `Account`, anchor为Account实现了owner安全检查
    ```rust
    #[derive(Accounts)]
    pub struct SecureWithdraw<'info> {
        /// 具体检查如下:
        // has_one:
        //     input_args.token_account.key == vault.token_account.key
        //     input_args.authority.key == vault.authority.key
        // Acccount的Owner trait 安全检查
        //    Account.info.owner == T::owner()
        //   `!(Account.info.owner == SystemProgram && Account.info.lamports() == 0)`
        #[account(has_one=token_account, has_one=authority)]
        pub vault: Account<'info, Vault>,

        #[account(mut, seeds=[b"token"], bump)]
        pub token_account: Account<'info, TokenAccount>,
        #[account(mut)]
        pub withdraw_destination: Account<'info, TokenAccount>,
        pub token_program: Program<'info, Token>, // SPL Token Program固定是 TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
        pub authority: Signer<'info>,
    }
    ```


### 案例3： Account Data Matching

> https://www.soldev.app/course/account-data-matching

```rust
use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod data_validation {
    use super::*;
    ...
    pub fn update_admin(ctx: Context<UpdateAdmin>) -> Result<()> {
        ctx.accounts.admin_config.admin = ctx.accounts.new_admin.key();
        Ok(())
    }
}

#[derive(Accounts)]
pub struct UpdateAdmin<'info> {
    #[account(mut)]
    pub admin_config: Account<'info, AdminConfig>,
    #[account(mut)]
    pub admin: Signer<'info>,
    pub new_admin: SystemAccount<'info>,
}

#[account]
pub struct AdminConfig {
    admin: Pubkey,
}
```

- 漏洞分析:
  - `update_config`缺少校验: `ctx.accounts.admin_conifg.admin == ctx.accounts.admin`


- 漏洞修复:
  - 方案1： 在`update_admin`增加校验 `ctx.accounts.admin_conifg.admin == ctx.accounts.admin`
  - 方案2： 使用`has_one`约束, 为`admin_config`增加约束 `#[account(has_one = admin)]`, 这样和方案1等效
  - 方案3： 使用`constraint`约束, 为`admin_config`增加约束 `#[account(constraint = admin_config.admin == admin.key())]`, 这样和方案1等效



[示例代码](https://github.com/youngqqcn/solana-course-source/blob/master/1_onchain_program_development/anchor-account-data-matching/programs/anchor-account-data-matching/src/lib.rs)

```rust
//...
    pub fn insecure_withdraw(ctx: Context<InsecureWithdraw>) -> Result<()> {
        // 缺少对 authority的校验
        let amount = ctx.accounts.token_account.amount;

        let seeds = &[b"vault".as_ref(), &[ctx.bumps.vault]];
        let signer = [&seeds[..]];

        let cpi_ctx = CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            token::Transfer {
                from: ctx.accounts.token_account.to_account_info(),
                authority: ctx.accounts.vault.to_account_info(),
                to: ctx.accounts.withdraw_destination.to_account_info(),
            },
            &signer,
        );

        token::transfer(cpi_ctx, amount)?;
        Ok(())
    }
// ...

#[derive(Accounts)]
pub struct InsecureWithdraw<'info> {
    #[account(
        seeds = [b"vault"],
        bump,
        // 缺少对 authority的校验
    )]
    pub vault: Account<'info, Vault>,

    #[account(
        mut,
        seeds = [b"token"],
        bump,
    )]
    pub token_account: Account<'info, TokenAccount>,
    #[account(mut)]
    pub withdraw_destination: Account<'info, TokenAccount>,
    pub token_program: Program<'info, Token>,
    pub authority: Signer<'info>,
}

#[account]
pub struct Vault {
    token_account: Pubkey,
    authority: Pubkey,
    withdraw_destination: Pubkey,
}
```


修复方案: 为 vault增加约束

```rust
    #[account(
        mut,
        seeds = [b"vault"],
        bump,
        has_one = authority,
        has_one=token_account,
        has_one = withdraw_destination,
    )]
    pub vault: Account<'info, Vault>,
```