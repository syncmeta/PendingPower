<p align="center">
  <img src="docs/app-icon.png" width="128" alt="PendingPower 应用图标" />
</p>
<h1 align="center">PendingPower</h1>
<p align="center">
  macOS menu bar app showing real-time system power
  <br />
  Mac 菜单栏显示实时功率的工具
</p>




<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue" /></a>
  <img alt="Swift" src="https://img.shields.io/badge/lang-Swift-F05138?logo=swift&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2013%2B%20%C2%B7%20Apple%20Silicon-lightgrey" />
  <a href="https://github.com/syncmeta/PendingPower/releases"><img alt="Release" src="https://img.shields.io/badge/release-v1.0.4-informational" /></a>
</p>

### 下载 / Download

[Releases](https://github.com/syncmeta/PendingPower/releases) 

M 芯片 Mac，并且系统版本在 macOS 13 或以上 就能用

Requires an Apple Silicon Mac running macOS 13 or later.

从 v1.0.3 起，应用通过 Sparkle 自动检查签名更新。发现新版时由用户确认安装；菜单里也可以手动选择“检查更新…”。旧版没有更新器，升级到 v1.0.3 需要手动安装一次。

Starting with v1.0.3, the app checks for signed updates with Sparkle. Installation is confirmed by the user. Earlier versions require one manual upgrade.

v1.0.4 起仅显示 AppleSMC `PSTR` 系统功率。菜单只有“检查更新… / 退出 / 关于”，关于窗口提供 GitHub 仓库链接。提供简体中文与英文，跟随 macOS 的应用语言设置。无法读取 `PSTR` 时显示 `— W`。

Starting with v1.0.4, PendingPower shows only AppleSMC `PSTR` system power. The menu contains Check for Updates, Quit, and About; the About window links to the GitHub repository. It follows the macOS app language setting in Simplified Chinese or English. An unavailable `PSTR` reading appears as `— W`.



## 原理 / How

菜单栏显示 AppleSMC `PSTR` 系统功率，不使用 IOReport。这个内部功率读数不等于插座输入功率；`PSTR` 是未公开的硬件传感器键，某些机型可能没有提供。

The menu bar reads AppleSMC `PSTR` system rail power without IOReport. This internal reading is not wall input power. `PSTR` is an undocumented hardware sensor key and may be unavailable on some Macs.



### 仓库结构

```
Sources/PendingPower/
├── SMCPowerReader.swift      读取 AppleSMC PSTR 整机功率
├── PowerMonitor.swift        定时采样 PSTR
├── StatusBarController.swift 菜单栏项和它的菜单
└── main.swift                NSApplicationDelegate，把上面两块接起来
Resources/                    Info.plist、entitlements、AppIcon.icns
scripts/                      build.sh · build-dmg.sh · make-icon.swift · smoke.swift
```



### Repository layout

```
Sources/PendingPower/
├── SMCPowerReader.swift      reads AppleSMC PSTR system rail power
├── PowerMonitor.swift        samples PSTR on a timer
├── StatusBarController.swift the menu bar item and its menu
└── main.swift                NSApplicationDelegate, wires the two together
Resources/                    Info.plist, entitlements, AppIcon.icns
scripts/                      build.sh · build-dmg.sh · make-icon.swift · smoke.swift
```



### 许可 / License

MIT
