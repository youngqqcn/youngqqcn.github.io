---
title: 如何开发AI-Agent?
date: 2025-05-13 10:36
categories: 技术
tags:
- AI
- 人工智能
- Agent
- LLM
- 大语言模型
- 协议
- MCP
---

> 参考文章：
> - https://github.com/youngqqcn/12-factor-agents
> - https://www.anthropic.com/engineering/building-effective-agents#agents

## 前言

2025年，底层大模型的快速发展，AI Agent 和 MCP类工具爆发式增长， 编程领域(或软件开发)正在经历一场新的**范式转变**。

正如很多关键的科技革命一样，需要一段时间的渐变过程。我们以为未来还很遥远，其实未来已来。


## 软件开发范式简史
> https://github.com/humanlayer/12-factor-agents/blob/main/content/brief-history-of-software.md

60年前，
![xx](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250513-102417.jpg)


20年前, 用编程语言编写确定的处理逻辑
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250513-102450.jpg)


10~15年前, 2012左右 , 在系统中加入了机器学习(Machine Learning), 对数据进行分类处理。

![xx](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250513-102553.jpg)


现在, LLM+Agent， 给出一个目标和一些限定规则(提示词+外部工具)， 让AI自己去完成。
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250513-102641.jpg)

由LLM自己决定解决问题的路径:

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250513-102709.jpg)



## Agent开发的基本要素

- [**要素1: 将自然语言转为外部工具调用**](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-01-natural-language-to-tool-calls.md)
  - 提供一些外部工具API给LLM获取外部数据, 由LLM决定需要调用的外部工具, 这也是目前MCP主流方式
  ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250513-104501.jpg)



- [**要素2: 掌控你提示词**](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-02-own-your-prompts.md)
  - 不要将你的系统提示词交给框架，而是要自己掌握，这样可以随时优化调整

- [要素3: 掌控上下文窗口](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-03-own-your-context-window.md)
  - 在任何时候，给LLM的输入包含 "到目前为止已经发生的" 和 "接下来要做哪一部？"
  - 上下文包括:
    - 提示词
    - 文档或外部数据(RAG)
    - 过去的状态，工具调用，工具调用结果，其他历史信息
    - 历史消息（记忆）


- [要素4: 工具只是结构化的输出](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-04-tools-are-structured-outputs.md)
  - 将工具列表以json格式或者提示词格式(XML) 提供给LLM, LLM在需要调用外部工具时会中断，输出工具调用参数，然后由外部客户端调用工具，将调用结果和上下文传递给LLM

- [要素5: Unify execution state and business state](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-05-unify-execution-state.md)
  - TODO, 暂不理解

- [要素6: Launch/Pause/Resume with simple APIs](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-06-launch-pause-resume.md)
  - Agent是一个程序，需要做到可以控制Agent的启动，暂停，恢复

- [要素7: Contact humans with tool calls](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-07-contact-humans-with-tools.md)
  - 工具调用

- [要素8: 掌控你的工作流](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-08-own-your-control-flow.md)
  - 可以做很多其他事情

- [要素9: 将LLM的错误信息包含在上下文](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-09-compact-errors.md)
  - 以便LLM可以自我修复
- [**要素10: 小而专(模块化)**](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-10-small-focused-agents.md)
  - 这是最重要的一条原则
  - 原因：agent越通用，上下文就越长且复杂，越复杂的上下文会导致LLM越难以理解，而迷失方向。因此专于一件事情的agent会更加稳定。
  - 优点：
    - 方便上下文管理
    - 明确的职责
    - 可靠
    - 方便测试
    - 方便调试

- [要素11: Trigger from anywhere, meet users where they are](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-11-trigger-from-anywhere.md)
  - 尽可能多的渠道，方便用户触及


- [要素12: Make your agent a stateless reducer](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-12-stateless-reducer.md)
  - TODO:  暂不理解


- [**要素13: 提前获取你需要的数据,而不要等工具调用**](https://github.com/humanlayer/12-factor-agents/blob/main/content/appendix-13-pre-fetch.md)
  - 如果你确定某个工具大概率会调用，你可以提前获取数据，而不是等到LLM工具调用，浪费时间

