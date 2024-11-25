---
title: 优化Docker的overlay2占用磁盘过大的问题
date: 2024-11-25 16:37:00
categories: 技术
tags:
- docker
- 优化
- linux
---

这个命令会删除停止的容器、未使用的网络、悬挂的镜像和未使用的卷

```
docker system prune -a
```