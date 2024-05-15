---
date: 2024-5-15
title: P2P技术(UDP)打洞
tags:
- 网络编程
- P2P
- UDP
- NAT
categories: 技术
---

- 文章: https://evilpan.com/2015/10/31/p2p-over-middle-box/

- 示例: https://github.com/youngqqcn/P2P-Over-MiddleBoxes-Demo/


其中最终核心的就是:

## 端点在不同的NAT之后
假设客户端A和客户端B的地址都是内网地址,且在不同的NAT后面. A、B上运行的P2P应用程序和服务器S都使用了UDP端口1234,A和B分别初始化了 与Server的UDP通信,地址映射如图所示:

```
                            Server S
                        18.181.0.31:1234
                               |
                               |
        +----------------------+----------------------+
        |                                             |
      NAT A                                         NAT B
155.99.25.11:62000                            138.76.29.7:31000
        |                                             |
        |                                             |
     Client A                                      Client B
  10.0.0.1:1234                                 10.1.1.3:1234
```


现在假设客户端A打算与客户端B直接建立一个UDP通信会话. 如果A直接给B的公网地址138.76.29.7:31000发送UDP数据,NAT B将很可能会无视进入的 数据（除非是Full Cone NAT）,因为源地址和端口与S不匹配,而最初只与S建立过会话. B往A直接发信息也类似.

**假设A开始给B的公网地址发送UDP数据的同时,给服务器S发送一个中继请求,要求B开始给A的公网地址发送UDP信息. A往B的输出信息会导致NAT A打开 一个A的内网地址与与B的外网地址之间的新通讯会话, B往A亦然.** 一旦新的UDP会话在两个方向都打开之后,客户端A和客户端B就能直接通讯, 而无须再通过引导服务器S了.

UDP打洞技术有许多有用的性质. 一旦一个的P2P链接建立,链接的双方都能反过来作为“引导服务器”来帮助其他中间件后的客户端进行打洞, 极大减少了服务器的负载. 应用程序不需要知道中间件具体是什么（如果有的话）,因为以上的过程在没有中间件或者有多个中间件的情况下 也一样能建立通信链路.




- 服务端： https://github.com/youngqqcn/P2P-Over-MiddleBoxes-Demo/blob/master/p2pchat/server.c

    ```c

    void on_message(int sock, endpoint_t from, Message msg) {
        log_debug("RECV %d bytes FROM %s: %s %s", msg.head.length,
                ep_tostring(from), strmtype(msg.head.type), msg.body);
        switch(msg.head.type) {


            case MTYPE_LOGIN: // 登录, 记录客户端的地址
                {
                    if (0 == eplist_add(g_client_pool, from)) {
                        log_info("%s logged in", ep_tostring(from));
                        udp_send_text(sock, from, MTYPE_REPLY, "Login success!");
                    } else {
                        log_warn("%s failed to login", ep_tostring(from));
                        udp_send_text(sock, from, MTYPE_REPLY, "Login failed");
                    }
                }
                break;

            // ....

            case MTYPE_PUNCH: // UDP打洞核心逻辑
                {
                    endpoint_t other = ep_fromstring(msg.body);
                    log_info("punching to %s", ep_tostring(other));

                    // 向目的地址发送打洞PUNCH消息, 并将源地址作为消息体，发给目的地址
                    udp_send_text(sock, other, MTYPE_PUNCH, ep_tostring(from));

                    // 向源地址发送一个消息, 源地址收到不会回复
                    udp_send_text(sock, from, MTYPE_TEXT, "punch request sent");

                }
                break;
            case MTYPE_PING:
                udp_send_text(sock, from, MTYPE_PONG, NULL);
                break;
            case MTYPE_PONG:
                break;
            default:
                udp_send_text(sock, from, MTYPE_REPLY, "Unkown command");
                break;
        }
    }

    ```


- 客户端：

    ```c

    void on_message(endpoint_t from, Message msg) {
        log_debug("RECV %d bytes FROM %s: %s %s", msg.head.length,
                ep_tostring(from), strmtype(msg.head.type), msg.body);
        // from server
        if (ep_equal(g_server, from)) {
            switch (msg.head.type) {
                case MTYPE_PUNCH: // 收到服务端的打洞请求，
                    {
                        endpoint_t peer = ep_fromstring(msg.body);
                        log_info("%s on call, replying...", ep_tostring(peer));

                        // 给源地址回复一条消息,
                        udp_send_text(g_clientfd, peer, MTYPE_REPLY, NULL);
                    }
                    break;
                case MTYPE_REPLY:
                    log_info("SERVER: %s", msg.body);
                    break;
                default:
                    break;
            }
            return;
        }
        // from peer
        switch (msg.head.type) {
            case MTYPE_TEXT:
                log_info("Peer(%s): %s", ep_tostring(from), msg.body);
                break;
            case MTYPE_REPLY: // UDP打洞打通了
                log_info("Peer(%s) replied, you can talk now", ep_tostring(from));
                eplist_add(g_peers, from);
            case MTYPE_PUNCH:
                /*
                * Usually we can't recevie punch request from other peer directly,
                * but it could happen when it come after we reply the punch request from server,
                * or there's a tunnel already.
                * */
                log_info("Peer(%s) punched", ep_tostring(from));
                udp_send_text(g_clientfd, from, MTYPE_TEXT, "I SEE YOU");
                break;
            case MTYPE_PING:
                udp_send_text(g_clientfd, from, MTYPE_PONG, NULL);
                log_info("Peer(%s) pinged", ep_tostring(from));
            default:
                break;
        }
    }
    ```




-----------------


以上的代码我在本地和2台服务做了测试，成功：

```
                Server(腾讯云服务器)


    ClientA(本机)            ClientB(aws服务器 )

```

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/udp_punch.jpg)
