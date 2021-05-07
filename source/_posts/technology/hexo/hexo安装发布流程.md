---
title: hexo安装发布流程记录
tags: hexo
categories: 技术
date: 2021-04-26
---

- 参考文档
  - https://hexo.io
  - https://www.jianshu.com/p/4f3e1b6d1ca5



- 安装步骤

  ```
  npm install hexo-cli -g
  hexo init blog
  cd blog
  npm install
  hexo server     #本地发布 http://localhost:4000/
  
  ```


直接修改source分支下的文档提交到github的source分支即可, github会自动编译出静态文件放在master分支
  
