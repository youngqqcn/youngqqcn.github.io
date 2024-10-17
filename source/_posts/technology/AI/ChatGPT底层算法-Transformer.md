---
title: ChatGPT底层算法Transformer
date: 2024-10-17 18:06
categories: 技术
tags:
- AI
- ChatGPT
- 人工智能
- 算法
---

> http://lib.ia.ac.cn/news/newsdetail/68571


Transformer算法机制：

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/qt1.1_F09DBE9AC8895CB064276BF8ACC95B98.jpg)






![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/qt1.2_A35C601756E296B8146244F0E4764975.png)



## Transformer核心三个步骤:

- 1. 编码（Embedding）
- 2. 定位 （Positional Encoding）
- 3. 自注意力机制（Self-Attention）



以翻译为例: 将 "I love you" 翻译为中文,

- 第一步——编码(Embedding)： 将 "I love you" 中每个单词进行编码成 512维向量（实际维度可能更高）
  - 可理解为512高维空间中的一个点
- 第二步——定位(Positional encoding)： 将每个单词的向量映射到一个新的高维向量
  - 高维向量包含了单词在句子中的“位置”信息
- 第三步——自注意力机制（Self-Attention）： 通过一个Attention（Q，K，V）算法, 将每个单词向再变换为一个更高维的向量
  - 高维向量包含了单词与句子中其他单词的关系



## 总结


- 深度学习算法，如Transformer，在工程实践中表现很好，但是**为什么好**，目前缺乏理论依据
  - ChatGPT为什么那么牛逼，科学家也解释不了，反正就是**大力出奇迹**

- **智能可用高维空间中的路径进行量化(可计算化)**
