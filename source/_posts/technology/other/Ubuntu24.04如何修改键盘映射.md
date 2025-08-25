---
title: Ubuntu24.04如何修改键盘映射
date: 2025-08-25 14:37:00
categories: 技术
tags:
    - Ubuntu24.04
---

https://cn.linux-terminal.com/?p=8225

之前直接修改 /usr/share/X11/xkb/keycodes/evdev ， 但是在 wayland 模式下，这个方法会存在很多问题。

有些软件不认这个映射，比如 vscode 。

因此，使用 udev 规则来修改键盘映射。

关于 udev 规则 和 x11 的 evdev 的区别：

udev 规则：系统全局生效
- 只要设备接入系统，无论你在哪个环境（纯控制台 tty、X11 图形界面、Wayland 桌面），udev 修改的按键映射都会生效。
- 例：若用 udev 把 “Caps Lock” 键的硬件编码改成 “Ctrl”，则在 tty 控制台（按 Ctrl+Alt+F1 进入）和 X11 浏览器中，该键都会被识别为 Ctrl。

X11 evdev 映射：仅 X11 环境生效
- 离开 X11 后（如纯控制台、Wayland 桌面），映射完全失效。因为 evdev 是 X11 专属的驱动，无法影响非 X11 系统的输入处理。
- 例：用 evdev（如 xmodmap）把 “Caps Lock” 改成 “Ctrl”，在 X11 下有效，但进入 tty 控制台后，该键仍会被识别为 Caps Lock。

详细的修改方法：https://cn.linux-terminal.com/?p=8225

修改之后， vscode 已经没有问题了。
