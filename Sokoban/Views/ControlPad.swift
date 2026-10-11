import SwiftUI

/// 十字方向键 + 撤销 / 重开。
struct ControlPad: View {
    var onMove: (Direction) -> Void
    var onUndo: () -> Void
    var onReset: () -> Void
    var canUndo: Bool

    var body: some View {
        VStack(spacing: 8) {
            row { dirButton(.up) }

            row {
                dirButton(.left)
                actions
                dirButton(.right)
            }

            row { dirButton(.down) }
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        HStack(spacing: 8) { content() }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(action: onReset) {
                Label("重来", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.15))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)

            Button(action: onUndo) {
                Label("撤销", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(canUndo ? 0.22 : 0.08))
                    .foregroundColor(canUndo ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canUndo)
        }
        .frame(width: 104)
    }

    private func dirButton(_ dir: Direction) -> some View {
        Button { onMove(dir) } label: {
            Image(systemName: dir.arrow)
                .font(.system(size: 26, weight: .bold))
                .frame(width: 66, height: 52)
                .background(Color.accentColor.opacity(0.18))
                .foregroundColor(Color.accentColor)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}