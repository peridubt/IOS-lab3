//
//  CircularSlider.swift
//  ulyanov-lab3
//
//  Created by xcode on 12.12.2025.
//  Copyright © 2025 VSU. All rights reserved.
//
import UIKit

class CircularSlider: UIControl {
    
    // MARK: - Public properties
    var startAngle: CGFloat = -.pi * 3/4        // левая граница дуги
    var endAngle: CGFloat = .pi * 3/4           // правая граница дуги
    var lineWidth: CGFloat = 25
    
    var tickCount: Int = 20                     // количество делений
    var tickLength: CGFloat = 8
    var tickColor: UIColor = UIColor.gray.withAlphaComponent(0.6)
    
    /// Текущее значение 0...1
    var value: CGFloat = 0.4 {
        didSet {
            setNeedsDisplay()
            sendActions(for: .valueChanged)
        }
    }
    
    // MARK: - Touch handling
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateValue(with: touch)
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateValue(with: touch)
        return true
    }
    
    private func updateValue(with touch: UITouch) {
        let point = touch.location(in: self)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = point.x - center.x
        let dy = point.y - center.y
        
        var angle = atan2(dy, dx)
        
        // Нормируем угол в диапазон startAngle...endAngle
        if angle < startAngle - .pi { angle += 2 * .pi }
        if angle > endAngle + .pi { angle -= 2 * .pi }

        let totalAngle = endAngle - startAngle
        let clamped = max(startAngle, min(endAngle, angle))
        
        value = (clamped - startAngle) / totalAngle
    }

    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        let radius = min(bounds.width, bounds.height)/2 - lineWidth
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let totalAngle = endAngle - startAngle
        let currentAngle = startAngle + value * totalAngle
        
        // ---- Background arc (after needle) — pale
        drawArc(ctx: ctx,
                center: center,
                radius: radius,
                from: currentAngle,
                to: endAngle,
                colors: [UIColor.systemGreen.withAlphaComponent(0.3),
                         UIColor.systemRed.withAlphaComponent(0.3)])
        
        // ---- Foreground arc (before needle) — more vivid
        drawArc(ctx: ctx,
                center: center,
                radius: radius,
                from: startAngle,
                to: currentAngle,
                colors: [UIColor.systemBlue,
                         UIColor.systemGreen])
        
        drawTicks(ctx: ctx, center: center, radius: radius + lineWidth/2)
        drawNeedle(ctx: ctx, center: center, radius: radius + lineWidth/2)
    }
    
    private func drawArc(ctx: CGContext,
                         center: CGPoint,
                         radius: CGFloat,
                         from: CGFloat,
                         to: CGFloat,
                         colors: [UIColor]) {
        
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: from,
                                endAngle: to,
                                clockwise: true)
        
        ctx.saveGState()
        ctx.addPath(path.cgPath)
        ctx.setLineWidth(lineWidth)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        
        // gradient
        let cgColors = colors.map { $0.cgColor } as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: cgColors,
                                  locations: nil)!
        
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: 0),
                               end: CGPoint(x: bounds.width, y: bounds.height),
                               options: [])
        
        ctx.restoreGState()
    }
    
    private func drawTicks(ctx: CGContext, center: CGPoint, radius: CGFloat) {
        let angleStep = (endAngle - startAngle) / CGFloat(tickCount - 1)
        
        ctx.saveGState()
        ctx.setStrokeColor(tickColor.cgColor)
        ctx.setLineWidth(2)
        
        for i in 0..<tickCount {
            let angle = startAngle + angleStep * CGFloat(i)
            let start = CGPoint(x: center.x + cos(angle) * (radius - tickLength),
                                y: center.y + sin(angle) * (radius - tickLength))
            let end = CGPoint(x: center.x + cos(angle) * (radius),
                              y: center.y + sin(angle) * (radius))
            ctx.move(to: start)
            ctx.addLine(to: end)
        }
        
        ctx.strokePath()
        ctx.restoreGState()
    }
    
    private func drawNeedle(ctx: CGContext, center: CGPoint, radius: CGFloat) {
        let totalAngle = endAngle - startAngle
        let angle = startAngle + value * totalAngle
        
        let endPoint = CGPoint(x: center.x + cos(angle) * radius,
                               y: center.y + sin(angle) * radius)
        
        ctx.saveGState()
        ctx.setLineWidth(4)
        ctx.setStrokeColor(UIColor.darkGray.cgColor)
        ctx.move(to: center)
        ctx.addLine(to: endPoint)
        ctx.strokePath()
        ctx.restoreGState()
    }
}
