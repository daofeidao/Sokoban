import Foundation

/// 一个关卡：名字 + 原始文本行。
struct Level {
    let name: String
    let rows: [String]

    var width: Int { rows.first?.count ?? 0 }
    var height: Int { rows.count }

    init(name: String, rows: [String]) {
        self.name = name
        // 关卡文本最容易被编辑器改动的地方就是行尾空格。
        // 统一补齐到最宽的一行，保证一定是矩形。
        self.rows = Level.rectangular(rows)
    }

    static func rectangular(_ rows: [String]) -> [String] {
        let width = rows.map(\.count).max() ?? 0
        guard width > 0 else { return rows }
        return rows.map { row in
            row.count >= width ? row : row + String(repeating: " ", count: width - row.count)
        }
    }
}

enum LevelError: Error, CustomStringConvertible {
    case empty(String)
    case noPlayer(String)
    case boxTargetMismatch(String, boxes: Int, targets: Int)

    var description: String {
        switch self {
        case .empty(let name):
            return "关卡「\(name)」是空的"
        case .noPlayer(let name):
            return "关卡「\(name)」里没有玩家（@）"
        case .boxTargetMismatch(let name, let b, let t):
            return "关卡「\(name)」有 \(b) 个箱子但 \(t) 个目标点，解不开"
        }
    }
}