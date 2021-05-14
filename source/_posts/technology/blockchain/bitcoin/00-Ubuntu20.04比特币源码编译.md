---
title: Ubuntu20.04比特币源码编译
date: 2021-05-14 09:55:00
tags: 
- 区块链
- 比特币源码
categories: 技术
---

原来的区块链学习笔记仓库 [QBlockChainNotes](https://github.com/youngqqcn/QBlockChainNotes)大部分笔记已经发布在我的csdn博客[https://blog.csdn.net/yqq1997/](https://blog.csdn.net/yqq1997/). 所以, 以后这边的技术博客主要发布新写的博客.

按照2021的计划, 先从Bitcoin源码分析和go-ethereum分析开始写.相关的源码也会上传至github并在博客中贴出仓库路径.


# Ubuntu20.04比特币源码编译

```
# Update OS before starting
# -----------------------------------------------------------------------------------------------------------
sudo apt update && sudo apt upgrade

# Install Dependencies
# -----------------------------------------------------------------------------------------------------------
# Build requirements:
sudo apt install git build-essential libtool autotools-dev automake pkg-config bsdmainutils python3

# Install required dependencies
sudo apt install libevent-dev libboost-system-dev libboost-filesystem-dev libboost-test-dev libboost-thread-dev

# Install the BerkeleyDB from Ubuntu repositories:
sudo apt install libdb-dev libdb++-dev

# Optional: upnpc
sudo apt install libminiupnpc-dev

# Optional ZMQ:
sudo apt install libzmq3-dev

# For GUI:
sudo apt install libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools

# For QR Code support
sudo apt install libqrencode-dev

# Install Bitcoin
# -----------------------------------------------------------------------------------------------------------
git clone https://github.com/bitcoin/bitcoin.git

# Move into project directory
cd bitcoin

# Config
# -----------------------------------------------------------------------------------------------------------
# Generate config script
./autogen.sh

# Configure, with incompatible BerkeleyDB
./configure --with-incompatible-bdb

# If debugging symbols not required, amend compile flags:
./configure --with-incompatible-bdb CXXFLAGS="-O2"

# ...lot's of checking...

# Make
# -----------------------------------------------------------------------------------------------------------
make

# Install - sudo is required to install binaries in /usr/local/bin
sudo make install 

```