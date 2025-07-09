---
title: Ubuntu24.04安装BurpsuitePro专业版激活教程
date: 2025-07-09 14:37:00
categories: 技术
tags:
- Burpsuite
- Burpsuite Pro
- Ubuntu24.04
---


- 下载文件 ：

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/burpsuit_pro_download.png)

> 通过网盘分享的文件：
链接: https://pan.baidu.com/s/1CbFydHhJK4Wi1BPs5faQHg?pwd=ynmi 提取码: ynmi 复制这段内容后打开百度网盘手机App，操作更方便哦


- 安装 Burp Suite Pro

```
chmod +x burpsuite_pro_linux_2025_5_6.sh
./burpsuite_pro_linux_2025_5_6.sh

# 然后按照正常的步骤安装
```

- 将 `Linux.zip` 和 `BurpSuite v2025.6.3.zip` 解压到 Burpsuite安装目录下

- 目录结构如下啊
```
.
├── burpbrowser
├── BurpSuite  # 即BurpSuite v2025.6.3.zip 解压后中的 BurpSuite 目录
├── BurpSuitePro
├── burpsuite_pro.jar
├── BurpSuitePro.png
├── BurpSuitePro.vmoptions
├── jre
├── Linux # 即Linux.zip 解压后中的 Linux 目录
├── tmp.desktop
└── uninstall
```

- 进入 `Linux`目录

```
chmod +x *.sh
```

- 运行 `./Start.sh` 即可

- 然后按照教程激活即可，破解详细教程： https://www.52pojie.cn/thread-1953331-1-1.html


## 创建桌面文件


- `Linux/New_EN_Burp.sh`

```
#!/bin/bash

SCRIPT_DIR="/home/yqq/bin/BurpSuitePro/Linux"
JAVA_HOME="$SCRIPT_DIR/jre"
BURP_DIR="/home/yqq/bin/BurpSuitePro/BurpSuite"

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

echo "JAVA_HOME: $JAVA_HOME"
"$JAVA_HOME/bin/java" --version

cd "$BURP_DIR"
"$JAVA_HOME/bin/java" \
  -XX:+IgnoreUnrecognizedVMOptions \
  -javaagent:burpsuitloader.jar=loader, \
  --add-opens=java.desktop/javax.swing=ALL-UNNAMED \
  --add-opens=java.base/java.lang=ALL-UNNAMED \
  --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED \
  --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED \
  --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED \
  -jar burpsuite_pro_org.jar

```

- `~/.local/share/applications/BurpSuite.desktop` 文件

```
[Desktop Entry]
Name=BurpSuite
Comment=BurpSuite
Exec=/home/yqq/bin/BurpSuitePro/Linux/New_EN_Burp.sh
Icon=/home/yqq/bin/BurpSuitePro/BurpSuitePro.png
Terminal=false
Type=Application
Categories=Development;
StartupWMClass=burp-StartBurp
```

- `chmod +x ~/.local/share/applications/BurpSuite.desktop`

- 复制图标: `cp /home/yqq/bin/BurpSuitePro/.install4j/BurpSuitePro.png /home/yqq/bin/BurpSuitePro/BurpSuitePro.png`

- 注意， `StartupWMClass` 通过 `xprop | grep WM_CLASS` 命令，点击 BurpSuite 窗口获取真实的 WM_CLASS 名称 (第二个值)。