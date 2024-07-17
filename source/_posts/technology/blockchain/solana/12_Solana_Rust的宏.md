---
date: 2024-07-17 16:31
title: 12_Solana-Rust的宏
categories: 技术
tags:
- 区块链
- Solana
- 交易
- Token
- Anchor
---

> 参考: https://www.soldev.app/course/rust-macros
> Rust官方: https://rustwiki.org/zh-CN/book/ch19-06-macros.html


Rust的宏分为2类:

- 声明宏(Declarative macro): 使用`macro_rules!`定义，例如: `vec!`
- 过程宏(Procedural macro): 使用AST(Abstract syntax tree) 支持更加复杂的代码生成
  - Function-like macros - `custom!(...)`
  - Derive macros - `#[derive(CustomDerive)]`, 一般用于 `struct, enum, union` , 用于实现某些trait
  ```rust
    #[derive(MyMacro)]
    struct Input {
        field: String
    }

    // 指定helper属性
    #[proc_macro_derive(MyMacro, attributes(helper))]
    pub fn my_macro(body: TokenStream) -> TokenStream {
        ...
    }

    #[derive(MyMacro)]
    struct Input {
        #[helper]  // 可以根据这个 helper attribitue 执行更多操作
        field: String
    }


  ```

  - Attribute macros - `#[CustomAttribute]`: 用于`struct`或函数
    ```rust
        #[my_macro]
        fn my_function() {
            ...
        }

        #[proc_macro_attribute]
        pub fn my_macro(attr: TokenStream, input: TokenStream) -> TokenStream {
            // 第1个参数 attr 代表属性宏的参数
            // 第2个参数 input，是剩余的元素
            ...,
        }

        #[my_macro(arg1, arg2)]
        fn my_function() {
            ...
        }
    ```

- 可以使用 `cargo-expand` 命令展开宏














