---
date: 2023-1-7
title: 再次分析delegatecall和call的区别
categories: 技术
tags:
- 区块链
- 代理合约
- solidity
---


在之前的文章中，已经详细介绍了`delegatecall`和`call`的用法, 原文： [EIP1967-实现可升级智能合约](./EIP1967-实现可升级智能合约.md)


---
#### delegatecall:


```sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _contract, uint _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
```

调用合约`A`的`setVars`函数，`setVars`合约内会以`delegatecall`的方式调用`合约B`, 更确切地说是`合约A`将`合约B`的`setVars`函数代码加载到`合约A`的运行环境，因此，就很容易理解`setVars`修改的是`合约A`中的数据，而不是`合约B`中的数据了。

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20230107-115127)


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/1*4OB3IwTF1AkW6zH3tJv8Tw.webp)

#### call




```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint public num;
    address public sender;
    uint public value;

    function setVars(address _contract, uint _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.call(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );
    }
}
```


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/1*PwYIsFyDM60IW4KuDkUncA.webp)



