#!/usr/bin/swift
// 生成 App 图标：推箱子的"箱子 + 目标点 + 小人"。
// 在 CI 上跑（macOS runner 自带 AppKit），图标不进 git。
// 画布保持满幅正方形，圆形裁切交给 iOS 自己处理。

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconDir = root.appendingPathComponent("Sokoban/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: iconDir, withIntermediateDirectories: true)

let size = 1024
let side = CGFloat(size)
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("无法创建图标画布")
}

let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
let rect = NSRect(x: 0, y: 0, width: side, height: side)

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> NSColor {
    NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
}

// 底色：偏冷的蓝紫渐变，跟橙色箱子形成对比，缩小后主体最跳。
let background = NSBezierPath(rect: rect)
NSGradient(colors: [
    rgb(0.13, 0.17, 0.34),
    rgb(0.20, 0.28, 0.52)
])!.draw(in: background, angle: -90)

// 网格纹理：淡到几乎看不见，只提供一点"棋盘"的暗示。
let grid = NSBezierPath()
grid.lineWidth = 10
for i in 1..<4 {
    let p = CGFloat(i) * side / 4
    grid.move(to: NSPoint(x: p, y: 0))
    grid.line(to: NSPoint(x: p, y: side))
    grid.move(to: NSPoint(x: 0, y: p))
    grid.line(to: NSPoint(x: side, y: p))
}
rgb(1, 1, 1, 0.05).setStroke()
grid.stroke()

// 目标点：箱子后面露出的一圈绿，暗示"推上去"。
let target = NSBezierPath(ovalIn: NSRect(x: 300, y: 300, width: 520, height: 520))
rgb(0.30, 0.85, 0.45, 0.55).setStroke()
target.lineWidth = 54
target.stroke()

// 箱子：主体，占画面中心，橙木色 + 白色交叉加固条。
let crate = NSRect(x: 250, y: 260, width: 520, height: 520)
let cratePath = NSBezierPath(roundedRect: crate, xRadius: 86, yRadius: 86)
NSGradient(colors: [
    rgb(0.98, 0.68, 0.22),
    rgb(0.87, 0.46, 0.13)
])!.draw(in: cratePath, angle: -90)

// 箱子的两条对角加固条
let brace = NSBezierPath()
brace.move(to: NSPoint(x: 300, y: 310))
brace.line(to: NSPoint(x: 720, y: 730))
brace.move(to: NSPoint(x: 724, y: 310))
brace.line(to: NSPoint(x: 304, y: 730))
brace.lineCapStyle = .round
brace.lineWidth = 62
rgb(1, 1, 1, 0.92).setStroke()
brace.stroke()

// 箱子描边，和背景拉开
rgb(0.35, 0.18, 0.05, 0.55).setStroke()
cratePath.lineWidth = 18
cratePath.stroke()

// 小人：右下方探出半个身子，暗示"推箱子的人"。
let skin = rgb(0.99, 0.87, 0.66)
let cloth = rgb(0.25, 0.55, 0.95)

// 头
let head = NSBezierPath(ovalIn: NSRect(x: 636, y: 396, width: 212, height: 212))
skin.setFill()
head.fill()
rgb(0.20, 0.13, 0.06, 0.45).setStroke()
head.lineWidth = 14
head.stroke()

// 眼睛（两个小点，控制住不至于太素）
let eye = NSBezierPath(ovalIn: NSRect(x: 690, y: 512, width: 34, height: 34))
rgb(0.18, 0.14, 0.10).setFill()
eye.fill()
let eye2 = NSBezierPath(ovalIn: NSRect(x: 766, y: 512, width: 34, height: 34))
rgb(0.18, 0.14, 0.10).setFill()
eye2.fill()

// 身体：半圆拱形，压在箱子右下角外侧
let body = NSBezierPath()
body.move(to: NSPoint(x: 646, y: 200))
body.line(to: NSPoint(x: 646, y: 330))
body.curve(to: NSPoint(x: 838, y: 330),
           controlPoint1: NSPoint(x: 646, y: 470),
           controlPoint2: NSPoint(x: 838, y: 470))
body.line(to: NSPoint(x: 838, y: 200))
body.close()
cloth.setFill()
body.fill()
rgb(0.12, 0.30, 0.62, 0.55).setStroke()
body.lineWidth = 14
body.stroke()

NSGraphicsContext.restoreGraphicsState()
let png = bitmap.representation(using: .png, properties: [:])!
try png.write(to: iconDir.appendingPathComponent("AppIcon.png"), options: .atomic)

let contents = """
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
try contents.write(to: iconDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("App 图标已生成：\(iconDir.path)")