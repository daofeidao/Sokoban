# MEMORY.md —— 推箱子项目工作记忆

> 硬规则（尤其是"绝不代执行破坏性命令"）在全局 `~/.config/opencode/AGENTS.md`；
> 项目细节（怎么构建、怎么加关卡）在 `README.md`。这里只记**下次不知道就会做错**的事。

最后更新：2026-10-12（项目建立）

---

## 一、这是什么

- **iPhone 推箱子益智游戏**，SwiftUI，无三方依赖
- 位置：`E:\文档\推箱子`
- 设备：**iPhone 13 Pro Max / iOS 15.6.1 / TrollStore**
- 竖屏，最低 iOS 15.0
- Bundle ID：`com.daofeidao.Sokoban`

**注意**：这跟 `E:\文档\默认项目`（TT 终端）是**两个完全无关的独立项目**，
不要把那边的构建习惯直接搬过来。

---

## 二、当前状态

- **仓库**：`https://github.com/daofeidao/Sokoban`（公开）
- **版本**：v0.2.0（12 关 + 图标 + 小人 + 震动 + 最优步数）
- 每次 push 触发 CI：校验关卡 → 生成图标 → xcodegen → xcodebuild → 打 IPA 发 Release
- IPA 命名 `Sokoban-v<版本>.B<构建号>.ipa`，交付后放进 `E:\下载`

已验证的构建产物信息：
- `MinimumOSVersion` = 15.0
- Bundle ID `com.daofeidao.Sokoban`
- 图标由 `scripts/generate-app-icon.swift` 在 CI 上用 AppKit 画，**不入 git**
  （`Sokoban/Assets.xcassets/` 已在 .gitignore 里）

### 关卡表（par = BFS 算出的最优步数）

| # | 名称 | 步数 |
|---|---|---|
| 1~7 | 第一步 / 推两步 / 两个箱子 / 绕一下 / 让开自己 / 窄道 / 对角 | 1 / 4 / 7 / 8 / 10 / 16 / 13 |
| 8 | 死角 | 13 |
| 9 | 三连 | 14 |
| 10 | 四连 | 16 |
| 11 | 长途 | 18 |
| 12 | 仓库 | 20 |

---

## 三、这个项目的技术选择（以及为什么）

| 选择 | 原因 |
|---|---|
| 关卡用**字符格式**（`#` `$` `.` `@`）嵌在 Swift 里 | Sokoban 通用格式，关卡可以直接从网上抄；放 Swift 文件而不是 Bundle 资源，少一类"资源找不到"的坑 |
| 棋盘用 `Canvas` 一次画完 | 不用堆几百个 View；`Canvas` 在 iOS 15 就有 |
| 逻辑全塞在 `GameState` | 加玩法只动一个文件，不用碰界面 |
| 不用游戏引擎 | CI 编译时间、包体、兼容性都得自己扛，纯 SwiftUI 够用 |
| 撤销栈**只在移动成功时压栈** | 避免"点了撤销没反应"的空转 |
| 解析关卡**不抛异常** | 关卡是编译期常量，异常路径只会变成运行时空屏，很难查 |

---

## 四、编码红线（违反了在手机上直接跑不起来）

1. **不准用 iOS 16+ 的 API**。已经刻意避开的：`NavigationStack`、`Grid`、
   `.scrollIndicators`、`.onChange`、`AnyLayout`、`sizeThatFits`。
   用之前先确认是 iOS 15 就有的。
2. **不准手改 `Sokoban.xcodeproj`**。工程由 `project.yml` 生成，CI 会重新生成。
3. **不准引入三方依赖**。要加新功能先想清楚能不能自己写。

---

## 五、待办

- [ ] 在 iPhone 13 Pro Max 上验收 v0.2.0（图标、小人、震动手感、8~12 关难度）
- [ ] 关卡还能往 25 步以上加，但**求解器在 PowerShell 里跑到 30 万状态就慢了**，
      再大的关需要换个更快的验证方式
- [ ] 想想要不要加：关卡进度存档（解锁到第几关）、最佳成绩记录、过关音效

---

## 五之二、加关卡的正确流程

```powershell
# 1) 在 Sokoban/Data/Levels.swift 里追加一条，par 先随便填
# 2) 跑校验，它会告诉你真实最优步数，也会指出 par 填错了
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_levels.ps1 -ShowWalkthrough
# 3) 把 par 改成它报出来的数字，再跑一遍确认全绿
# 4) 提交推送，CI 会再验一次才出包
```

校验器现在会同时检查三件事，**任何一项不过 CI 就红**：
关卡可解、状态空间没爆、`par` 和 BFS 结果一致。

超过 25 步会标 `LONG`（可解但多半不好玩），状态空间超限标 `SKIP`（没证明，不拦）。

---

## 六、这个仓库的推送方式（跟别的项目不一样）

`github.com` 主站在这台机器上**连不上**（`Failed to connect` / `Connection was reset`），
但 `api.github.com` 正常。所以 `git push` 一定失败，**必须走 REST API**：

| 步骤 | 做法 |
|---|---|
| 0 | `git init -b main` + `add` + `commit`（本地历史照常有） |
| 1 | **空仓库必须先用 Contents API 播种一次**：`PUT /repos/OWNER/REPO/contents/<任意文件名>` |
| 2 | 每个文件 `POST /git/blobs`，content 走 **base64**（绕开 PowerShell 编码坑） |
| 3 | `POST /git/trees`（不传 `base_tree`） |
| 4 | `POST /git/commits`，parents 指向播种 commit |
| 5 | **`PATCH /git/refs/heads/<branch>`** —— ref 已存在，POST 会 422 |

踩过的坑：

- **空仓库里不能直接建 blob**，会 409 `Git Repository is empty`。必须先播种。
- **播种时不要传 `branch` 字段**。空仓库里分支还不存在，传了直接 404。不传才会自动建 `main`。
- **ref 已存在要用 PATCH，POST 会 422** `Reference already exists`。
- 中文文件内容一律 base64 走 blob，**不要用 `Set-Content`**。
- 现成脚本：`C:\Users\lion\AppData\Local\Temp\opencode\push_api_tree.ps1`
  （临时目录会丢，重写时照着第四节「网络」那条来）
- 本地 git 不在 PATH，每次先设：
  `$env:PATH = "C:\Program Files\GitHub CLI;C:\Program Files\Git\bin;$env:PATH"`
- **注意**：本地 `git log` 和 GitHub 上的 commit sha **对不上**。REST API 建的是另一条历史链，
  本地 `origin/main` 还指着空仓库的起点。下次要同步得 `git fetch` + 处理分叉，或者干脆
  重新 `git init`。别被这个搞混。

---

## 七、已知的坑（项目自身）

### ⚠️ v0.1.0 的第 4 关是死关，已修

B1/B2 发出去的第 4 关 `#$#@ #` 那一行里，箱子的**左、上、下三面全是墙**，
人永远站不到箱子左边，所以**箱子一格都推不动**。玩家反馈"根本推不出来"。

**教训**：这一关当初标注"逐关验证过可解"，其实**一次都没运行过任何东西**，
全凭记忆手推，而且手推时把那一行读成了空格。**凭印象不算验证。**

现在有 `scripts/verify_levels.ps1`（BFS 求解器），并且**已经接进 CI**：
关卡不可解就直接构建失败，IPA 出不来。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify_levels.ps1 -ShowWalkthrough
```

它会输出每关的最短步数和完整走法，超过 25 步会标 `LONG`
（可解但多半不好玩）。**加完关卡必须跑一遍。**

### 其他

- **关卡必须箱子和目标点数量相等、且有 `@`**，否则会被跳过/判死。
  启动日志里会打印跳过原因。
- 行尾空格不用管，`Level` 会自动补齐成矩形。
- 含中文的 `.ps1` 脚本必须存 **UTF-8 BOM**，否则 PS 5.1 按 GBK 读会解析错中文路径。
  `verify_levels.ps1` 是纯 ASCII + `$PSScriptRoot` 推路径，所以不需要 BOM。