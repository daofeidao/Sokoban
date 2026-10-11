import SwiftUI

/// 棋盘。用 `Canvas` 画，格子数不大，一次画完比堆几百个 View 划算。
struct BoardView: View {
    @ObservedObject var game: GameState

    var body: some View {
        GeometryReader { geo in
            // 先算出能放下的格子尺寸，再按格子数反推棋盘大小并居中。
            // 不用 aspectRatio —— GeometryReader 套 aspectRatio 在不同尺寸下容易算歪。
            let cols = CGFloat(game.level.width)
            let rows = CGFloat(game.level.height)
            let cell = min(geo.size.width / max(cols, 1), geo.size.height / max(rows, 1))

            Canvas(opaque: false, rendersAsynchronously: false) { ctx, _ in
                for row in 0..<game.level.height {
                    for col in 0..<game.level.width {
                        let pos = Pos(row: row, col: col)
                        let rect = CGRect(
                            x: CGFloat(col) * cell,
                            y: CGFloat(row) * cell,
                            width: cell,
                            height: cell
                        )
                        draw(pos, in: rect, cell: cell, ctx: &ctx)
                    }
                }
            }
            .frame(width: cell * cols, height: cell * rows)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func draw(_ pos: Pos, in rect: CGRect, cell: CGFloat, ctx: inout GraphicsContext) {
        let inner = rect.insetBy(dx: cell * 0.05, dy: cell * 0.05)

        if game.isWall(pos) {
            ctx.fill(
                Path(roundedRect: inner, cornerRadius: cell * 0.14),
                with: .color(Color(red: 0.31, green: 0.35, blue: 0.43))
            )
            return
        }

        // 目标点画在箱子底下，压上去时还能看到边
        if game.isTarget(pos) {
            ctx.stroke(
                Path(ellipseIn: inner.insetBy(dx: cell * 0.28, dy: cell * 0.28)),
                with: .color(Color.green.opacity(0.9)),
                lineWidth: cell * 0.07
            )
        }

        if game.hasBox(pos) {
            let onTarget = game.isTarget(pos)
            ctx.fill(
                Path(roundedRect: inner, cornerRadius: cell * 0.18),
                with: .color(onTarget ? Color.green : Color.orange)
            )
            ctx.stroke(
                Path(inner.insetBy(dx: inner.width * 0.3, dy: inner.height * 0.3)),
                with: .color(Color.white.opacity(0.6)),
                lineWidth: cell * 0.06
            )
        }

        if pos == game.player {
            ctx.fill(
                Path(ellipseIn: inner.insetBy(dx: cell * 0.14, dy: cell * 0.14)),
                with: .color(Color.blue)
            )
        }
    }
}