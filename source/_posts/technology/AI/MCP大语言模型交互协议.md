---
title: MCP大语言模型交互协议
date: 2025-05-09 16:36
categories: 技术
tags:
- AI
- 人工智能
- LLM
- 大语言模型
- 协议
- MCP
---

# Model Context Protocol (MCP)

> 官方文档: https://modelcontextprotocol.io/introduction



> 入门教程: https://github.com/liaokongVFX/MCP-Chinese-Getting-Started-Guide


什么是MCP？

模型上下文协议（MCP）是一个创新的开源协议，它重新定义了大语言模型（LLM）与外部世界的互动方式。MCP 提供了一种标准化方法，使任意大语言模型能够轻松连接各种数据源和工具，实现信息的无缝访问和处理。MCP 就像是 AI 应用程序的 USB-C 接口，为 AI 模型提供了一种标准化的方式来连接不同的数据源和工具。

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/image-20250223214308430.png)



MCP 有以下几个核心功能：

- Resources 资源
- Prompts 提示词(模板)， 用于给客户端提供提示词模板
- Tools 工具
- Sampling 采样
- Roots 根目录
- Transports 传输层
  - stdio 用于本地
    - 通过 uvx 或 npx 跑一个本地服务供mcp客户端（也是大模型客户端）调用
  - streamable http 最新的
  - http + sse : 已废弃，老的mcp依然使用



MCP客户端:
- Claude App (要翻墙)
- Cusor
- Vscode
- Cherry Studio
- ...


### mcp的资源

目前 MCP 非常火爆，很多开发者参与:

- https://github.com/modelcontextprotocol/servers/tree/main/src

- https://mcp.so/

- https://www.modelscope.cn/mcp

- https://github.com/punkpeye/awesome-mcp-servers/tree/main


### MCP的工作原理
> 关于mcp工作过程 https://zhuanlan.zhihu.com/p/29001189476

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/v2-2bcd98f6541da0b6f14dc9082ee2dcda_1440w.jpg)




- 1, 用户使用客户端（如 Cursor, Cherry Studio）, 并指定开启的mcp工具，并向大模型提出问题
- 2, 客户端将问题发大模型，同时附带上可使用的mcp工具列表
- 3, 如果大模型需要调用mcp工具获取外部数据，大模型会中断并返回需要调用的工具列表, 并包含一个中断原因: tool_call; 如果不需要调用工具，则直接返回结果
- 4, 客户端根据大模型返回的工具列表，调用相应的mcp工具, 获取外部数据
- 5, 客户端将获取到的数据，传递给大模型
- 6, 大模型根据获取到的数据，继续处理问题
- 7, 大模型返回结果
- 8, 客户端将结果返回给用户



### MCP server 开发

> 官方文档: https://modelcontextprotocol.io/introduction
> Python SDK: https://github.com/modelcontextprotocol/python-sdk

支持 Python, Typescript, Java ...

这里以 Python 为例, 用 `uv`创建一个项目

如果没有安装 `uv`, 请先安装 `uv`: https://docs.astral.sh/uv/getting-started/installation/

```
uv init mcp-server-demo

cd mcp-server-demo

uv add "mcp[cli]"

source .venv/bin/activate

```


创建一个  `add_server.py`, 代码:

```python
# server.py
from mcp.server.fastmcp import FastMCP

# Create an MCP server
mcp = FastMCP("Demo")


# Add an addition tool
@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers"""
    return a + b


# Add a dynamic greeting resource
@mcp.resource("greeting://{name}")
def get_greeting(name: str) -> str:
    """Get a personalized greeting"""
    return f"Hello, {name}!"


if __name__ == "__main__":
    # Start the server
    mcp.run(transport="streamable-http")

```

**调试 MCP server**:

- 测试/调试MCP程序, 启动2个终端
- 在一个终端运行 mcp 服务, `streamable-http` 默认监听 `8000` 端口 和 `mcp`端点 ```python add_server.py```

- 在另外一个终端中, 启动一个测试客户端 ```mcp dev add_server.py ```

   ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/mcp_demo_20250509.png)


- 浏览器打开 `http://127.0.0.1:6274`

- Transport 选择 `streamable-http`

- URL 填入 `http://localhost:8000/mcp`

- 点击 `Connect`, 可以看到连接成功

- 然后点击  `Tools`, 点击 `List Tools` 列出所有的工具
- 点击 `add` 进行测试, 输入 `a` 和 `b` 的值, 点击 `Run Tool`, 可以看到返回结果

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250509-173256.jpg)



**在客户端使用 MCP server**

在 Cherry Studio 中使用上面的 add MCP server

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250509-173901.jpg)



在 Cherry Studio 中选择支持工具调用的大模型(带工具icon的模型)
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250509-174150.jpg)


在对话中，开启我们刚才添加的 my_test_add工具:
![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250509-174336.jpg)


因为我们这个add工具过于简单，如果直接问大模型 100 + 3 等于多少，模型会直接返回结果，而不会调用我们添加的 add 工具 ， 因此，我们这里需要换种方式提问，以便大模型能够调用我们添加的 add 工具

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20250509-174526.jpg)


可见， 大模型调用了我们添加的 add 工具，并返回了正确结果