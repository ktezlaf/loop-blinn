import CoreGraphics

extension CGPath {
    /// A representation of the receiver's curves as cubic Bézier curves.
    var cubicBézierCurves: [CubicBézierCurve] {
        var curves: [CubicBézierCurve] = []
        var previousContour: [CGPoint]? = nil
        var currentContour: [CGPoint]? = nil

        self.applyWithBlock { pointer in
            let element = pointer.pointee
            if var currentContourTemp = currentContour {
                switch element.type {
                case .addLineToPoint:
                    currentContourTemp.append(element.points[0])
                    currentContour = currentContourTemp
                case .addQuadCurveToPoint:
                    if let currentPoint = currentContourTemp.last {
                        curves.append(CubicBézierCurve(origin: currentPoint, quadratic: element.points))
                    }

                    currentContourTemp.append(element.points[1])
                    currentContour = currentContourTemp
                case .addCurveToPoint:
                    if let currentPoint = currentContourTemp.last {
                        curves.append(CubicBézierCurve(origin: currentPoint, cubic: element.points))
                    }

                    currentContourTemp.append(element.points[2])
                    currentContour = currentContourTemp
                case.closeSubpath:
                    previousContour = currentContourTemp
                    currentContour = nil
                case .moveToPoint:
                    previousContour = currentContourTemp
                    currentContour = [element.points[0]]
                @unknown default:
                    break
                }
            } else {
                switch element.type {
                case .addLineToPoint:
                    if let currentPoint = previousContour?.first {
                        currentContour = [currentPoint, element.points[0]]
                    }
                case .addQuadCurveToPoint:
                    if let currentPoint = previousContour?.first {
                        curves.append(CubicBézierCurve(origin: currentPoint, quadratic: element.points))
                        currentContour = [currentPoint, element.points[1]]
                    }
                case .addCurveToPoint:
                    if let currentPoint = previousContour?.first {
                        curves.append(CubicBézierCurve(origin: currentPoint, cubic: element.points))
                        currentContour = [currentPoint, element.points[2]]
                    }
                case.closeSubpath:
                    break
                case .moveToPoint:
                    currentContour = [element.points[0]]
                @unknown default:
                    break
                }
            }
        }

        return curves
    }
}

private extension SIMD2 where Scalar == Double {
    init(_ point: CGPoint) {
        self.init(Scalar(point.x), Scalar(point.y))
    }
}

private extension CubicBézierCurve {
    init(origin: CGPoint, quadratic points: UnsafePointer<CGPoint>) {
        self.init(origin: SIMD2(origin), control: SIMD2(points[0]), destination: SIMD2(points[1]))
    }

    init(origin: CGPoint, cubic points: UnsafePointer<CGPoint>) {
        self.init(origin: SIMD2(origin), control0: SIMD2(points[0]), control1: SIMD2(points[1]), destination: SIMD2(points[2]))
    }
}
