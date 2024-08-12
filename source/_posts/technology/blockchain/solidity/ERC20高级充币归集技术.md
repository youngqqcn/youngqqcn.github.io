---
date: 2024-08-12  18:07
title: ERC20高级充币归集技术
categories: 技术
tags:
    - ERC20
    - 区块链
    - 智能合约
---

### 核心技术概括:

- 使用 `CREATE2`派生确定的充币地址(合约)
- 归集时在合约中 使用相同的 salt 和 hash, 创建充币地址(合约)
  - 在合约中执行 ERC20的 approve，授权本合约
  - 调用 `selfdestruct`销毁合约
- 转移使用`transferFrom`转移充币地址中的ERC20代币



----

### 实际案例

-   充币 USDC交易: https://etherscan.io/tx/0x3a5a4f8075aab5f67ae5d0be98574ddbae05daa5b3be4b82bc75dad3f3752967
-   归集(操作)USDC交易: https://etherscan.io/tx/0xf745adf975e874c4f4831e3fc07eb7aa18235013fe2d84089a20f85d0c8460f7
    -   实际上是跨链

#### 技术点剖析:

-   充币地址(接收地址)是一个"临时"合约地址
-   "临时"地址可以派生出来
-   且，"归集"合约可以操作 "临时"地址进行 `approve`操作
-   `approve`完成后即自毁(`selfdestruct`)了临时合约地址


#### 合约代码分析:

- 合约代码: https://vscode.blockscan.com/ethereum/0x07042134d4dc295cbf3ab08a4a0eff847a528171


```js
// Function that bridges taking amount from the t2bAddress where the user funds are parked.
function bridgeERC20(
    uint256 fees,
    uint256 nonce,
    bytes calldata bridgeData,
    bytes calldata signature
) external {
    // recovering signer.
    address recoveredSigner = ECDSA.recover(
        keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        address(this),
                        nonce,
                        block.chainid, // uint256
                        fees,
                        bridgeData
                    )
                )
            )
        ),
        signature
    );

    if (signerAddress != recoveredSigner) revert SignerMismatch();
    // nonce is used by gated roles and we don't expect nonce to reach the max value of uint256
    unchecked {
        if (nonce != nextNonce[signerAddress]++) revert InvalidNonce();
    }

    if (bridgeVerifiers[uint32(bytes4(bridgeData[0:4]))] == address(0))
        revert UnsupportedBridge();

    // 解析数据
    (bool parseSuccess, bytes memory parsedData) = bridgeVerifiers[
        uint32(bytes4(bridgeData[0:4]))
    ].call(bridgeData[4:bridgeData.length - 1]);

    if (!parseSuccess) revert VerificationCallFailed();

    // 解析数据
    IT2BRequest.T2BRequest memory t2bRequest = abi.decode(
        parsedData,
        (IT2BRequest.T2BRequest)
    );

    // 获取派生地址
    address t2bAddress = getAddressFor(
        t2bRequest.recipient,
        t2bRequest.toChainId
    );

    // 判断 allowance
    if (
        ERC20(t2bRequest.token).allowance(t2bAddress, address(this)) <
        t2bRequest.amount
    ) {
        // 计算salt
        bytes32 uniqueSalt = keccak256(
            abi.encode(t2bRequest.recipient, t2bRequest.toChainId)
        );

        // 调用 CREATE2 创建临时地址
        new T2BApproval{salt: uniqueSalt}(address(this));
    }

    // 将派生地址的 ERC20代币转移
    ERC20(t2bRequest.token).safeTransferFrom(
        t2bAddress,
        address(this),
        t2bRequest.amount + fees
    );

    //... 其他代码, 略
}
```

```js

// 部署派生地址
function deployApprovalContract(
    address receiver,
    uint256 toChainId
) public returns (address approvalAddress) {
    bytes32 uniqueSalt = keccak256(abi.encode(receiver, toChainId));
    approvalAddress = address(new T2BApproval{salt: uniqueSalt}(address(this)));
}

// 获取派生地址
function getAddressFor(
    address receiver,
    uint256 toChainId
) public view returns (address) {
    bytes32 salt = keccak256(abi.encode(receiver, toChainId));
    return
        address(
            uint160(
                uint256(
                    keccak256(

                        // 可以看下文的  CreateAddress2的实现
                        abi.encodePacked(
                            bytes1(0xff), // 固定的
                            address(this), // 本合约地址
                            salt, // salt

                            // 合约代码的 hash
                            keccak256(
                                abi.encodePacked(
                                    type(T2BApproval).creationCode, // 合约代码
                                    abi.encode(address(this)) // 合约
                                )
                            )
                        )
                    )
                )
            )
        );
}
```

-   `T2BApproval` 派生地址合约

```js
contract T2BApproval {
    using SafeTransferLib for ERC20;

    error ZeroAddress();
    error InvalidTokenAddress();


    // Constructor
    constructor(address _t2bRouter) {
        // Set T2b Router.
        IT2BRouter t2bRouter = IT2BRouter(_t2bRouter);

        // Set Max Approvals for supported tokens.
        uint256 tokenIndex = 0;
        while (t2bRouter.supportedTokens(tokenIndex) != address(0)) {

            // 进行 approve操作
            ERC20(t2bRouter.supportedTokens(tokenIndex)).safeApprove(
                address(t2bRouter),
                type(uint256).max
            );
            unchecked {
                ++tokenIndex;
            }
        }

        // 销毁
        selfdestruct(payable(msg.sender));
    }
}
```

安全性:

- ` new T2BApproval{salt: uniqueSalt}(address(this));`
  - CREATE2 生成的地址是基于`部署者地址`、`salt`、`合约字节码的哈希`计算的。


-  https://github.com/ethereum/go-ethereum/blob/5adf4adc8ec2c497eddd3b1ff20d2d35d65ec5fc/core/vm/instructions.go#L709-L743

```go
//  scope.Contract 是本合约地址
// input  合约代码
res, addr, returnGas, suberr := interpreter.evm.Create2(scope.Contract, input, gas, &endowment, &salt)
```


- https://github.com/ethereum/go-ethereum/blob/master/core/vm/evm.go#L583-L587

```go
// Create2 creates a new contract using code as deployment code.
//
// The different between Create2 with Create is Create2 uses keccak256(0xff ++ msg.sender ++ salt ++ keccak256(init_code))[12:]
// instead of the usual sender-and-nonce-hash as the address where the contract is initialized at.
func (evm *EVM) Create2(caller ContractRef, code []byte, gas uint64, endowment *uint256.Int, salt *uint256.Int)
 (ret []byte, contractAddr common.Address, leftOverGas uint64, err error) {

    // 合约代码的hash
	codeAndHash := &codeAndHash{code: code}


	contractAddr = crypto.CreateAddress2(caller.Address(), salt.Bytes32(), codeAndHash.Hash().Bytes())
	return evm.create(caller, codeAndHash, gas, endowment, contractAddr, CREATE2)
}
```

- https://github.com/ethereum/go-ethereum/blob/master/crypto/crypto.go#L123-L125

生成地址

```go
// CreateAddress2 creates an ethereum address given the address bytes, initial
// contract code hash and a salt.
func CreateAddress2(b common.Address, salt [32]byte, inithash []byte) common.Address {
	return common.BytesToAddress(Keccak256([]byte{0xff}, b.Bytes(), salt[:], inithash)[12:])
}
```


- 略 https://github.com/ethereum/go-ethereum/blob/master/core/vm/evm.go#L448




