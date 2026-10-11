# 推箱子 Sokoban

iPhone 上的经典推箱子益智游戏。SwiftUI 写的，无三方依赖。

- 设备：**iPhone 竖屏**，最低 iOS 15.0
- 安装：IPA 传到手机后用 **TrollStore（巨魔）** 打开
- 编译：本机没有 Xcode，由 GitHub Actions 出包

## 怎么玩

把箱子推到绿色目标点上，全部推上去就过关。

| 操作 | 方式 |
|---|---|
| 移动 / 推箱子 | 屏幕下方方向键，或在棋盘上滑动 |
| 撤销 | 「撤销」按钮（可以一直退回到开局） |
| 重开 | 「重来」按钮 |
| 选关 | 顶部数字条 |

被墙挡住、或者箱子后面没地方站的时候，这一步不成立 —— 步数不计，也不会白白消耗撤销次数。

## 构建

```bash
git add -A
git commit -m "feat: xxx"
git push origin main
```

GitHub Actions 编译完把 IPA 放进 Releases，文件名形如
`Sokoban-v0.1.0.B123.ipa`。下载后用巨魔安装。

工程唯一真源是 `project.yml`（XcodeGen），**不要手改 `Sokoban.xcodeproj`** —— CI 会重新生成，手改必丢。

## 加关卡

打开 `Sokoban/Data/Levels.swift`，照着现有格式往下加一条：

```swift
(name: "8 · 关卡名", rows: [
    "########",
    "#      #",
    "#  @   #",
    "#  $ . #",
    "#      #",
    "########",
]),
```

用的是 Sokoban 的通用字符表：

| 字符 | 含义 |
|---|---|
| `#` | 墙 |
| (空格) | 地板 |
| `.` | 目标点 |
| `$` | 箱子 |
| `*` | 箱子压在目标点上 |
| `@` | 玩家 |
| `+` | 玩家站在目标点上 |

注意事项：

- **行尾空格不用管**，代码会自动把每行补齐到一样宽。
- **箱子和目标点数量必须相等**，否则这关会被跳过（启动日志里能看到原因）。
- **必须有 `@`**，否则同样被跳过。
- 关卡在启动时会做一遍校验。加完记得先自己数一遍箱子数。

## 代码结构

```
Sokoban/
├── SokobanApp.swift        入口
├── Models/
│   ├── Geometry.swift      Pos / Direction / Cell
│   ├── Level.swift         关卡数据结构 + 错误类型
│   └── GameState.swift     全部游戏逻辑：解析、移动、推、撤销、过关判定
├── Data/
│   └── Levels.swift        关卡表（字符格式）
└── Views/
    ├── GameView.swift      顶栏 / 选关条 / 手势 / 过关提示
    ├── BoardView.swift     Canvas 画棋盘
    └── ControlPad.swift    方向键 + 撤销 + 重开
```

游戏规则全部集中在 `GameState`，视图只读状态、调方法。加玩法（比如推箱子时的"连锁"、撤销改限制步数）只需要动 `GameState.swift`。

## 渲染说明

棋盘用 SwiftUI 的 `Canvas` 一次画完，不是几百个 View 堆的。格子大小按棋盘行列数算，短边留白居中，所以不同尺寸的关卡都能正常显示。

## iOS 15 兼容注意

代码里**没有用任何 iOS 16+ 的 API**（没用 `NavigationStack`、`Grid`、`.scrollIndicators`、`.onChange` 等）。以后加功能时要保持这一点，不然你 iOS 15.6.1 的手机上会直接跑不起来。