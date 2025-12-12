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
    var value: CGFloat = 0.5 {
        didSet {
            // ограничим [0,1] на всякий случай
            value = min(max(0, value), 1)
            updateLayers()
            sendActions(for: .valueChanged)
        }
    }
    
    var lineWidth: CGFloat = 24
    var startAngle: CGFloat = -.pi * 3/4
    var endAngle: CGFloat =  .pi * 3/4

    // MARK: - Layers
    private let brightGradient = CAGradientLayer()
    private let paleGradient = CAGradientLayer()
    
    private let brightMask = CAShapeLayer()
    private let paleMask = CAShapeLayer()
    
    private let needleLayer = CAShapeLayer()
    private let tickLayer = CAShapeLayer()

    // MARK: - Animation helpers
    private var displayLink: CADisplayLink?
    private var animStartValue: CGFloat = 0
    private var animTargetValue: CGFloat = 0
    private var animStartTime: CFTimeInterval = 0
    private var animDuration: CFTimeInterval = 0

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    deinit {
        stopAnimation()
    }
    
    // MARK: - Layer Setup
    private func setupLayers() {
        layer.addSublayer(paleGradient)
        paleGradient.mask = paleMask
        
        layer.addSublayer(brightGradient)
        brightGradient.mask = brightMask
        
        layer.addSublayer(tickLayer)
        layer.addSublayer(needleLayer)
        
        // Gradient colors
        brightGradient.colors = [
            UIColor.blue.cgColor,
            UIColor.green.cgColor
        ]
        paleGradient.colors = [
            UIColor.green.withAlphaComponent(0.3).cgColor,
            UIColor.red.withAlphaComponent(0.3).cgColor
        ]
        
        tickLayer.strokeColor = UIColor.lightGray.cgColor
        tickLayer.lineWidth = 2
        tickLayer.fillColor = UIColor.clear.cgColor
        needleLayer.strokeColor = UIColor.darkGray.cgColor
        needleLayer.lineWidth = 4
        needleLayer.lineCap = .round
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        brightGradient.frame = bounds
        paleGradient.frame = bounds
        
        drawTicks()
        updateLayers()
    }

    // MARK: - Drawing Layers
    private func updateLayers() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth/2
        
        let totalAngle = endAngle - startAngle
        let angle = startAngle + totalAngle * value
        
        // --- Paths for masks ---
        let brightPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: angle,
            clockwise: true
        )
        
        let palePath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: angle,
            endAngle: endAngle,
            clockwise: true
        )
        
        brightMask.path = brightPath.cgPath
        brightMask.lineWidth = lineWidth
        brightMask.strokeColor = UIColor.black.cgColor
        brightMask.fillColor = UIColor.clear.cgColor
        brightMask.lineCap = .round
        
        paleMask.path = palePath.cgPath
        paleMask.lineWidth = lineWidth
        paleMask.strokeColor = UIColor.black.cgColor
        paleMask.fillColor = UIColor.clear.cgColor
        paleMask.lineCap = .round
        
        // --- Needle ---
        let needlePath = UIBezierPath()
        let endPoint = CGPoint(
            x: center.x + cos(angle) * (radius + lineWidth/2),
            y: center.y + sin(angle) * (radius + lineWidth/2)
        )
        needlePath.move(to: center)
        needlePath.addLine(to: endPoint)
        needleLayer.path = needlePath.cgPath
    }


    // MARK: - Ticks
    private func drawTicks() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth/2
        
        let tickCount = 18
        let path = UIBezierPath()
        
        for i in 0..<tickCount {
            let t = CGFloat(i) / CGFloat(tickCount - 1)
            let angle = startAngle + (endAngle - startAngle) * t
            
            let p1 = CGPoint(x: center.x + cos(angle) * (radius - 6),
                y: center.y + sin(angle) * (radius - 6)
            )
            let p2 = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            path.move(to: p1)
            path.addLine(to: p2)
        }
        
        tickLayer.path = path.cgPath
        tickLayer.fillColor = UIColor.clear.cgColor
    }

    // MARK: - Touch handling
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        // При первом касании — анимируем иглу до места клика
        updateValue(touch, animated: true)
        return true
    }
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        // Во время перетаскивания — прерываем анимацию и двигаем сразу
        stopAnimation()
        updateValue(touch, animated: false)
        return true
    }
    
    // animated: true — запустить плавную интерполяцию value (и дуги) до целевого значения
    private func updateValue(_ touch: UITouch, animated: Bool) {
        let pt = touch.location(in: self)
        let c = CGPoint(x: bounds.midX, y: bounds.midY)
        let dx = pt.x - c.x
        let dy = pt.y - c.y
        
        var ang = atan2(dy, dx)
        
        // Нормализация под дугу: если угол меньше start, пробуем добавить 2π, чтобы попасть в интервал
        if ang < startAngle { ang += 2 * .pi }
        
        // Ограничим по рамкам дуги
        let clampedAngle = max(startAngle, min(endAngle, ang))
        let targetValue = (clampedAngle - startAngle) / (endAngle - startAngle)
        
        if animated {
            animateToValue(targetValue)
        } else {
            value = targetValue
        }
    }
    
    // MARK: - Animation (CADisplayLink interpolation)
    private func animateToValue(_ target: CGFloat) {
        stopAnimation()
        
        let current = value
        guard abs(current - target) > 0.0001 else { return } // ничего не делать, если уже на месте
        
        animStartValue = current
        animTargetValue = min(max(0, target), 1)
        animStartTime = CACurrentMediaTime()
        
        // Длительность пропорциональна расстоянию (можно подстроить)
        let distance = abs(Double(animTargetValue - animStartValue))
        animDuration = 0.25 + distance * 0.5 // от 0.25 до ~0.75s
        
        displayLink = CADisplayLink(target: self, selector: #selector(stepAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func stepAnimation() {
        let now = CACurrentMediaTime()
        let tRaw = (now - animStartTime) / animDuration
        if tRaw >= 1.0 {
            // завершили
            value = animTargetValue
            stopAnimation()
            return
        }
        let t = CGFloat(tRaw)
        let eased = easeOutCubic(t)
        let newValue = animStartValue + (animTargetValue - animStartValue) * eased
        // обновляем значение — это вызовет updateLayers()
        value = newValue
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        return 1 - pow(1 - t, 3)
    }
}
