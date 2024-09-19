---
title: 逆向分析pump.fun的BondingCurve算法
date: 2024-09-03 20:17:01
categories: 技术
math: true
tags:
    - web3
    - 技术
    - solana
    - nextjs
---

找到 div id, 或者 用报错文本 进行全局搜索
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/pump2.jpg)

全局搜索
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/pump3.png)

可以看到 `onChange`事件处理函数:

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/pump4.jpg)

```js
onChange:  es ? e=>{
    if (et)
        return;
    let t = parseFloat(e.target.value);
    if (isNaN(t)) {
        g(""),
        f("");
        return
    }
    g(t),
    f(I(new ex.BN(Math.floor(1e9 * t)), !0).toNumber() / 1e6)
}
: e=>{
    let t;
    if (et)
        return;
    let n = parseFloat(e.target.value);
    if (isNaN(n)) {
        f(""),
        g("");
        return
    }
    f(n);
    let s = new ex.BN(1e6 * n);
    t = u ? I(s, !1) : A(s),
    g((0,
    p.s)(t))
}
})
```

可知， 函数`I`正是算法函数的实现, 接下来，需要定位 `I`函数的位置，

我们在 `onChange`函数中打两个断点, 然后在输入框输入数量，触发执行到断点处

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/pump5.jpg)


此时，将鼠标放置在`I`上就可以查看函数的位置:
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/pump6.jpg)

或者，直接在调试窗口的下方控制台，直接输入 `I`， 然后双击输出， 也可以查看`I`的定义,
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/pump7.jpg)

至此，我们已经找到pump.fun的bonding curve的算法实现函数:



根据前面的分析,
- 参数 `n` 是个`bool`值， 表示的是按照sol还是按照token买入
- 参数 `e` 是数量

因此,
其中 i 是 bigint库


```js
 // 买入
 function x(e,n)=>{
    let s, a;
    if (e.eq(new i.BN(0)) || !t)
        return new i.BN(0);
    if (n) {
        // 按照 sol数量买入
        let n = t.virtualSolReserves.mul(t.virtualTokenReserves)
          , r = t.virtualSolReserves.add(e)
          , o = n.div(r).add(new i.BN(1));
        a = t.virtualTokenReserves.sub(o),
        a = i.BN.min(a, t.realTokenReserves),
        s = e
    } else
        // 按照 token数量买入
        s = (e = i.BN.min(e, t.realTokenReserves)).mul(t.virtualSolReserves).div(t.virtualTokenReserves.sub(e)).add(new i.BN(1)),
        a = e;
    let r = _(s); // 手续费
    return n ? a : s.add(r) //SOL加上手续费
}

// 卖出
sellQuote: e=>{
    if (e.eq(new i.BN(0)) || !t)
        return new i.BN(0);
    let n = e.mul(t.virtualSolReserves).div(t.virtualTokenReserves.add(e))
      , s = _(n); // 手续费
    return n.sub(s) // 扣除手续费
}
```


|变量|变量全称|类型|说明（统一使用最小单位)|初始值|
|---|----|----|-----|----|
|Tv|virtualTokenReserves| u64 | 虚拟token库存量 | 1073000000 * 10^6|
|Sv|virtualSolReserves|u64|虚拟SOL的库存量|30 * 10^9|
|Tr| realTokenReserves | u64 |真实的token库存量 |793100000 * 10^6|
|Sr| realSolReserves | u64 | 真实的SOL的库存量 | 0 * 10^9|



$$
y = x^2
$$