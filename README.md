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

![PendingPower 菜单栏截图](docs/menu-screenshot.png)

### 下载 / Download

[Releases](https://github.com/syncmeta/PendingPower/releases) 

M 芯片 Mac，并且系统版本在 macOS 13 或以上 就能用

Requires an Apple Silicon Mac running macOS 13 or later.

## 原理 / How

数据来源于 AppleSMC `PSTR` 系统功率。

It reads AppleSMC `PSTR` system rail power.

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
