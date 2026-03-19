//
//  PasswordDotView.swift
//
//  Created by rain on 4/21/16.
//  Copyright © 2016 Recruit Lifestyle Co., Ltd. All rights reserved.
//

import UIKit

@IBDesignable
open class PasswordDotView: UIView {
    
    let stackView = UIStackView()
    var key_image: [UIImageView] = []
    
    //MARK: Property
    @IBInspectable
    open var inputDotCount = 0 {
        didSet {
            let format = Bundle(for: type(of: self)).localizedString(forKey: "PasswordDotViewAccessibilityValue", value: nil, table: nil)
            accessibilityValue = String(format: format, totalDotCount, inputDotCount)
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    open var totalDotCount = 6 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    open var strokeColor = UIColor.darkGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    open var fillColor = UIColor.red {
        didSet {
            setNeedsDisplay()
        }
    }

    fileprivate var radius: CGFloat = 6
    fileprivate let spacingRatio: CGFloat = 2
    fileprivate let borderWidthRatio: CGFloat = 1 / 5
    
    fileprivate(set) open var isFull = false
    
    //MARK: Draw
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        isFull = (inputDotCount == totalDotCount)
        let isOdd = (totalDotCount % 2) != 0
        let positions = getDotPositions(isOdd)
        //let borderWidth = radius * borderWidthRatio
        for (index, position) in positions.enumerated() {
            if index < inputDotCount {
                //let pathToFill = UIBezierPath(circleWithCenter: position, radius: (radius + borderWidth / 2), lineWidth: borderWidth)
                //pathToFill.fill()
                key_image[index].image = UIImage(named: "img_key_on")
            } else {
                //let pathToStroke = UIBezierPath(circleWithCenter: position, radius: radius, lineWidth: borderWidth)
                //pathToStroke.stroke()
                key_image[index].image = UIImage(named: "img_key_off")
            }
        }
    }
    
    //MARK: LifeCycle
    open override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        isAccessibilityElement = true
        accessibilityLabel = Bundle(for: type(of: self)).localizedString(forKey: "PasswordDotViewAccessibilityLabel", value: nil, table: nil)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        updateRadius()
        setNeedsDisplay()
        
        stackView.frame = self.bounds
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.contentMode = .scaleAspectFit
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.autoresizesSubviews = true
        
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        for i in 0..<totalDotCount {
            key_image.append(UIImageView.init(image: UIImage(named: "img_key_off")))
            key_image[i].translatesAutoresizingMaskIntoConstraints = false
            key_image[i].widthAnchor.constraint(equalToConstant: 65.0).isActive = true
            stackView.addArrangedSubview(key_image[i])
        }
    }
    
    //MARK: Animation
    fileprivate var shakeCount = 0
    fileprivate var direction = false
    open func shakeAnimationWithCompletion(_ completion: @escaping () -> ()) {
        let maxShakeCount = 5
        let centerX = bounds.midX
        let centerY = bounds.midY
        var duration = 0.10
        var moveX: CGFloat = 5
        
        if shakeCount == 0 || shakeCount == maxShakeCount {
            duration *= 0.5
        } else {
            moveX *= 2
        }
        shakeAnimation(withDuration: duration, animations: {
            if !self.direction {
                self.center = CGPoint(x: centerX + moveX, y: centerY)
            } else {
                self.center = CGPoint(x: centerX - moveX, y: centerY)
            }
        }) {
            if self.shakeCount >= maxShakeCount {
                self.shakeAnimation(withDuration: duration, animations: {
                    let realCenterX = self.superview!.bounds.midX
                    self.center = CGPoint(x: realCenterX, y: centerY)
                }) {
                    self.direction = false
                    self.shakeCount = 0
                    completion()
                }
            } else {
                self.shakeCount += 1
                self.direction = !self.direction
                self.shakeAnimationWithCompletion(completion)
            }
        }
    }
}

private extension PasswordDotView {
    //MARK: Animation
    func shakeAnimation(withDuration duration: TimeInterval, animations: @escaping () -> (), completion: @escaping () -> ()) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.01, initialSpringVelocity: 0.35, options: .curveEaseInOut, animations: {
            animations()
        }) { _ in
            completion()
        }
    }
    
    //MARK: Update Radius
    func updateRadius() {
        let width = bounds.width
        let height = bounds.height
        radius = height / 2 - height / 2 * borderWidthRatio
        let spacing = radius * spacingRatio
        let count = CGFloat(totalDotCount)
        let spaceCount = count - 1
        if (count * radius * 2 + spaceCount * spacing > width) {
            radius = floor((width / (count + spaceCount)) / 2)
        } else {
            radius = floor(height / 2);
        }
        radius = radius - radius * borderWidthRatio
    }

    //MARK: Dots Layout
    func getDotPositions(_ isOdd: Bool) -> [CGPoint] {
        let centerX = bounds.midX
        let centerY = bounds.midY
        let spacing = radius * spacingRatio
        let middleIndex = isOdd ? (totalDotCount + 1) / 2 : (totalDotCount) / 2
        let offSet = isOdd ? 0 : -(radius + spacing / 2)
        let positions: [CGPoint] = (1...totalDotCount).map { index in
            let i = CGFloat(middleIndex - index)
            let positionX = centerX - (radius * 2 + spacing) * i + offSet
            return CGPoint(x: positionX, y: centerY)
        }
        return positions
    }
}

internal extension UIBezierPath {
    convenience init(circleWithCenter center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        self.init(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2.0 * CGFloat(Double.pi), clockwise: false)
        self.lineWidth = lineWidth
    }
}
