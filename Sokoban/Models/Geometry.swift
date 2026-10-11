import Foundation

/// 网格坐标。`row` 向下增大，`col` 向右增大。
struct Pos: Hashable {
    var row: Int
    var col: Int
}

extension Pos {
    static func + (a: Pos, b: Pos) -> Pos {
        Pos(row: a.row + b.row, col: a.col + b.col)
    }
}

enum Direction {
    case up, down, left, right

    var delta: Pos {
        switch self {
        case .up: return Pos(row: -1, col: 0)
        case .down: return Pos(row: 1, col: 0)
        case .left: return Pos(row: 0, col: -1)
        case .right: return Pos(row: 0, col: 1)
        }
    }

    var arrow: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
}

/// 关卡文本里的字符。
///
/// 没列出来的字符（空格、制表符等）一律当**地板**处理，
/// 这样关卡可以随手对齐而不用纠结行尾空格。
enum Cell: Character {
    case wall = "#"
    case target = "."
    case box = "$"
    case boxOnTarget = "*"
    case player = "@"
    case playerOnTarget = "+"
}