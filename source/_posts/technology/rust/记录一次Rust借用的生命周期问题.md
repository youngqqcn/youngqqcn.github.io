---
date: 2024-07-26 16:46
title: 记录一次Rust借用的生命周期问题
categories: 技术
tags:
- Rust
- 生命周期
- 区块链
- Solana
- Anchor
---



Unstake的结构体声明如下:

```rust

#[derive(Accounts)]
pub struct UnStake<'info> {
    #[account(
        mint::token_program = token_program,
    )]
    pub stake_token_mint: InterfaceAccount<'info, Mint>,
}

```

我想编写一个helper函数, 用来为 Unstake创建 CpiContext, 像这样：

```rust
impl<'info> UnStake<'info> {
    pub fn transfer_ctx(&self) -> CpiContext<'_, '_, '_, 'info, TransferChecked<'info>> {
        let seeds: &[&[&[u8]]] =&[ &[
            b"POOL_AUTH".as_ref(),
            self.stake_token_mint.key().as_ref(),
        ]];
        CpiContext::new_with_signer(
            self.token_program.to_account_info(),
            TransferChecked {
                from: self.receive_stake_token_ata.to_account_info(),
                mint: self.stake_token_mint.to_account_info(),
                to: self.user_stake_token_ata.to_account_info(),
                authority: self.pool_authority.to_account_info(),
            },
            seeds,
        )
    }
}
```


编译报错：

```
error[E0515]: cannot return value referencing temporary value
   --> programs/anchor-token-staking-yqq/src/instructions/unstake.rs:218:9
    |
216 |               self.stake_token_mint.key().as_ref(),
    |               --------------------------- temporary value created here
217 |           ]];
218 | /         CpiContext::new_with_signer(
219 | |             self.token_program.to_account_info(),
220 | |             TransferChecked {
221 | |                 from: self.receive_stake_token_ata.to_account_info(),
...   |
226 | |             seeds,
227 | |         )
    | |_________^ returns a value referencing data owned by the current function

error[E0515]: cannot return value referencing temporary value
   --> programs/anchor-token-staking-yqq/src/instructions/unstake.rs:218:9
    |
214 |           let seeds: &[&[&[u8]]] =&[ &[
    |  _____________________________________-
215 | |             b"POOL_AUTH".as_ref(),
216 | |             self.stake_token_mint.key().as_ref(),
217 | |         ]];
    | |_________- temporary value created here
218 | /         CpiContext::new_with_signer(
219 | |             self.token_program.to_account_info(),
220 | |             TransferChecked {
221 | |                 from: self.receive_stake_token_ata.to_account_info(),
...   |
226 | |             seeds,
227 | |         )
    | |_________^ returns a value referencing data owned by the current function

error[E0515]: cannot return value referencing temporary value
   --> programs/anchor-token-staking-yqq/src/instructions/unstake.rs:218:9
    |
214 |           let seeds: &[&[&[u8]]] =&[ &[
    |  __________________________________-
215 | |             b"POOL_AUTH".as_ref(),
216 | |             self.stake_token_mint.key().as_ref(),
217 | |         ]];
    | |__________- temporary value created here
218 | /         CpiContext::new_with_signer(
219 | |             self.token_program.to_account_info(),
220 | |             TransferChecked {
221 | |                 from: self.receive_stake_token_ata.to_account_info(),
...   |
226 | |             seeds,
227 | |         )
    | |_________^ returns a value referencing data owned by the current function

For more information about this error, try `rustc --explain E0515`.
warning: `anchor-token-staking-yqq` (lib) generated 1 warning
error: could not compile `anchor-token-staking-yqq` (lib) due to 3 previous errors; 1 warning emitted
```


**原因： 返回局部变量的引用.**  即返回临时变量`seeds`的引用， 而seeds在函数结束之后就被释放了。
  - 深层次的原因：seeds中包含了对 `self.stake_token_mint.key().as_ref()` 引用，而 `self.stake_token_mint`


下面这段代码是可以的， 因为 `"POOL_AUTH"`具有静态生命周期，在整个运行期间都有效，因此，seeds的生命周期静态生命周期。


```rust
impl<'info> UnStake<'info> {
    pub fn transfer_ctx(&self) -> CpiContext<'_, '_, '_, 'info, TransferChecked<'info>> {
        let seeds: &[&[&[u8]]] = &[&[b"POOL_AUTH"]];
        CpiContext::new_with_signer(
            self.token_program.to_account_info(),
            TransferChecked {
                from: self.receive_stake_token_ata.to_account_info(),
                mint: self.stake_token_mint.to_account_info(),
                to: self.user_stake_token_ata.to_account_info(),
                authority: self.pool_authority.to_account_info(),
            },
            seeds,
        )
    }
}

```


为什么？ 看下面简化的例子

```rust
struct Example<'a> {
    data: &'a str,
}

impl<'info> Example<'info> {
    fn problematic(&self) -> &'info str {
        let local = self.data;  // local 的生命周期被限制在函数内
        local  // 错误：尝试返回一个生命周期比函数更短的引用
    }

    fn works(&self) -> &'info str {
        self.data  // 直接返回，没问题
    }
}
```


局部变量的生命周期：
- 在Rust中，局部变量的生命周期默认仅限于它们被定义的作用域内。即使这个局部变量包含了对生命周期更长的数据的引用，变量本身的生命周期仍然被限制在函数内。
- 引用的生命周期 vs 变量的生命周期： 虽然 `self.stake_token_mint` 的生命周期是 `'info`，但当我们创建一个包含这个引用的新局部变量时，这个新变量的生命周期被限制在函数内。
- 生命周期的传播： 生命周期并不会自动从被引用的数据传播到包含引用的新数据结构。
- 编译器的保守处理： 编译器会保守地处理生命周期，除非明确指定，否则它不会假设局部变量的生命周期比函数更长。



那么，不使用局部变量 `seeds` , 而是直接传参, 同样报错：

```rust
impl<'info> UnStake<'info> {
    pub fn transfer_ctx(&self) -> CpiContext<'_, '_, '_, 'info, TransferChecked<'info>> {
        // let seeds: &[&[&[u8]]] =;
        CpiContext::new_with_signer(
            self.token_program.to_account_info(),
            TransferChecked {
                from: self.receive_stake_token_ata.to_account_info(),
                mint: self.stake_token_mint.to_account_info(),
                to: self.user_stake_token_ata.to_account_info(),
                authority: self.pool_authority.to_account_info(),
            },
            &[&[b"POOL_AUTH", self.stake_token_mint.key().as_ref()]],
        )
    }
}

```

`self.stake_token_mint.key()` 会创建应该临时变量, 这个临时变量的生命周期也是仅限函数内部，因此参数中包含对于一个 临时变量的引用，导致生命周期不匹配的问题



最终的解决方案：

- seeds作为参数从外部传入
- 使用生命周期注解`'a`, 注解`self` 和 `seeds` ，确保`seeds`在函数执行期间有效


```rust
impl<'info> UnStake<'info> {
    pub fn transfer_ctx<'a>(
        &'a self,
        seeds: &'a [&[&[u8]]],
    ) -> CpiContext<'_, '_, '_, 'info, TransferChecked<'info>> {
        CpiContext::new_with_signer(
            self.token_program.to_account_info(),
            TransferChecked {
                from: self.receive_stake_token_ata.to_account_info(),
                mint: self.stake_token_mint.to_account_info(),
                to: self.user_stake_token_ata.to_account_info(),
                authority: self.pool_authority.to_account_info(),
            },
            seeds,
        )
    }
}

```
