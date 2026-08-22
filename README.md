<p align="center">
  <img src="docs/app-icon.png" width="128" alt="PendingPower 应用图标" />
</p>
<h1 align="center">PendingPower</h1>

<p align="center">
  A menu bar tool that shows real-time power draw on macOS
  <br />
  <em>在 mac 的菜单栏显示实时功率的工具</em>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue" /></a>
  <img alt="Swift" src="https://img.shields.io/badge/lang-Swift-F05138?logo=swift&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2013%2B%20%C2%B7%20Apple%20Silicon-lightgrey" />
  <a href="https://github.com/syncmeta/PendingPower/releases"><img alt="Release" src="https://img.shields.io/badge/release-v1.0.1-informational" /></a>
</p>

<p align="center"><b>Apple Silicon Only</b></p>

<p align="center">
  <img src="assets/screenshot.png" width="420" alt="菜单栏里的总功率，以及展开后的 CPU / GPU / ANE / Other 分项" />
</p>

> **这是一个人的实验项目，不是产品。**
>
> 功能就是截图里那些，没有别的。它读的是 Apple 私有的 `IOReport` 框架，
> 以后的 macOS 版本可能改动或移除那些计数器。详见下面的「现状」。
>
> *(A personal experiment, not a product. It does what the screenshot shows and
> nothing more; it reads Apple's private `IOReport` framework, which a future
> macOS release can change or remove. See "Status" below.)*

<p align="center"><a href="#english">English</a> · <a href="#中文">中文</a></p>

---

## English

The menu bar shows total watts, updated once per second. Opening the menu breaks
it down into CPU / GPU / ANE / Other.

How: reads SoC energy counters via Apple's private `IOReport` framework.

### Quick start

- **Install** — grab the app from [Releases](https://github.com/syncmeta/PendingPower/releases).
- **Build it yourself** — `scripts/build.sh`, then open
  `/tmp/PendingPower-build/PendingPower.app`.

Requirements:

- Apple Silicon Mac (the `Energy Model` counters this reads do not exist on Intel)
- macOS 13 or later
- Xcode command line tools (for building)

### What it does

- Total watts in the menu bar, refreshed once per second
- Menu breaks the total into **CPU / GPU / ANE / Other**
- That is the whole feature list

### Status

A personal experiment, not a product. It does what the screenshot shows and
nothing more — no history graph, no preferences, no launch-at-login.
There is no test suite beyond `scripts/smoke.swift`, and no CI.

`IOReport` is a private framework, so a future macOS release can change or
remove the counters this depends on.

### Build

```sh
# unsigned build — produces /tmp/PendingPower-build/PendingPower.app
scripts/build.sh

# with a Developer ID
scripts/build.sh --sign "Developer ID Application: Your Name (TEAMID)"
```

The build goes to `/tmp` on purpose: building inside an iCloud Drive folder lets
the file provider re-attach `com.apple.FinderInfo` xattrs, which `codesign`
rejects. A `build` symlink in the project root points at it.

Signed + notarized DMG (needs a Developer ID and a stored notarytool profile):

```sh
xcrun notarytool store-credentials AC_PROFILE \
    --apple-id "you@example.com" --team-id "TEAMID" \
    --password "app-specific-password"

scripts/build-dmg.sh \
    --sign "Developer ID Application: Your Name (TEAMID)" \
    --notary-profile AC_PROFILE
```

Sanity check the counter reading without building the app:

```sh
swift scripts/smoke.swift \
    Sources/PendingPower/IOReportBridge.swift \
    Sources/PendingPower/PowerMonitor.swift
```

### Download

[Releases](https://github.com/syncmeta/PendingPower/releases) — macOS only, and
Apple Silicon only.

### Repository layout

Four Swift files, about 370 lines in total. There is no architecture worth
drawing, so this README does not pretend there is one.

```
Sources/PendingPower/
├── IOReportBridge.swift      private IOReport.framework, resolved via dlsym at runtime
├── PowerMonitor.swift        samples the energy counters, turns them into watts
├── StatusBarController.swift the menu bar item and its menu
└── main.swift                NSApplicationDelegate, wires the two together
Resources/                    Info.plist, entitlements, AppIcon.icns
scripts/                      build.sh · build-dmg.sh · make-icon.swift · smoke.swift
```

### Contributing

A personal experiment — issues and PRs are welcome, but the author does not
promise a response time or a roadmap.

### License

MIT — see [LICENSE](LICENSE).

---

## 中文

菜单栏显示总功率，每秒刷新一次。点开菜单可以看到 CPU / GPU / ANE / Other 的分项。

原理：通过 Apple 私有的 `IOReport` 框架读取 SoC 能量计数器。

### 快速开始

- **直接用** —— 从 [Releases](https://github.com/syncmeta/PendingPower/releases) 下载。
- **自己构建** —— 跑 `scripts/build.sh`，产物在 `/tmp/PendingPower-build/PendingPower.app`。

运行要求：

- Apple Silicon 的 Mac（它读的 `Energy Model` 计数器在 Intel 机器上不存在）
- macOS 13 及以上
- 构建需要 Xcode 命令行工具

### 主要功能

- 菜单栏显示总功率，每秒刷新一次
- 点开菜单看 **CPU / GPU / ANE / Other** 分项
- 功能就这些，没有别的

### 现状

个人实验项目，不是产品。功能就是截图里那些，没有别的 —— 没有历史曲线、
没有偏好设置、不支持开机自启。除了 `scripts/smoke.swift` 之外没有测试，也没有 CI。

`IOReport` 是私有框架，以后的 macOS 版本可能改动或移除它依赖的那些计数器。

### 跑起来

```sh
# 不签名构建，产物在 /tmp/PendingPower-build/PendingPower.app
scripts/build.sh

# 带 Developer ID 签名
scripts/build.sh --sign "Developer ID Application: Your Name (TEAMID)"
```

产物特意放在 `/tmp`：在 iCloud Drive 目录里构建的话，文件同步会把
`com.apple.FinderInfo` 扩展属性重新贴回来，`codesign` 会因此报错。
项目根目录下的 `build` 是指向它的软链接。

打签名并公证过的 DMG（需要 Developer ID 和事先存好的 notarytool profile）：

```sh
xcrun notarytool store-credentials AC_PROFILE \
    --apple-id "you@example.com" --team-id "TEAMID" \
    --password "app-specific-password"

scripts/build-dmg.sh \
    --sign "Developer ID Application: Your Name (TEAMID)" \
    --notary-profile AC_PROFILE
```

不构建整个 app，只验证计数器读数是否正常：

```sh
swift scripts/smoke.swift \
    Sources/PendingPower/IOReportBridge.swift \
    Sources/PendingPower/PowerMonitor.swift
```

### 下载

[Releases](https://github.com/syncmeta/PendingPower/releases) —— 只有 macOS 版，
且只支持 Apple Silicon。

### 仓库结构

四个 Swift 文件，一共 370 行左右。**没有值得画的架构**，这份 README 也就不硬凑一节。

```
Sources/PendingPower/
├── IOReportBridge.swift      私有 IOReport.framework，运行时用 dlsym 解符号
├── PowerMonitor.swift        采样能量计数器，换算成瓦
├── StatusBarController.swift 菜单栏项和它的菜单
└── main.swift                NSApplicationDelegate，把上面两块接起来
Resources/                    Info.plist、entitlements、AppIcon.icns
scripts/                      build.sh · build-dmg.sh · make-icon.swift · smoke.swift
```

### 参与

个人实验项目，issue 和 PR 都欢迎，但作者不保证响应速度，也不承诺路线。

### 许可

MIT，见 [LICENSE](LICENSE)。

---

<sub>本 README 全文由 Claude 撰写。行数、文件清单与运行要求来自 2026-08-22 的实际代码核对
（`Sources/PendingPower` 四个文件共 370 行、`Package.swift` 里 `platforms: [.macOS(.v13)]`），
版本号取自 GitHub Releases 上的最新一版，不是从旧文档转抄。</sub>
