---
title: 安装无域名版Reality
date: 2026-06-02 15:01:00
categories: 技术
tags:
- vpn
- reality
- 翻墙
- 梯子
---


https://www.v2ray-agent.com/archives/1708584312877


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/一键Reality.png)



### `migrate.sh`

```sh
# 使用root用户
#
#sudo su

apt update && apt upgrade -y

apt install build-essential

###### Bun ###############
curl -fsSL https://bun.sh/install | bash
source /root/.bashrc
######################

############# Node #########
# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"
# Download and install Node.js:
nvm install 24
# Verify the Node.js version:
node -v
nvm current
# Download and install Yarn:
corepack enable yarn
# Verify Yarn version:
yarn -v

##############

source ~/.bashrc

############# 安装说明#######################
#
# 支持无域名reality协议, 韩国首尔用域名 weverse.io
#
#
# 一键无域名Reality协议安装教程：https://www.v2ray-agent.com/archives/1708584312877
# 选择 v2ray
# vless + reality端口用 443
# 域名填写   weversee.io:443
# 其他都回车即可
#
# 安装完成之后，要查看订阅:  vasma > 用户管理 > 查看订阅 ，  端口输入43585 , 会列出  ClashMeta 的 http订阅链接
#
# 服务器防火墙要开启对应443 和 43585 的 tcp端口
#
#
# 安装完成之后, 必须开启BBR加速, 否则网速很慢，操作方式：vasma > 18.BBR加速 >> 11.BBR+FQ ，  然后重启core即可， 通过https://fast.com/进行测速
#
# 还有选择 22优化系统配置参数
#
# 也可以选择 BBR + CAKE
#
# 其他说明：
#    安装完成后开启 443端口， 并配置配置文件（通过其他https进行中转，设置端口ip白名单， fantopia_coze_api 这个进行中转）
#    重启方式: vasma > core管理 > 重启
#
wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/youngqqcn/v2ray-agent/refs/heads/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
###################
#
#
# 去掉google资源直连
mv /etc/v2ray-agent/xray/conf/09_routing.json ~/
```