import CoreGraphics

extension CGRect {
    /// An affine transform that inverts the receiver to the unit square centered at the coordinate system origin.
    var inverseTransform: CGAffineTransform {
        CGAffineTransform(translationX: -0.5, y: -0.5)
            .scaledBy(x: 1.0 / self.size.width, y: 1.0 / self.size.height)
            .translatedBy(x: -self.origin.x, y: -self.origin.y)
    }
}
