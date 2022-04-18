---
date: 2022-04-18
title: NFT学习
categories: 技术
tags: 
- 区块链
- NFT
- ERC721
---


# NFT学习


ERC721官网：[http://erc721.org/](http://erc721.org/)

```solidity

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 /* is ERC165 */ {
    // 事件：转移token
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    //事件： 授权approved管理owner的tokenId
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    //事件：  授权operator管理所有资产
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // 获取token的数量
    function balanceOf(address owner) external view returns (uint256 balance);

    // 获取token所有者
    function ownerOf(uint256 tokenId) external view returns (address owner);

    // 安全转移，首先会检查合约是否能够识别ERC721协议，以防止转进区的NFT被锁住
    // from, to 都不能是零地址
    // 如果调用者不是from，那么，在此之前必须已经被授权
    // 如果to是智能合约，那么，to必须实现IERC721Receiver-onERC721Received
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    // 转移函数
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

   
    // 授权函数
    function approve(address to, uint256 tokenId) external;

    
    // 获取某个token授权的账户
    function getApproved(uint256 tokenId) external view returns (address operator);

   
    // 授权operator管理所有资产 
    function setApprovalForAll(address operator, bool _approved) external;

   
    // 检查是否有授权
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    
    // 同上，多了一个data参数
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


//用于接收ERC721的智能合约必须实现此 `IERC721Receiver` 接口
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    // 当智能合约收到ERC721 token时，此函数就会被调用，并返回一个selector以确认收到了token    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

```



所谓NFT（Non-Fungible Token）就是保证tokenId唯一即可，关于tokenId生成，有很多方式。CryptoKitty中是用数组的index

```solidity

Kitty[] kitties; 

uint256 newKittenId = kitties.push(_kitty) - 1; // push 会返回数组的长度，用元素的index作为token的ID

```