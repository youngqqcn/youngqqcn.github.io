---
date: 2024-10-23 15:19
title: 3_Sui项目结构
categories: 技术
tags:
- Move
- 智能合约
- Sui
---

> - move项目结构 https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-one/lessons/2_sui_project_structure.md
> - 自定义结构体和特性: https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-one/lessons/3_custom_types_and_abilities.md
> - 函数: https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-one/lessons/4_functions.md
> -  https://github.com/sui-foundation/sui-move-intro-course/blob/main/unit-one/lessons/5_contract_deployment.md


## 基础理论知识

- Sui标准库发布在`0x2`下面
- 发布的模块是不可变对象(immutable object),
  - 不可变对象:
    - 不能被修改+不能被转移+不能被删除
    - 任何人都可以使用

- 结构体的特性(abilities)
  - **copy**: value can be copied (or cloned by value)
  - **drop**: value can be dropped by the end of the scope
  - **key**: value can be used as a key for global storage operations
  - **store**: value can be held inside a struct in global storage

- 函数可见性：
  - **private**: the default visibility of a function; it can only be accessed by functions inside the same module
  - **public**: the function is accessible by functions inside the same module and by functions defined in another module
  - **public(package)**: the function is accessible by functions of modules inside the same package


## HelloWorld

- 创建move项目: `sui move new hello_world`

- 将 `Move.toml`中的 `rev = "framework/testnet"` 改为 `rev = "framework/devnet"`

- 在 `source/hello_world.move` 输入完整代码

    ```rust
    module hello_world::hello_world {

        use std::string;

        // 自定义结构体
        /// An object that contains an arbitrary string
        public struct HelloWorldObject has key, store {
            id: UID,
            /// A string contained in the object
            text: string::String
        }

        #[lint_allow(self_transfer)]
        public fun mint(ctx: &mut TxContext) {
            let object = HelloWorldObject {
                id: object::new(ctx),
                text: string::utf8(b"hello fucker!")
            };

            // 将 对象转给调用者
            transfer::public_transfer(object, tx_context::sender(ctx));
        }

    }
    ```

- 编译move代码:  `sui move build`

- 发布package: `sui client publish --gas-budget 20000000  ./`
  - 可以看到输出之后的package ID
  ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20241023-161318.jpg)


- `export PACKAGE_ID=xxx`

- 调用package : `sui client call --function mint --module hello_world --package $PACKAGE_ID --gas-budget 10000000`

    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/call_helloworld.png)


- 区块浏览器查看交易： https://suiscan.xyz/devnet/tx/9aXrUYDWmHNZ5JoYwUjNBpqgyZUpXvh7xndV3nwrndFa


- 查看新建的 `HelloWorldObject`: https://suiscan.xyz/devnet/object/0x2001aa30f0aa00c6b6ef86201b5f83271c5a8f7fe6c87720ee939ebda5a4f9ce

  - 此 Object的owner是我的地址
  - Object中的字段值 `hello fucker`


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20241023-162315.jpg)