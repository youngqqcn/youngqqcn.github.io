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

$$y=x^2$$

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


## Bonding Curve公式

特别说明:
- 前端计算使用BN:,
  -  https://github.com/indutny/bn.js/
  - 或者使用 anchor.BN
- 合约计算过程中使用 u128 , 最终计算结果保存在数据账户使用u64即可


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/0919_0.png)

### 用户买入Token

买入公式(按照SOL数量)
$$
\begin{equation}

\Delta{t} = T_v - \bigg ( \frac{S_v \times T_v}{S_v + \Delta{s}} + 1 \bigg)

\end{equation}
$$

买入公式(按照Token数量)


$$
\begin{equation}

\Delta{s} =  \frac{\Delta{t} \times S_v }{T_v - \Delta{t}} + 1

\end{equation}
$$

买入后状态更新：

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/0919_1.png)


### 用户卖出Token

$$
\begin{equation}

\Delta{s} =  \frac{\Delta{t} \times S_v }{T_v + \Delta{t}}

\end{equation}
$$

卖出后状态更新：
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/0919_2.png)


---

## 推导过程

基础公式

$$
\begin{equation}

T_v \times S_v = k

\end{equation}
$$

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/0919_3.png)


### 买入Token(按照token数量)

$$
\begin{equation}
\begin{align*}

&(T_v - \Delta t)(S_v + \Delta s) = k = T_v \times S_v  \\


&\Delta t = T_v - \frac{T_v \times S_v}{S_v + \Delta s} \\

\end{align*}
\end{equation}
$$


### 用户买入Token(按照SOL)

$$
\begin{equation}
\begin{align*}

&(T_v + \Delta t)(S_v - \Delta s) = k = T_v \times S_v \\

&\Delta s = S_v - \frac{T_v \times S_v}{T_v + \Delta t} \\

&\Delta s =  \frac{S_v \times (T_v +\Delta t) - T_v \times S_v}{T_v + \Delta t} \\

&\Delta s =  \frac{S_v \times T_v + S_v \times \Delta t - T_v \times S}{T_v + \Delta t} \\

&\Delta s =  \frac{S_v \times \Delta t }{T_v + \Delta t} \\

\end{align*}
\end{equation}
$$


### 价格

$$p = \frac{S_v}{T_v}$$