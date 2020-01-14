import Metal
import UIKit

class MetalView: UIView {
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }

    var metalLayer: CAMetalLayer {
        return self.layer as! CAMetalLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentScaleFactor = UIScreen.main.scale
        self.metalLayer.drawableSize = self.bounds.size * self.contentScaleFactor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.contentScaleFactor = UIScreen.main.scale
        self.metalLayer.drawableSize = self.bounds.size * self.contentScaleFactor
    }
}

private extension CGSize {
    static func * (size: CGSize, scale: CGFloat) -> CGSize {
        CGSize(width: size.width * scale, height: size.height * scale)
    }
}
