---
date: 2024-12-10 16:24
title: Raydium做市资金量计算
categories: 技术
tags:
- DeFi
---


```python
from math import sqrt


def calc_market(market_cap_in_usd: float, sol_price_in_usd: float):

    # k = x * y      量纲 t*s  , s 为 sol ,  t 为 token
    k = 79 * (10_0000_0000 - 7_9310_0000)

    P = 0  # 量纲   s/t
    if True:
        # 量纲 u/s  , u为usd
        target_sol_price = sol_price_in_usd

        # 量纲 u/t  , u为usd
        target_token_price = market_cap_in_usd / 10_0000_0000

        # p = (u/t) / (u/s) , 目标量纲为 s/t
        P = target_token_price / target_sol_price
        # print(p)

    # y^2 = k / p       ,  量纲为 ts / (s/t) = t^2 , 因此 y的量纲为 t
    Y = sqrt(k / P)

    # x = p * y         , 量纲为 (s/t) * t = s , 因此 x 的量纲为 s
    X = P * Y

    return X, Y


target_market_cap_in_usd_lists = [1_0000_0000 * i for i in range(1, 11)]
sol_price_in_usd = 230

for target_market_cap in target_market_cap_in_usd_lists:
    ret = calc_market(target_market_cap, sol_price_in_usd)
    print(
        f"拉盘到{target_market_cap:0.0f}美金市值,  所需资金数量: {ret[0]:0.0f} 枚SOL , 约合 {ret[0] * sol_price_in_usd : 0.0f} USDT"
    )

```


计算结果：

```
拉盘到100000000美金市值,  所需资金数量: 2666 枚SOL , 约合  613137 USDT
拉盘到200000000美金市值,  所需资金数量: 3770 枚SOL , 约合  867107 USDT
拉盘到300000000美金市值,  所需资金数量: 4617 枚SOL , 约合  1061985 USDT
拉盘到400000000美金市值,  所需资金数量: 5332 枚SOL , 约合  1226275 USDT
拉盘到500000000美金市值,  所需资金数量: 5961 枚SOL , 约合  1371017 USDT
拉盘到600000000美金市值,  所需资金数量: 6530 枚SOL , 约合  1501873 USDT
拉盘到700000000美金市值,  所需资金数量: 7053 枚SOL , 约合  1622209 USDT
拉盘到800000000美金市值,  所需资金数量: 7540 枚SOL , 约合  1734214 USDT
拉盘到900000000美金市值,  所需资金数量: 7997 枚SOL , 约合  1839412 USDT
拉盘到1000000000美金市值,  所需资金数量: 8430 枚SOL , 约合  1938910 USDT
```