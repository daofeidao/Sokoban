import UIKit

/// 触感反馈。
///
/// 推箱子这类"每一步都要给反馈"的操作，震动比动画更能立住手感。
/// 轻震＝走路，中震＝推动箱子，通知＝过关。
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func push() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}