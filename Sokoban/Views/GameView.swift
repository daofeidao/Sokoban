import SwiftUI

struct GameView: View {
    @StateObject private var game: GameState
    @State private var index: Int

    private let levels: [Level]

    init() {
        // `Levels.all` 已过滤掉无效关卡，这里拿到的必然能解析。
        // 构造不抛异常，解析不了会退化成空布局而不是崩。
        _index = State(initialValue: 0)
        _game = StateObject(wrappedValue: GameState(level: Levels.all.first ?? Levels.fallback))
        levels = Levels.all.isEmpty ? [Levels.fallback] : Levels.all
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            levelStrip
            BoardView(game: game)
                .padding(.horizontal, 16)
                .gesture(swipe)
                // 过关提示盖在棋盘上，不挤动布局
                .overlay(alignment: .bottom) { solvedOverlay }
            Spacer(minLength: 0)
            ControlPad(
                onMove: { game.move($0) },
                onUndo: { game.undo() },
                onReset: { game.reset() },
                canUndo: game.canUndo
            )
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - 顶栏

    private var header: some View {
        VStack(spacing: 4) {
            Text(game.level.name)
                .font(.system(size: 20, weight: .bold))
            HStack(spacing: 18) {
                counter("步数", game.moveCount)
                counter("推动", game.pushCount)
            }
            .font(.system(size: 13))
            .foregroundColor(.secondary)
        }
    }

    private func counter(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
            Text("\(value)").foregroundColor(.primary).fontWeight(.semibold)
        }
    }

    // MARK: - 选关

    private var levelStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(levels.indices, id: \.self) { i in
                    Button { select(i) } label: {
                        Text("\(i + 1)")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .background(i == index
                                        ? Color.accentColor
                                        : Color.secondary.opacity(0.15))
                            .foregroundColor(i == index ? .white : .primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 过关

    private var solvedOverlay: some View {
        Group {
            if game.solved {
                VStack(spacing: 8) {
                    Text("过关！一共推了 \(game.pushCount) 次")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    if index + 1 < levels.count {
                        Button("下一关") { select(index + 1) }
                            .font(.system(size: 15, weight: .semibold))
                            .buttonStyle(.borderedProminent)
                    } else {
                        Text("全部通关")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.72))
                .cornerRadius(14)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - 手势 / 动作

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    game.move(dx > 0 ? .right : .left)
                } else {
                    game.move(dy > 0 ? .down : .up)
                }
            }
    }

    private func select(_ i: Int) {
        guard levels.indices.contains(i) else { return }
        guard game.load(levels[i]) else { return }
        index = i
    }
}