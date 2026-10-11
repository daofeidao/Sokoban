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
            drawPlayer(in: rect, cell: cell, ctx: &ctx)
        }
    }

    /// 小人：一个胶囊形身体 + 一个圆脑袋。
    /// 用胶囊而不是圆弧拼接，缩到 30pt 也不会画歪。
    private func drawPlayer(in rect: CGRect, cell: CGFloat, ctx: inout GraphicsContext) {
        let w = rect.width
        let h = rect.height

        let body = CGRect(
            x: rect.minX + w * 0.26,
            y: rect.minY + h * 0.46,
            width: w * 0.48,
            height: h * 0.44
        )
        let shirt = Color(red: 0.20, green: 0.50, blue: 0.95)
        ctx.fill(
            Path(roundedRect: body, cornerRadius: body.width / 2),
            with: .color(shirt)
        )
        ctx.stroke(
            Path(roundedRect: body, cornerRadius: body.width / 2),
            with: .color(Color.white.opacity(0.85)),
            lineWidth: max(cell * 0.035, 1)
        )

        let headSize = w * 0.42
        let head = CGRect(
            x: rect.midX - headSize / 2,
            y: rect.minY + h * 0.06,
            width: headSize,
            height: headSize
        )
        ctx.fill(
            Path(ellipseIn: head),
            with: .color(Color(red: 0.99, green: 0.85, blue: 0.66))
        )
        ctx.stroke(
            Path(ellipseIn: head),
            with: .color(Color(red: 0.45, green: 0.30, blue: 0.18, opacity: 0.9)),
            lineWidth: max(cell * 0.035, 1)
        )

        // 眼睛：两个小点，缩到很小也还看得出朝向
        let eye = head.width * 0.16
        let eyeY = head.midY - eye * 0.5
        let offset = head.width * 0.17
        for sign in [-1.0, 1.0] {
            let x = head.midX + CGFloat(sign) * offset - eye / 2
            ctx.fill(
                Path(ellipseIn: CGRect(x: x, y: eyeY, width: eye, height: eye)),
                with: .color(Color(red: 0.16, green: 0.12, blue: 0.08))
            )
        }
    }
}