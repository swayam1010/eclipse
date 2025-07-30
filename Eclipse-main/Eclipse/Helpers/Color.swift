import Foundation
import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat? = nil) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        if hexSanitized.count == 6 {
            var rgb: UInt64 = 0
            Scanner(string: hexSanitized).scanHexInt64(&rgb)
            let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
            let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
            let blue = CGFloat(rgb & 0xFF) / 255.0
            let finalAlpha = alpha ?? 1.0
            self.init(red: red, green: green, blue: blue, alpha: finalAlpha)
        } else {
            self.init(white: 0.0, alpha: 1.0)
        }
    }
}

class RadialGradientLayer: CALayer {
    var center: CGPoint
    var radius: CGFloat
    var colors: [CGColor]

    init(center: CGPoint, radius: CGFloat, colors: [CGColor]) {
        self.center = center
        self.radius = radius
        self.colors = colors
        super.init()
        needsDisplayOnBoundsChange = true
    }

    override init(layer: Any) {
        guard let layer = layer as? RadialGradientLayer else {
            fatalError("Layer is not a RadialGradientLayer")
        }
        self.center = layer.center
        self.radius = layer.radius
        self.colors = layer.colors
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(in ctx: CGContext) {
        ctx.saveGState()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]

        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
            return
        }

        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: .drawsAfterEndLocation)

        ctx.restoreGState()
    }
}


