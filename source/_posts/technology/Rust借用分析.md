---
title: Rust借用分析
date: 2022-11-13 11:16:37
categories: 技术
tags:
- Rust
---

可以把Rust中的借用，理解为C语言中的指针， `mut`, `&`,  可变借用、不可变借用这些比较绕的概念，可以理解为C语言中的`const`修饰符(尽管，C语言中的`const`只是做一个“约定”, 这里只是为了方便理解， 不必纠结)。

例如 `let b = 1;  let a = &b;` , `a`是指向`不可变变量b`的`不可变借用`。

我们用C语言的可以表示为： `const int b = 1;  const int const *a = &b;`

---

第1种

```rust

let b = 1;
let a = b;

println!("a = {} ", a);
println!("b = {}", b);
// println!("*a = {}", *a); // error:  type `{integer}` cannot be dereferenced

let c = 2;
// a = c; // error: cannot assign twice to immutable variable

```

- `let a = b;` 是将`b`的值拷贝给`a`。 注意，不是移动！
- `a` 和 `b`一样， 也是`不可变的整型变量`， `a`不是`b`引用，也不是`b`的move


---




第2种

```rust
let b = 2;
let a = &b;
println!("a = {}, b = {}", a, b);
println!("a = {}, b = {}", *a, b);

// *a = 99; // `a` is a `&` reference, so the data it refers to cannot be written
```

- `b`是`不可变整型变量`
- `a`是`b`的`不可变引用`, 因此`*a`(即`a`所引用的内容)不能被修改

---


第3种

```rust
let b = 2;
let mut a = &b;
println!("a = {}, b = {}", a, b); //  ok， 自动解引用
println!("*a = {}, b = {}", *a, b); // ok，手动解引用

let c = 3;
a = &c;  // 修改 a 的指向
println!("a = {}", a);

```

可以将`引用`理解为C语言中的`指针`, 很像 `const`修饰的原理

- `let mut a = &b; ` 其中 `a`是指向`不可变变量b`的`可变引用`， 即`b`的内容不能被改变， 但是，`a`本身的“指向”可以变
- `a = &c;` 即改变了 `a`的指向， `a`指向了`c`


---

第4种

```rust
let b = 1;
let a = &mut b; // error:  cannot borrow `b` as mutable, as it is not declared as mutable
```

不能对`不可变变量`进行`可变`借用

```rust

let mut b = 1;
let a = &mut b;
println!("xxx===> a = {}", a);
// println!("xxx===> a = {}, b = {}", a, b); // error, 不能同时可变引用和不可引用
// println!("b = {}", b); //error, 不能同时可变引用和不可引用
*a = 99;
// println!("xxx===> a = {}, b = {}", a, b); // error，  不能同时可变引用和不可引用
println!("xxx===> a = {}", a);
println!("b = {}", b); // 可变引用用完了， 原来的不可变引用可以继续使用了

let mut c = 1;
// a = &mut c;  // error, cannot assign twice to immutable variable `a`
```

- `a`是指向`可变变量b`的`不可变引用`， 即`a`的指向不能变， 所指向的内容（值）`*a`是可以变的

---

第5种


```rust
let b = 1;
let mut a = b; // 将b的值进行了拷贝
println!("===> a = {}, b = {}", a, b);
a = 2;
println!("===> a = {}, b = {}", a, b);
```

- `let mut a = b;` 是将`b`的值拷贝到`a`， 不是move！ 因此，互不影响
- `a`是`可变整型变量`



----



第6种


```rust
let b = 1;
let &(mut a) = &b;
println!("+++ a = {}, b = {}", a, b);
a  = 999;
println!("+++ a = {}, b = {}", a, b);
// println!("+++ a = {}, b = {}", *a, b); // type `{integer}` cannot be dereferenced
```

- `let &(mut a) = &b;` 可以“约”多余符号，等效于 `let mut a = b;`, 因此效果同上例(第5种), 不赘述


---


第7种

```rust

let mut c = 1;
let mut a = &mut c;
*a = 99;
println!("a = {}", *a);

let mut d = 33;
a = &mut d; // ok
println!("a = {}", *a);
```

- 如果理解上面提到集中情况， 很容易理解此种变化
- `a` 是指向 `可变整型变量c`的`可变整型变量的可变引用`
- 两个“可变”即代表， `a`所指向内容(`*a`)是可以修改的； 同时，`a`本身的“指向”也是可以修改的


---


第8种

```rust
let b = 1;
// let ref mut a  = b;  // 错，同 let a = &mut b;
let mut c = 1;
let ref mut a = c; // 等效于   let a = &mut c;
*a = 99;
// println!("a = {}, c = {}", *a, c); // error,  c已经被可变借用了，不能和可变借用同时存在
println!("a = {}", *a);
println!("c = {}", c); // 可变借用用完之后，  c不可变引用又可以使用了

let mut d = 777;
// a = &mut d; // error, cannot assign twice to immutable variable `a`
// println!("a = {}", a);

```

- `let ref mut a = c;`  等效于 `let a = &mut c;`


    