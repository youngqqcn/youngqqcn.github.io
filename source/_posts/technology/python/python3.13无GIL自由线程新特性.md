---
date: 2025-03-27 16:11:35
title: python3.13无GIL自由线程新特性
categories: 技术
tags:
- python3.13
---


## 安装Python3.13.2


Windows: 安装python3.13, 直接下载即可，在安装目录的 `python3.13t`
- 在"Advanced Options"下，确保选择“Download free-threaded binaries(experimental)”选项，然后点击“安装”

Ubuntu: 下载代码编译
```shell
./configure --disable-gil --enable-optimizations
make

# 会覆盖系统的python
make install

# 或者， 不覆盖系统的python
make altinstall
```



## 运行测试代码:

```python
import threading


def f():
    while 1:
        pass

for i in range(16):
    threading.Thread(target=f).start()
```

使用`python3.13t` 或 `python3.13` 运行代码 `python3.13t test.py` 或 `PYTHON_GIL=0 python3.13 test.py` 或 `python3.13 -Xgil=0 test.py`, 查看16核CPU的占用率100%
- 如何没有设置 `PYTHON_GIL`， 那么 python3.13默认是无GIL的

- 对比python3.13的无GIL版本:
    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/python-nogil-test.png)

- 对比python3.13 的有GIL版本:

    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/python3.13-gil-test.png)

- 对比python3.12版本(有GIL)
    ![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/python-withgil-test.png)



## PEP-703

https://peps.python.org/pep-0703/




## 关于容器的线程安全

https://peps.python.org/pep-0703/#container-thread-safety

python底层的实现中，每个object内部使用临界区来实现线程同步

> Per-object locks with critical sections provide weaker protections than the GIL. Because the GIL doesn’t necessarily ensure that concurrent operations are atomic or correct, the per-object locking scheme also cannot ensure that concurrent operations are atomic or correct. Instead, per-object locking aims for similar protections as the GIL, but with mutual exclusion limited to individual objects.


- 在object加锁
  - `list.append, list.insert, list.repeat, PyList_SetItem`
  - `dict.__setitem__, PyDict_SetItem`
  - `list.clear, dict.clear`
  - `list.__repr__, dict.__repr__, etc.`
  - `list.extend(iterable)`
  - `setiter_iternext`
- 在2个object加锁
  - `list.extend(list), list.extend(set), list.extend (dictitems), and other specializations where the implementation is specialized for argument type.`
  - `list.concat(list)`
  - `list.__eq__(list), dict.__eq__(dict)`
- 无锁
  - len(list) i.e., list_length(PyListObject *a)
  - len(dict)
  - len(set)
- 看情况, 需要根据内存分配器的实现而定， 尽量会少用锁提升性能
  - list[idx] (list_subscript)
  - dict[key] (dict_subscript)
  - listiter_next, dictiter_iternextkey/value/item
  - list.contains



## no-GIL + async/await


```python
import threading
import asyncio
import time

async def async_range(n):
    for i in range(n):
        yield i

# 异步任务
async def async_task(name):
    for i in range(20):
        print(f"异步任务 {name} 开始执行")
        async for i in async_range(1000_0000):
            pass
        print(f"异步任务 {name} 执行结束")
    return f"结果 {name}"

# 在线程中运行异步任务
def run_async_in_thread(name):
    # 创建一个新的事件循环
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    # 运行异步任务
    result = loop.run_until_complete(async_task(name))

    # 关闭事件循环
    loop.close()

    return result

# 线程函数
def thread_function(name):
    print(f"线程 {name} 开始执行")
    result = run_async_in_thread(f"Async-{name}")
    print(f"线程 {name} 执行结束，结果: {result}")

# 主函数
def main():

    start  = time.time()
    # 创建并启动线程
    threads = []
    for i in range(16):
        thread = threading.Thread(target=thread_function, args=(f"Thread-{i+1}",))
        threads.append(thread)
        thread.start()

    # 等待所有线程完成
    for thread in threads:
        thread.join()


    print(f"所有任务执行完毕, 耗时: {time.time() - start} s" )


if __name__ == "__main__":
    main()
```


- 多进程
```python
import threading
import asyncio
import time
import multiprocessing
from typing import List


async def async_range(n):
    for i in range(n):
        yield i


# 异步任务
async def async_task(name):
    for i in range(20):
        print(f"异步任务 {name} 开始执行")
        async for i in async_range(1000_0000):
            pass
        print(f"异步任务 {name} 执行结束")
    return f"结果 {name}"


# 在进程中运行异步任务
def run_async_in_thread(name):
    # 创建一个新的事件循环
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    # 运行异步任务
    result = loop.run_until_complete(async_task(name))

    # 关闭事件循环
    loop.close()

    return result


# 线程函数
def thread_function(name):
    print(f"进程 {name} 开始执行")
    result = run_async_in_thread(f"Async-{name}")
    print(f"进程 {name} 执行结束，结果: {result}")


# 主函数
def main():

    start = time.time()
    # 创建并启动进程
    processes: List[multiprocessing.Process] = []
    for i in range(16):
        process = multiprocessing.Process(
            target=thread_function, args=(f"Process-{i+1}",)
        )
        processes.append(process)
        process.start()

    # 等待所有进程完成
    for process in processes:
        process.join()

    print(f"所有任务执行完毕, 耗时: {time.time() - start} s")


if __name__ == "__main__":
    main()

```

运行时间对比
- 使用 No-GIL python3.13 耗时`66s`
- 使用 GIL python3.13 耗时`375s`
- 使用带GIL的多进程`65s`



## 有了multiprocessing，为什么还要No-GIL ？

因为`multiprocessing`是多进程， 每个进程都有自己的内存空间， 进程间通信成本较高

- 进程间通信手段: Queue, Pipe, Semaphore, Socket, File
- 线程间同步: Lock, RLock, Condition, Event, Queue, Barrier


NO-GIL的最大优势:
- **同一程序空间，线程间通信简单**


-----


## [附] 多进程和多线程的区别:

- 多进程: 每个进程有自己的内存空间
    ```python
    from multiprocessing import Process

    # 定义一个全局变量
    counter = 0

    def increment():
        global counter
        for _ in range(1000000):
            counter += 1

    if __name__ == "__main__":
        # 创建两个进程
        p1 = Process(target=increment)
        p2 = Process(target=increment)

        # 启动进程
        p1.start()
        p2.start()

        # 等待进程完成
        p1.join()
        p2.join()

        # 打印最终的全局变量值
        print(f"Final counter value: {counter}")
    ```

    运行结果:
    ```
    $ python3.13 test_process.py
    counter: 1000000
    counter: 1000000
    Final counter value: 0
    ```

    因为主进程中的 counter没有改过, 所以最终的结果是0

- 多线程: 共享内存空间

    ```python
    # from multiprocessing import Process
    from threading import Thread

    # 定义一个全局变量
    counter = 0

    def increment():
        global counter
        for _ in range(1000000):
            counter += 1

    if __name__ == "__main__":
        # 创建两个进程
        p1 = Thread(target=increment)
        p2 = Thread(target=increment)

        # 启动进程
        p1.start()
        p2.start()

        # 等待进程完成
        p1.join()
        p2.join()

        # 打印最终的全局变量值
        print(f"Final counter value: {counter}")
    ```

    - 使用 GIL版本运行结果:
        ```
        $ python3.13 -Xgil=1 test_thread.py
        Final counter value: 2000000
        ```

    - 使用 No-GIL版本运行结果:
        ```
        $ python3.13 -Xgil=0 test_thread.py
        Final counter value: 1139283
        $ python3.13 -Xgil=0 test_thread.py
        Final counter value: 1170427
        $ python3.13 -Xgil=0 test_thread.py
        Final counter value: 1415999
        $ python3.13 -Xgil=0 test_thread.py
        Final counter value: 1205918
        ```
        - 因为没有GIL的限制, 且没有加锁， 所以多线程的结果是不确定的

  - 对counter加锁

  ```python
    from threading import Thread, Lock

    # 定义一个全局变量
    counter = 0

    lock = Lock()

    def increment():
        global counter
        for _ in range(1000000):
            lock.acquire() # 获取锁
            counter += 1
            lock.release() # 释放锁

    if __name__ == "__main__":
        # 创建两个进程
        p1 = Thread(target=increment)
        p2 = Thread(target=increment)

        # 启动进程
        p1.start()
        p2.start()

        # 等待进程完成
        p1.join()
        p2.join()

        # 打印最终的全局变量值
        print(f"Final counter value: {counter}")
  ```

  使用无GIL python运行结果:
  ```
  $ python3.13 -Xgil=0 test_thread.py
    Final counter value: 2000000
    ```