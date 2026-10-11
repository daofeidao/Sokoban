import Foundation

/// 关卡表。
///
/// 格式就是 Sokoban 的通用字符表：
///
/// | 字符 | 含义 |
/// |---|---|
/// | `#` | 墙 |
/// | (空格) | 地板 |
/// | `.` | 目标点 |
/// | `$` | 箱子 |
/// | `*` | 箱子压在目标点上 |
/// | `@` | 玩家 |
/// | `+` | 玩家站在目标点上 |
///
/// 行尾空格不用管，`Level` 会自动补齐成矩形。
enum Levels {

    /// 关卡万一全被校验判废时的兜底，保证 App 一定能起来。
    static let fallback = Level(name: "占位关", rows: [
        "#######",
        "#     #",
        "# @$. #",
        "#     #",
        "#######",
    ])

    static let all: [Level] = {
        let usable = Levels.raw
            .map { Level(name: $0.name, rows: $0.rows) }
            .filter { level in
                // 关卡是编译期写死的常量，过不了校验的直接剔掉，
                // 免得运行时开天窗。剔掉会打日志。
                if let problem = GameState.problem(in: level) {
                    print("[Levels] 跳过无效关卡「\(level.name)」：\(problem)")
                    return false
                }
                return true
            }
        return usable.isEmpty ? [Levels.fallback] : usable
    }()

    private static let raw: [(name: String, rows: [String])] = [

        (name: "1 · 第一步", rows: [
            "#######",
            "#     #",
            "#  @  #",
            "#  $  #",
            "#  .  #",
            "#     #",
            "#######",
        ]),

        (name: "2 · 推两步", rows: [
            "########",
            "#      #",
            "#  @   #",
            "#  $ . #",
            "#      #",
            "########",
        ]),

        (name: "3 · 两个箱子", rows: [
            "########",
            "#      #",
            "# @$ . #",
            "#  $ . #",
            "#      #",
            "########",
        ]),

        // 直着推会被墙挡住 —— 必须先往下推，再绕到左边横推。
        (name: "4 · 绕一下", rows: [
            "########",
            "#      #",
            "# $#@  #",
            "#  #   #",
            "#  .   #",
            "#      #",
            "########",
        ]),

        (name: "5 · 让开自己", rows: [
            "########",
            "#      #",
            "# .$$  #",
            "# .  @ #",
            "#      #",
            "########",
        ]),

        (name: "6 · 窄道", rows: [
            "######",
            "#    #",
            "# #@ #",
            "# $* #",
            "# .* #",
            "#    #",
            "######",
        ]),

        (name: "7 · 对角", rows: [
            "########",
            "#      #",
            "#  .   #",
            "# $$@  #",
            "#  .   #",
            "#      #",
            "########",
        ]),
    ]
}