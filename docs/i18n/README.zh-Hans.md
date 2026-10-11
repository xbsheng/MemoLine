<img src="../images/desktop.jpg" alt="Mac 桌面：五张彩色纸备忘录挂在菜单栏下方的一根细绳上。">

# MemoLine

把备忘录晾在 macOS 菜单栏下面的一根绳上。
看不着，但够得着。

<p>
  <a href="../../README.md">English</a> ·
  简体中文 ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português (Brasil)</a>
</p>

把指针停在菜单栏，绳子带着卡片滑下来，卡片轻轻晃着；移开指针，它就收起。
桌面上什么都没有，也没有窗口要打开。

免费，MIT 许可，macOS 13 及以上。没有账号，不联网，不要任何权限。

<br>

## 一个动作一件事

| 动作 | 结果 |
|:--|:--|
| 指针停在菜单栏 | 绳子在那一块屏幕滑下来 |
| 单击卡片 | 写这条备忘录 |
| 左上角的复制按钮 | 复制文字，卡片闪一下「已复制」 |
| 右上角的叉 | 取下这条（删除） |
| 沿绳子拖动卡片 | 换位置，其它卡片让开 |
| 把卡片拖出绳外 | 把文字拖给别的 App，原卡片留在绳上 |
| 右键卡片 | 编辑、复制、新建、换纸张、移动、取下 |
| 绳头的 **＋** | 新建一条，并直接打开编辑器 |
| 绳头的 **⌃** | 把绳子收起来 |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>N</kbd> | 新建备忘录 |
| <kbd>⌃</kbd><kbd>⌥</kbd><kbd>M</kbd> | 显示 / 收起绳子（可在菜单栏里改） |
| 在绳上两指左右滑 | 卡片多于一屏时前后翻看 |
| 编辑器里 <kbd>⌘</kbd><kbd>C</kbd> | 和别处一样复制 |

菜单栏图标里还有：全部取下、放下绳子的时机、绳上保留多少条、卡片大小、快捷键、
声音、登录时打开。

<br>

## 写

双击卡片，绳子下方就会浮出一张纸，颜色和那张卡片一致。边写边存，所以怎么关都能留下；
底部一排色点换纸张，卡片和编辑器同时变色。

<img src="../images/editor.png" width="340" alt="编辑器：一张彩色纸，底部五个纸色，右下角是「完成」。">

<br>

## 安装

从[最新发布](../../releases/latest)下载 `MemoLine.zip`，解压后把 **MemoLine.app** 拖进「应用程序」。

应用是 ad-hoc 签名的（Apple 开发者 ID 要年费），所以第一次打开时 macOS 会说无法验证开发者。放行一次即可：

- **macOS 15 及以上**：「系统设置 › 隐私与安全性」→ 往下找到「安全性」→ 点 MemoLine 旁边的**仍要打开**
- **更早的系统**：右键点应用，选**打开**
- **不想点**：`xattr -dr com.apple.quarantine /Applications/MemoLine.app`

之后就和普通应用一样。它不要任何权限：不录屏、不要辅助功能、不联网。

### 或者自己构建

需要 macOS 13 以上和 Swift 工具链，Xcode 可选。

```sh
git clone https://github.com/xbsheng/MemoLine.git
cd MemoLine
scripts/build-app.sh        # 产出 build/MemoLine.app，通用二进制
open build/MemoLine.app
```

`swift build && .build/debug/MemoLine` 也能直接跑，不带 .app 外壳。

不用屏幕就能自检，也不会碰你正在用的备忘录：

```sh
swift run MemoLine --self-check     # 布局、排序、存储
swift scripts/check-strings.swift   # 每种语言的字符串都齐
```

想让它开机就在：把 app 拖进「应用程序」，再在菜单栏里打开「登录时打开」。

<br>

## 备忘录存在哪

`~/Library/Application Support/MemoLine/memos.json`，就是 JSON，一条一个条目。
不离开这台 Mac：没有账号、不联网、无统计、不要任何权限，只写这一个文件。

<br>

## 许可

MIT，见 [LICENSE](../../LICENSE)。

绳子的交互——菜单栏上方的晾衣绳、夹子、摇摆——来自 Alejandro Buján 的
[Tendedero](https://github.com/alejandrobujan/tendedero)，本应用基于它构建（同为 MIT）。
按那份许可的要求，MemoLine 用自己的名字和图标，与 Tendedero 无隶属关系。

<sub>本文译自英文 README。代码结构见英文版。</sub>
