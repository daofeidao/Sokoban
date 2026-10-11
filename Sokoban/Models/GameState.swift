import Foundation
import SwiftUI

/// 推箱子的全部游戏状态。
///
/// 状态是这个类型里**唯一**的可变真相；视图只读它、只调 `move` / `undo` / `reset` / `load`。
final class GameState: ObservableObject {

    /// 一关解析之后的静态布局。
    struct Layout {
        var walls: Set<Pos> = []
        var boxes: Set<Pos> = []
        var targets: Set<Pos> = []
        var player: Pos = Pos(row: 0, col: 0)

        static let empty = Layout()
    }

    // MARK: - 关卡静态信息

    @Published private(set) var level: Level
    private var walls: Set<Pos>

    // MARK: - 对局状态

    @Published private(set) var player: Pos
    @Published private(set) var boxes: Set<Pos>
    @Published private(set) var targets: Set<Pos>
    @Published private(set) var moveCount = 0
    @Published private(set) var pushCount = 0
    @Published private(set) var solved = false

    /// 撤销栈。只在**真正移动成功**时才压栈，
    /// 所以「撤销」永远不会出现"点了没反应"的空转。
    private var history: [Snapshot] = []

    private struct Snapshot {
        var player: Pos
        var boxes: Set<Pos>
        var pushCount: Int
    }

    // MARK: - 初始化

    /// 解析不出来就退化成空布局，**不崩**。
    ///
    /// 关卡是编译期写死的常量，正常路径下 `Levels.all` 已经校验过一遍，
    /// 走不到这个兜底分支。
    init(level: Level) {
        self.level = level
        let layout = GameState.layout(of: level) ?? .empty
        self.walls = layout.walls
        self.player = layout.player
        self.boxes = layout.boxes
        self.targets = layout.targets
    }

    /// 把关卡文本拆成墙 / 箱子 / 目标点 / 玩家位置。失败返回 `nil`。
    static func layout(of level: Level) -> Layout? {
        guard level.width > 0, level.height > 0 else { return nil }

        var layout = Layout()
        var foundPlayer = false

        for (row, line) in level.rows.enumerated() {
            for (col, ch) in line.enumerated() {
                guard let cell = Cell(rawValue: ch) else { continue }
                let pos = Pos(row: row, col: col)
                switch cell {
                case .wall:
                    layout.walls.insert(pos)
                case .target:
                    layout.targets.insert(pos)
                case .box:
                    layout.boxes.insert(pos)
                case .boxOnTarget:
                    layout.boxes.insert(pos)
                    layout.targets.insert(pos)
                case .player:
                    layout.player = pos
                    foundPlayer = true
                case .playerOnTarget:
                    layout.player = pos
                    layout.targets.insert(pos)
                    foundPlayer = true
                }
            }
        }

        guard foundPlayer else { return nil }
        // 箱子和目标点数量不等的话不可能有解，直接判废
        guard layout.boxes.count == layout.targets.count else { return nil }

        return layout
    }

    /// 校验用：关卡有问题时返回一句人话，没问题返回 `nil`。
    static func problem(in level: Level) -> String? {
        guard level.width > 0, level.height > 0 else {
            return LevelError.empty(level.name).description
        }
        guard layout(of: level) != nil else {
            // 区分开是"没有玩家"还是"箱子目标数不等"
            let hasPlayer = level.rows.contains { $0.contains(Cell.player.rawValue) || $0.contains(Cell.playerOnTarget.rawValue) }
            if hasPlayer {
                let counts = LevelCounts(of: level)
                return LevelError.boxTargetMismatch(level.name, boxes: counts.boxes, targets: counts.targets).description
            }
            return LevelError.noPlayer(level.name).description
        }
        return nil
    }

    // MARK: - 换关 / 重开

    /// 换关。解析不了就**保持原关不变**，返回 `false`。
    @discardableResult
    func load(_ newLevel: Level) -> Bool {
        guard let layout = GameState.layout(of: newLevel) else { return false }
        level = newLevel
        walls = layout.walls
        player = layout.player
        boxes = layout.boxes
        targets = layout.targets
        resetCounters()
        return true
    }

    /// 重开当前关。
    func reset() {
        guard let layout = GameState.layout(of: level) else { return }
        player = layout.player
        boxes = layout.boxes
        resetCounters()
    }

    private func resetCounters() {
        moveCount = 0
        pushCount = 0
        solved = false
        history.removeAll()
    }

    // MARK: - 查询

    var canUndo: Bool { !history.isEmpty }
    func isWall(_ pos: Pos) -> Bool { walls.contains(pos) }
    func isTarget(_ pos: Pos) -> Bool { targets.contains(pos) }
    func hasBox(_ pos: Pos) -> Bool { boxes.contains(pos) }

    // MARK: - 操作

    /// 走一步。被墙或被自己顶住的箱子挡住时不动，也不计步。
    func move(_ dir: Direction) {
        guard !solved else { return }

        let next = player + dir.delta
        guard !walls.contains(next) else { return }

        var newBoxes = boxes
        var didPush = false

        if boxes.contains(next) {
            // 要推箱子，先看箱子后面那一格能不能站人 / 有没有别的箱子
            let beyond = next + dir.delta
            guard !walls.contains(beyond), !boxes.contains(beyond) else { return }
            newBoxes.remove(next)
            newBoxes.insert(beyond)
            didPush = true
        }

        // 走到这一步才动状态，失败路径上不留痕迹
        history.append(Snapshot(player: player, boxes: boxes, pushCount: pushCount))
        player = next
        boxes = newBoxes
        moveCount += 1
        if didPush { pushCount += 1 }
        if boxes == targets { solved = true }
    }

    /// 撤销一步。
    func undo() {
        guard let snap = history.popLast() else { return }
        player = snap.player
        boxes = snap.boxes
        pushCount = snap.pushCount
        moveCount = max(0, moveCount - 1)
        solved = false
    }
}

/// 统计关卡里的箱子和目标点个数，给校验错误信息用。
private struct LevelCounts {
    let boxes: Int
    let targets: Int

    init(of level: Level) {
        var b = 0, t = 0
        for line in level.rows {
            for ch in line {
                guard let cell = Cell(rawValue: ch) else { continue }
                switch cell {
                case .box:
                    b += 1
                case .boxOnTarget:
                    b += 1
                    t += 1
                case .target:
                    t += 1
                default:
                    break
                }
            }
        }
        boxes = b
        targets = t
    }
}