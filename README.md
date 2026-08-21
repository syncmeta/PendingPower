# PendingPower

[English](#english) · [中文](#中文)

---

## English

A menu bar tool that shows real-time power draw on macOS.

![screenshot](assets/screenshot.png)

**Apple Silicon Only**

The menu bar shows total watts, updated once per second. Opening the menu breaks
it down into CPU / GPU / ANE / Other.

How: reads SoC energy counters via Apple's private `IOReport` framework.

### Download

[Releases](https://github.com/syncmeta/PendingPower/releases)

### Requirements

- Apple Silicon Mac (the `Energy Model` counters this reads do not exist on Intel)
- macOS 13 or later
- Xcode command line tools (for building)

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

### Status

A personal experiment, not a product. It does what the screenshot shows and
nothing more — no history graph, no preferences, no launch-at-login.
There is no test suite beyond `scripts/smoke.swift`, and no CI.

`IOReport` is a private framework, so a future macOS release can change or
remove the counters this depends on.

### License

MIT — see [LICENSE](LICENSE).

---

## 中文

在 mac 的菜单栏显示实时功率的工具

![screenshot](assets/screenshot.png)

**Apple Silicon Only**

菜单栏显示总功率,每秒刷新一次。点开菜单可以看到 CPU / GPU / ANE / Other 的分项。

原理:通过 Apple 私有的 `IOReport` 框架读取 SoC 能量计数器

### 下载

[Releases](https://github.com/syncmeta/PendingPower/releases)

### 运行要求

- Apple Silicon 的 Mac(它读的 `Energy Model` 计数器在 Intel 机器上不存在)
- macOS 13 及以上
- 构建需要 Xcode 命令行工具

### 构建

```sh
# 不签名构建,产物在 /tmp/PendingPower-build/PendingPower.app
scripts/build.sh

# 带 Developer ID 签名
scripts/build.sh --sign "Developer ID Application: Your Name (TEAMID)"
```

产物特意放在 `/tmp`:在 iCloud Drive 目录里构建的话,文件同步会把
`com.apple.FinderInfo` 扩展属性重新贴回来,`codesign` 会因此报错。
项目根目录下的 `build` 是指向它的软链接。

打签名并公证过的 DMG(需要 Developer ID 和事先存好的 notarytool profile):

```sh
xcrun notarytool store-credentials AC_PROFILE \
    --apple-id "you@example.com" --team-id "TEAMID" \
    --password "app-specific-password"

scripts/build-dmg.sh \
    --sign "Developer ID Application: Your Name (TEAMID)" \
    --notary-profile AC_PROFILE
```

不构建整个 app,只验证计数器读数是否正常:

```sh
swift scripts/smoke.swift \
    Sources/PendingPower/IOReportBridge.swift \
    Sources/PendingPower/PowerMonitor.swift
```

### 现状

个人实验项目,不是产品。功能就是截图里那些,没有别的 —— 没有历史曲线、
没有偏好设置、不支持开机自启。除了 `scripts/smoke.swift` 之外没有测试,也没有 CI。

`IOReport` 是私有框架,以后的 macOS 版本可能改动或移除它依赖的那些计数器。

### 许可

MIT,见 [LICENSE](LICENSE)。
