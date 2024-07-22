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

> 参考: https://github.com/coral-xyz/sealevel-attacks/tree/master


----

> https://www.soldev.app/course/signer-auth


### 案例 1: 缺少 Signer Authentication

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

-   方案 1：使用 `ctx.accounts.authority.is_signer` 判断 authority 是否是交易的 signer
    -   缺点： 账户验证和指令逻辑验证是一起的（没有分离）
-   方案 2：使用 Anchor 的 `Singer`
    -   优点： 账户验证和指令逻辑验证是分开, 在进入逻辑之前就已经做了校验
    -   缺点: 只能和 Singer 账户一起,不能和其他账户类型
-   方案 3: 使用 `#[account(singer)]`
    -   作用和 `Signer`是一样，但是比 `Signer` 更灵活，支持更多账户类型
    -   比如，
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

### 案例 2： Missing owner check

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

-   `admin_instruction`: 检查的是有输入参数指定的程序状态(state)与参数是否匹配, 并没有检查数据账户的 owner 是不是本程序帐户

    如下图, 攻击这将 B 数据账户传入给 A 程序，可以通过 A 程序的简单校验，从而修改 A 数据账户的状态

    ```
    [A程序账户]        [B程序账户]
       |                 |
       |                 |
    [A数据账户]        [B数据账户]
    ```

-   [攻击案例-国库提币攻击](https://github.com/youngqqcn/solana-course-source/blob/master/1_onchain_program_development/solana-owner-checks-starter/programs/solana-owner-checks-starter/src/lib.rs)

    -   攻击者的合约，

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

    -   漏洞修复： 将 vault 的 `UncheckedAccount` 改成 `Account`, anchor 为 Account 实现了 owner 安全检查

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

### 案例 3： Account Data Matching

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

-   漏洞分析:

    -   `update_config`缺少校验: `ctx.accounts.admin_conifg.admin == ctx.accounts.admin`

-   漏洞修复:
    -   方案 1： 在`update_admin`增加校验 `ctx.accounts.admin_conifg.admin == ctx.accounts.admin`
    -   方案 2： 使用`has_one`约束, 为`admin_config`增加约束 `#[account(has_one = admin)]`, 这样和方案 1 等效
    -   方案 3： 使用`constraint`约束, 为`admin_config`增加约束 `#[account(constraint = admin_config.admin == admin.key())]`, 这样和方案 1 等效

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

修复方案: 为 vault 增加约束

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

### 案例 4： Re-initialization Attacks (重新初始化攻击)

```rust
use anchor_lang::prelude::*;
use borsh::{BorshDeserialize, BorshSerialize};

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod initialization_insecure  {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let mut user = User::try_from_slice(&ctx.accounts.user.data.borrow()).unwrap();
        user.authority = ctx.accounts.authority.key();
        user.serialize(&mut *ctx.accounts.user.data.borrow_mut())?;
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(mut)]
    user: AccountInfo<'info>,
    #[account(mut)]
    authority: Signer<'info>,
}

#[derive(BorshSerialize, BorshDeserialize)]
pub struct User {
    authority: Pubkey,
}
```

漏洞分析：

-   `Initialize`的 user 采用的 手动初始化， 没有 `is_initialize`标识， 可以重复初始化

修复方案:

-   方案 1： 在`User`中增加`is_initialize`字段，并且在指令处理函数中增加 `is_initialize`的判断, 防止重复初始化

-   方案 2(推荐)： 使用 Anchor 的`init`约束, `init`约束通过 CPI 调用 System Program 创建一个账户，并且设置账户`discrimiantor`,

    -   `init` 约束可以确保每个账户**只能**被初始化一次
    -   `init`约束必须和 `payer` 和 `space` 一起使用
        -   `space`: 指定账户的空间大小，这决定了支付的租金大小
            -   头`8字节`，存放账户的`discrimiantor`, 即账户结构体名称的哈希
        -   `payer`: 支付初始化账户的费用

-   方案 3： 使用 Anchor 的 `init_if_needed`约束, **要谨慎**:
    -   如果指定的账户不存在，它会创建并初始化该账户
    -   如果账户已经存在，它会跳过初始化步骤，直接使用现有账户。
    -   `init_if_needed`与普通 `init` 的区别：
        -   `init` 总是尝试创建新账户，如果账户已存在会失败。
        -   `init_if_needed` 在账户存在时不会失败，而是跳过初始化。

### 案例 5： 相同的可修改账户

> https://www.soldev.app/course/duplicate-mutable-accounts

一个"石头剪刀布"游戏程序

```rust
use anchor_lang::prelude::*;
use borsh::{BorshDeserialize, BorshSerialize};

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod duplicate_mutable_accounts {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        ctx.accounts.new_player.player = ctx.accounts.payer.key();
        ctx.accounts.new_player.choice = None;
        Ok(())
    }

    pub fn rock_paper_scissors_shoot_insecure(
        ctx: Context<RockPaperScissorsInsecure>,
        player_one_choice: RockPaperScissors,
        player_two_choice: RockPaperScissors,
    ) -> Result<()> {
        ctx.accounts.player_one.choice = Some(player_one_choice);

        ctx.accounts.player_two.choice = Some(player_two_choice);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = payer,
        space = 8 + 32 + 8
    )]
    pub new_player: Account<'info, PlayerState>,
    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct RockPaperScissorsInsecure<'info> {
    #[account(mut)]
    pub player_one: Account<'info, PlayerState>,
    #[account(mut)]
    pub player_two: Account<'info, PlayerState>,
}

#[account]
pub struct PlayerState {
    player: Pubkey,
    choice: Option<RockPaperScissors>,
}

#[derive(Clone, Copy, BorshDeserialize, BorshSerialize)]
pub enum RockPaperScissors {
    Rock,
    Paper,
    Scissors,
}
```

漏洞分析: `RockPaperScissorsInsecure` 中 `player_one` 和 `player_two` 可以相同, 攻击可以传入 2 个相同的地址

漏洞修复:

-   方案 1： 直接在指令处理函数中增加判断 `ctx.accounts.player_one() != ctx.account.player_two.key()`

-   方案 2（推荐）： 使用 Anchor 的 `constraint`,

    ```rust
    #[derive(Accounts)]
    pub struct RockPaperScissorsSecure<'info> {
        #[account(
            mut,
            constraint = player_one.key() != player_two.key() // 检查
        )]
        pub player_one: Account<'info, PlayerState>,
        #[account(mut)]
        pub player_two: Account<'info, PlayerState>,
    }
    ```

### 案例 6： type-cosplay

> https://www.soldev.app/course/type-cosplay

```rust
use anchor_lang::prelude::*;
use borsh::{BorshDeserialize, BorshSerialize};

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod type_cosplay_insecure {
    use super::*;

    pub fn admin_instruction(ctx: Context<AdminInstruction>) -> Result<()> {
        let account_data =
            AdminConfig::try_from_slice(&ctx.accounts.admin_config.data.borrow()).unwrap();
        if ctx.accounts.admin_config.owner != ctx.program_id {
            return Err(ProgramError::IllegalOwner.into());
        }
        if account_data.admin != ctx.accounts.admin.key() {
            return Err(ProgramError::InvalidAccountData.into());
        }
        msg!("Admin {}", account_data.admin);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct AdminInstruction<'info> {
    admin_config: UncheckedAccount<'info>,
    admin: Signer<'info>,
}

#[derive(BorshSerialize, BorshDeserialize)]
pub struct AdminConfig {
    admin: Pubkey,
}

#[derive(BorshSerialize, BorshDeserialize)]
pub struct UserConfig {
    user: Pubkey,
}
```

漏洞分析:

-   `AdminConfig` 和 `UserConfig` 有相同的数据结构， 因此 2 个类型可以随意传参,

漏洞修复:

-   方案 1: 使用 Anchor 的 `Account`类型， 为类型增加类型标识(`Discriminator`)

    ```rust

    #[derive(Accounts)]
    pub struct AdminInstruction<'info> {
        #[account(has_one = admin)]
        admin_config: Account<'info, AdminConfig>,
        admin: Signer<'info>,
    }
    ```

### 案例 7： Arbitrary CPI

```rust
use anchor_lang::prelude::*;
use anchor_lang::solana_program;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod arbitrary_cpi_insecure {
    use super::*;

    pub fn cpi(ctx: Context<Cpi>, amount: u64) -> ProgramResult {

        //
        solana_program::program::invoke(
            &spl_token::instruction::transfer(
                ctx.accounts.token_program.key,
                ctx.accounts.source.key,
                ctx.accounts.destination.key,
                ctx.accounts.authority.key,
                &[],
                amount,
            )?,
            &[
                ctx.accounts.source.clone(),
                ctx.accounts.destination.clone(),
                ctx.accounts.authority.clone(),
            ],
        )
    }
}

#[derive(Accounts)]
pub struct Cpi<'info> {
    source: UncheckedAccount<'info>,
    destination: UncheckedAccount<'info>,
    authority: UncheckedAccount<'info>,
    token_program: UncheckedAccount<'info>, // 没有做任何检测
}
```

漏洞分析：

-   没有检查`token_program` , 因此，可以传入任意值
-   直接使用原生的`invoke`和指令组装进行 CPI 调用，缺少安全检查

漏洞修复：

-   方案 1： 在`cpi`中增加检查

    ```rust
    if &spl_token::ID != ctx.accounts.token_program.key {
          return Err(ProgramError::IncorrectProgramId);
      }
    ```

-   方案 2： 使用 Anchor 的 CPI 模块进行 CPI 调用, Anchor 在 CPI 内部做了一系列安全检查

```rust
use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount};

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod arbitrary_cpi_recommended {
    use super::*;

    pub fn cpi(ctx: Context<Cpi>, amount: u64) -> ProgramResult {
        token::transfer(ctx.accounts.transfer_ctx(), amount)
    }
}

#[derive(Accounts)]
pub struct Cpi<'info> {
    source: Account<'info, TokenAccount>,
    destination: Account<'info, TokenAccount>,
    authority: Signer<'info>,
    token_program: Program<'info, Token>,
}

impl<'info> Cpi<'info> {
    pub fn transfer_ctx(&self) -> CpiContext<'_, '_, '_, 'info, token::Transfer<'info>> {
        let program = self.token_program.to_account_info();
        let accounts = token::Transfer {
            from: self.source.to_account_info(),
            to: self.destination.to_account_info(),
            authority: self.authority.to_account_info(),
        };
        CpiContext::new(program, accounts)
    }
}
```

案例, 对战游戏: https://github.com/Unboxed-Software/solana-arbitrary-cpi/tree/starter/programs

账户结构:

```

Gameplay Program                 Metadata Program              Metadata Fake Program

 [character A]                  [metadata account A]           [metadata account X]
 [character B]                  [metadata account B]
```

漏洞分析: 因为`gameplay`中 `BattleInsecure` 的 metadata_program 和 player 可以任意传入，并且指令处理函数中也没有进行判断，
那么，攻击者就可以伪造 一个 Metadata Fake 程序，在 Fake 程序中为角色设置很高`health`, 这样，攻击者可以一直获胜

```rust
#[derive(Accounts)]
pub struct BattleInsecure<'info> {
    pub player_one: Account<'info, Character>,
    pub player_two: Account<'info, Character>,


    /// CHECK: manual checks  漏洞
    pub player_one_metadata: UncheckedAccount<'info>,
    /// CHECK: manual checks   漏洞
    pub player_two_metadata: UncheckedAccount<'info>,
    /// CHECK: intentionally unchecked      漏洞
    pub metadata_program: UncheckedAccount<'info>,
}

```

漏洞修复: 使用 Anchor 自带的 `Program`类型， 其中做了检查`account_info.key == expected_program && account_info.executable == true`

```rust
pub metadata_program: Program<'info, CharacterMetadata>,
```

### 案例 8： Bump Seed Canonicalization

-   对于每个 seed, 有效的 bump 值在 `[0, 255]`闭区间， 共`256`个
-   有效的 bump 值，是确保 PDA 在 ED25519 曲线之外
-   对于单个 bump 值，有约`80%`概率是有效的, 因此，生成有效 bump 值是很容易的
-   Canonical bump 指的是最大有效`bump`值, 从`255`开始递减

```rust
use anchor_lang::prelude::*;

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod bump_seed_canonicalization_insecure {
    use super::*;

    pub fn set_value(ctx: Context<BumpSeed>, key: u64, new_value: u64, bump: u8) -> Result<()> {
        let address = Pubkey::create_program_address(
            &[key.to_le_bytes().as_ref(),
            &[bump]],
            ctx.program_id
        ).unwrap();

        if address != ctx.accounts.data.key() {
            return Err(ProgramError::InvalidArgument.into());
        }

        ctx.accounts.data.value = new_value;

        Ok(())
    }
}

#[derive(Accounts)]
pub struct BumpSeed<'info> {
    data: Account<'info, Data>,
}

#[account]
pub struct Data {
    value: u64,
}
```

- 漏洞分析:

    -   key 和 bump 都是由外部输入，那么，就存在碰撞风险
    -   PDA 没有建立与账户 `1对1`绑定的关系， 用户可以传入任意的有效 key 和 bump 来生成**多个**PDA 账户

- 漏洞修复：

    - 方案 1: 推荐使用 `find_program_address` 生成有效的 canonical bump
    - 方案 2: 使用 Anchor 的 `seeds` 和`bump` 约束,
        - 注意: 如果不指定 bump,由 solana 自动计算，则需要消耗更多计算单元(CU)

    ```rust
      // initialize account at PDA
      #[derive(Accounts)]
      #[instruction(key: u64)]
      pub struct BumpSeed<'info> {
      #[account(mut)]
      payer: Signer<'info>,
      #[account(
          init,
          seeds = [key.to_le_bytes().as_ref()],
          // 会自动生成 canonical bump, 来生成 PDA， 需要消耗更多计算单元
          // derives the PDA using the canonical bump
          bump,
          payer = payer,
          space = 8 + 8
      )]
      data: Account<'info, Data>,
      system_program: Program<'info, System>
      }

      #[account]
      pub struct Data {
          value: u64,
      }

    ```

-   [空投案例](https://github.com/youngqqcn/solana-course-source/blob/master/1_onchain_program_development/bump-seed-canonicalization/programs/bump-seed-canonicalization/src/lib.rs)
    - [修复官方 demo 的漏洞 PR](https://github.com/Unboxed-Software/solana-bump-seed-canonicalization/pull/1)
    - `user`缺少`mut`, 导致 `claim_secure` 可以重复调用



### 案例9： Closing Account重入攻击


原理: 因为Solana的垃圾回收是**整个交易**结束之后才进行，而一笔交易包含多个指令, 在交易插入一笔发送“租金”的指令，这样，账户就不会回收

示例:

[彩票案例](https://github.com/youngqqcn/solana-course-source/blob/master/1_onchain_program_development/solana-closing-accounts/programs/solana-closing-accounts/src/lib.rs)


关于Anchor的`close`属性约束的细节：

1. 执行时机：
   是的，close约束是在指令执行之后关闭账户。更具体地说，它是在指令的主要逻辑执行完成后，但在指令完全结束之前执行的。

2. 执行顺序：
   在一个Anchor指令中，执行顺序通常是：
   - 首先执行所有的前置约束（比如检查账户所有者、初始化检查等）
   - 然后执行指令的主要逻辑
   - 最后执行close等后置约束

3. 功能：
   close约束会做以下3件事：
   - 将账户的lamports（Solana的原生代币）转移到指定的接收者账户
   - 将账户数据的前8个字节设置为CLOSED_ACCOUNT_DISCRIMINATOR
   - 将账户的大小设置为0


注意：
- `close`约束是在**单个指令**结束之前执行3个关闭操作(退钱，清零，改owner)
- solana垃圾回收的时机是 **整个交易** 执行结束

