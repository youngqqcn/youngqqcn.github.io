---
title: react基础
date: 2023-12-06 11:42:37
categories: 技术
tags:
- React
- Javascript
- 前端
- 全栈
---

# react中文教程

- https://zh-hans.react.dev/learn


# React环境搭建

- Ubuntu： https://github.com/nodesource/distributions#ubuntu-versions
- 全局安装脚手架: `npm i -g create-react-app`
- 直接创建项目: `npx create-react-app my-app`


# antd使用

> https://ant-design.antgroup.com/components/overview-cn

- 全局安装  `npm install antd-init -g`
- antd-init
- npm install antd --save


# React

在你的组件显示在屏幕上之前，它们必须由 React 进行渲染。理解这个过程中的步骤有助于你思考你的代码如何执行并解释其行为。

想象一下，你的组件是厨房里的厨师，用食材制作出美味的菜肴。在这个场景中，React 是服务员，负责提出顾客的要求，并给顾客上菜。这个请求和服务 UI 的过程有三个步骤：

- 触发渲染（将食客的订单送到厨房）
- 渲染组件（在厨房准备订单）
- 提交到 DOM（将订单送到桌前）


作为快照的状态

- 与普通 JavaScript 变量不同，React 状态的行为更像一个快照。设置它并不改变你已有的状态变量，而是触发一次重新渲染。这在一开始可能会让人感到惊讶！


```js
console.log(score);  // 0
setScore(score + 1); // setScore(0 + 1);
console.log(score);  // 0
setScore(score + 1); // setScore(0 + 1);
console.log(score);  // 0
setScore(score + 1); // setScore(0 + 1);
console.log(score);  // 0
```


## 更新数组


| |避免使用 (会改变原始数组) | 推荐使用 (会返回一个新数组）|
|--|-----|----|
|添加元素| push，unshift|concat，[...arr] 展开语法（例子）|
|删除元素| pop，shift，splice| filter，slice（例子）|
|替换元素| splice，arr[i] = ... 赋值| map（例子）|
|排序| reverse，sort| 先将数组复制一份（例子）|



## Context使用场景




## ref 和 state 的不同之处


|ref | state |
|----|-----|
|`useRef(initialValue)`返回 `{ current: initialValue }`|`useState(initialValue)` 返回 state 变量的当前值和一个 `state` 设置函数 `( [value, setValue])`|
|更改时不会触发重新渲染|更改时触发重新渲染。|
|可变 —— 你可以在渲染过程之外修改和更新 `current` 的值。|“不可变” —— 你必须使用 `state` 设置函数来修改 `state` 变量，从而排队重新渲染。|
|你不应在渲染期间读取（或写入） `current` 值。|你可以随时读取 `state`。但是，每次渲染都有自己不变的 `state` 快照。|



## Effect


```js
const [count, setCount] = useState(0);
useEffect(() => {
  setCount(count + 1);
});

```
