---
date: 2024-07-30 11:34
title: 17_Solana程序安全审计-openbook-dex
categories: 技术
tags:
- 区块链
- Solana
- Anchor
- 安全
- 审计
---

> 审计报告: https://github.com/openbook-dex/openbook-v2/blob/master/audit/openbook_audit.pdf

- place_order方法缺少下单方向检查，黑客可以下反方向的单， 导致用户的下单金额被盗



漏洞修复:

https://github.com/openbook-dex/openbook-v2/commit/1b40b6898f7fca130d47f74c66c8f3017d17753