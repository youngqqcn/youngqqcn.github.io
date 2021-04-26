---
title: hexo安装发布流程记录
tags: hexo,github.io
categories: 技术
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

  

- 发布到 github.io
- 使用  `hexo g` 命令生成静态网页
  - 使用命令`hexo deploy`  发布文章到github.io



- 将源文件上传到github备份

  可以参考: https://www.jianshu.com/p/8814ce1da7a4

  - 新建dev分支
  - 将 `scaffolds`,  `source`, `themes` , `_config.yml` , `package.json` 等上传