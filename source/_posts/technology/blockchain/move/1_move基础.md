---
date: 2024-10-9 17:47
title: 1_move基础
categories: 技术
tags:
- Move
- 智能合约
- Aptos
- Sui
---

- Move介绍: https://move-language.github.io/move/introduction.html

- 教程: https://github.com/move-language/move/tree/main/language/documentation/tutorial



## 总结

move的语法和rust差不多，核心概念简单，上手快。

- 语法： move语法基本上和Rust语法大同小异, 以下为几个不同之处
  - `module` 块
  - `script` 块
  - 函数声明 `fun`
  - 函数访问性:  `public`
  - 结构体特性(ability): `has`

- 核心概念: 常用的核心概念，整理如下


## 核心概念

- **Module(模块)**:
  - 库
  - 包含结构体 和 更新结构体的函数
  - **发布(publish)** 在地址上, 以供被调用, 例如： 0xCAFE就是模块发布的地址
    - 值需要发布(publish)才能存储在global storage, 即调用 `move_to`进行发布

  ```rust
    // sources/FirstModule.move
    module 0xCAFE::BasicCoin {
        ...
    }
  ```

- **Script(脚本)**:
  - 入口函数
  - 执行程序
  - 临时的
  - 不存储在 global storage中

- **Struct(结构体)**: 结构体
- **Resource(资源)**:
  - 结构体中的 *不可拷贝* 且 *不可销毁(drop)* 的值(values)
  - 必须在函数尾部(end)转移资源的权限
- **Address(地址)**: 地址
- **Global Storage(全局存储)**: 全局数据库
  - 类似下面的结构:
  ```rust
    struct GlobalStorage {
        // 资源(values)
        resources: Map<address, Map<ResourceType, ResourceValue>>

        // 模块(code)
        modules: Map<address, Map<ModuleName, ModuleBytecode>>
    }
  ```


## Move区块链的状态(state)模型

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/move_state.png)


与EVM链的状态模式对比

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/solidity_state.png)



## Struct的4大特性(ability)

- https://move-language.github.io/move/abilities.html

- `copy`: 可拷贝
- `drop`: 可丢弃
- `store`: 可存储(存在global storage)
- `key`: 可作为 global storage中的key


例如：

```rust
struct Coin has key {
    value: u64,
}
```

## Global Storage的5个操作

https://move-language.github.io/move/global-storage-operators.html


- `move_to<T>(&signer,T)`: 将`T`发布在 `signer.address`地址下
- `move_from<T>(address): T`:  将地址下的T移除
- `borrow_global_mut<T>(address): &mut T`:  获取地址下的可变引用
- `borrow_global<T>(address): &T`: 获取不可变引用
- `exists<T>(address): bool`: 判断地址下是否存在T


## Acquires 修饰

- https://move-language.github.io/move/functions.html?highlight=acquires#acquires

当一个函数通过`move_from`, `borrow_global`, 或 `borrow_global_mut`来使用资源(resource)时，函数需要加上 `acquires`修饰


例如：

```rust
/// Deposit `amount` number of tokens to the balance under `addr`.
fun deposit(addr: address, check: Coin) acquires Balance{
    let balance = balance_of(addr);
    let balance_ref = &mut borrow_global_mut<Balance>(addr).coin.value;
    let Coin { value } = check;
    *balance_ref = balance + value;
}
```


## 函数

public, public(friend), or public(script)

- 函数默认是私有的(private), 可以通过下面几种方式进行限定
  - public：
    - 同一模块的函数可调用
    - 其他模块中的函数可调用
    - 脚本中的函数可调用
  - public(friend) : 供 friend 模块调用（类似C++中的友元函数）
    - 同一模块
    - 其他友元模块中的函数
  - public entry
    - 相当于一个模块的main函数（入口）
  - ~~public(script) : 供交易脚本调用~~


## 单元测试

move中的单元测试 和 rust单元测试类似， 直接在模块中编写单元测试即可

`move test` : 运行单元测试



```rust
#[test(account = @0x1)]  // 将 account 参数设置为地址 0x1
#[expected_failure(abort_code = 2)] //  预期失败，错误码 2
fun publish_balance_already_exists(account: signer) {
    publish_balance(&account);
    publish_balance(&account);
}
```


例如：

```rust
module 0xCAFE::BasicCoin {
     // Only included in compilation for testing. Similar to #[cfg(testing)]
    // in Rust. Imports the `Signer` module from the MoveStdlib package.
    #[test_only]
    use std::signer;

    struct Coin has key {
        value: u64,
    }

    public fun mint(account: signer, value: u64) {
        move_to(&account, Coin { value })
    }

    // 单元测试
    // Declare a unit test. It takes a signer called `account` with an
    // address value of `0xC0FFEE`.
    #[test(account = @0xC0FFEE)]
    fun test_mint_10(account: signer) acquires Coin {
        let addr = signer::address_of(&account);
        mint(account, 10);
        // Make sure there is a `Coin` resource under `addr` with a value of `10`.
        // We can access this resource and its value since we are in the
        // same module that defined the `Coin` resource.
        assert!(borrow_global<Coin>(addr).value == 10, 0); // assert 可以指定错误码
    }
}
```


## phantom类型

- https://move-language.github.io/move/generics.html#phantom-type-parameters


- ChatGPT的回答： https://chatgpt.com/share/67078dde-ae08-8004-a109-f1125dfa1fad


**为什么需要phantom类型？**

- **编译时类型约束**：Phantom 类型允许你在泛型参数中提供类型信息，而不需要实际在运行时使用这些类型。这使得编译器能够在编译时检查类型安全性，而不引入运行时开销。
- **零运行时开销**：因为 phantom 类型在运行时并不占用任何存储空间，它避免了不必要的内存分配或额外的存储复杂性。
- **增强的泛型能力**：在某些场景下，你可能希望在泛型中传递一些类型信息，但这些信息仅在编译时有用。在 Move 中使用 phantom 类型可以让代码更加灵活。




**phantom常见应用场景:**

- **逻辑分离**：通过 phantom 类型标记不同的逻辑上下文，确保类型安全。
- **权限控制**：在编译时限制某些操作只能由特定权限的账户执行，确保系统安全。
- **标记类型**：用 phantom 来标记不同状态或角色，避免运行时状态混乱。
- **资源类型的泛化**：对资源类型进行泛化处理，使得代码在不同资源类型上可重用，减少代码重复。



示例： 逻辑分离

```rust
module PhantomLogicExample {
    /// 定义两种逻辑上下文的类型标记
    struct Deposit {}
    struct Withdraw {}

    /// 泛型结构体，用于表示不同逻辑的账户操作，但通过 phantom 类型来区分逻辑
    struct Account<T: store, phantom Operation> {
        balance: u64,
        operation_info: T,
    }

    /// 创建一个用于“存款”逻辑的账户结构
    public fun create_deposit_account<T: store>(balance: u64, info: T): Account<T, Deposit> {
        Account { balance, operation_info: info }
    }

    /// 创建一个用于“取款”逻辑的账户结构
    public fun create_withdraw_account<T: store>(balance: u64, info: T): Account<T, Withdraw> {
        Account { balance, operation_info: info }
    }

    /// 增加存款逻辑的账户余额
    public fun add_deposit<T: store>(account: &mut Account<T, Deposit>, amount: u64) {
        account.balance = account.balance + amount;
    }

    /// 减少取款逻辑的账户余额
    public fun subtract_withdraw<T: store>(account: &mut Account<T, Withdraw>, amount: u64) {
        account.balance = account.balance - amount;
    }

    /// 获取账户余额 (适用于任意逻辑)
    public fun get_balance<T: store, Operation>(account: &Account<T, Operation>): u64 {
        account.balance
    }
}

```


示例： 资源类型的泛化

```rust

module ResourceExample {
    struct Coin<phantom Currency> {
        amount: u64,
    }

    struct USDCoin {}
    struct Bitcoin {}

    public fun create_usd_coin(amount: u64): Coin<USDCoin> {
        Coin { amount }
    }

    public fun create_bitcoin(amount: u64): Coin<Bitcoin> {
        Coin { amount }
    }

    /// 转移代币
    public fun transfer<T>(coin: &mut Coin<T>, amount: u64) {
        coin.amount = coin.amount - amount;
    }

    /// 获取代币余额
    public fun get_balance<T>(coin: &Coin<T>): u64 {
        coin.amount
    }
}

```



示例： 类型标记

```rust
module StateExample {
    struct Pending {}
    struct Approved {}
    struct Rejected {}

    struct Transaction<phantom Status> {
        id: u64,
        amount: u64,
    }

    public fun create_pending_transaction(id: u64, amount: u64): Transaction<Pending> {
        Transaction { id, amount }
    }

    public fun approve_transaction(pending_txn: Transaction<Pending>): Transaction<Approved> {
        Transaction { id: pending_txn.id, amount: pending_txn.amount }
    }

    public fun reject_transaction(pending_txn: Transaction<Pending>): Transaction<Rejected> {
        Transaction { id: pending_txn.id, amount: pending_txn.amount }
    }

    public fun process_approved_transaction(approved_txn: Transaction<Approved>) {
        // 处理已批准的交易
    }
}

```



## 形式化验证

https://github.com/move-language/move/blob/main/language/move-prover/doc/user/spec-lang.md

`move prove`


```
# 在move的根目录下执行
./scripts/dev_setup.sh -yp
source ~/.profile

# 检查 boogie是否按照
boogie /version
```


形式化验证用于验证逻辑是否



常用的关键词：

- `let`:
- `aborts_if`: 条件中断
- `let post` : **函数执行后**获取值
- `ensures`: **函数执行成功后**必须满足的条件



关于move spec形式化验证 与 单元测试的区别：
- ChatGPT的回答：https://chatgpt.com/share/67079e85-c11c-8004-9d5d-52f8d4c16583
- Move Spec 和单元测试是互补的。Move Spec 可以提供形式化的**逻辑保障**，而单元测试则用来确保代码在实际运行环境中表现正确。
- 重点放在关键性质上：形式化验证特别适合那些涉及**安全性、资金管理、状态变化一致性**等至关重要的合约部分，而单元测试则适合验证合约中常见的逻辑操作和具体功能。


例如：

```rust
spec withdraw {
    let balance = global<Balance<CoinType>>(addr).coin.value;
    // 判断资源是否存在
    aborts_if !exists<Balance<CoinType>>(addr);
    // 校验balance
    aborts_if balance < amount;

    // 检查执行后的状态
    let post balance_post = global<Balance<CoinType>>(addr).coin.value;
    // 余额检查
    ensures balance_post == balance - amount;
    // 检查返回值
    ensures result == Coin<CoinType> { value: amount };
}
```



**特别注意**： 在 Move 的形式化验证中，**每一个**可能的 abort（异常中断）都需要在 spec 规范中通过 aborts_if 子句来描述。当你编写了涉及可能导致 abort 的操作时，Move Prover 需要你为这些操作提供明确的终止条件。


例如：

```rust
fun deposit<CoinType>(addr: address, check: Coin<CoinType>) acquires Balance{
    let balance = balance_of<CoinType>(addr);
    let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(addr).coin.value;
    let Coin { value } = check;
    *balance_ref = balance + value;
}

spec deposit {
    let balance = global<Balance<CoinType>>(addr).coin.value;
    let check_value = check.value;

    // 对应 borrow_global<Balance<CoinType>>(owner).coin.value
    aborts_if !exists<Balance<CoinType>>(addr);

    // 对应 *balance_ref = balance + value;
    aborts_if balance + check_value > MAX_U64;

    let post balance_post = global<Balance<CoinType>>(addr).coin.value;
    ensures balance_post == balance + check_value;
}
```

其中2个 `aborts_if` 缺一不可，必须都存在


可以通过 move  provier 的提示来增加

