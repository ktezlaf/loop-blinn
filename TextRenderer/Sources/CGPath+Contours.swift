import CoreGraphics

extension CGPath {
    /// A representation of the receiver as contours:  closed subpaths with implicit terminals.
    var contours: [[CGPoint]] {
        var finishedContours: [[CGPoint]] = []
        var currentContour: [CGPoint]? = nil

        self.applyWithBlock { pointer in
            let element = pointer.pointee
            if var currentContourTemp = currentContour {
                switch element.type {
                case .addLineToPoint:
                    currentContourTemp.append(element.points[0])
                    currentContour = currentContourTemp
                case .addQuadCurveToPoint:
                    currentContourTemp.append(element.points[1])
                    currentContour = currentContourTemp
                case .addCurveToPoint:
                    currentContourTemp.append(element.points[2])
                    currentContour = currentContourTemp
                case.closeSubpath:
                    finishedContours.append(currentContourTemp)
                    currentContour = nil
                case .moveToPoint:
                    finishedContours.append(currentContourTemp)
                    currentContour = [element.points[0]]
                @unknown default:
                    break
                }
            } else {
                switch element.type {
                case .addLineToPoint:
                    if let currentPoint = finishedContours.last?.first {
                        currentContour = [currentPoint, element.points[0]]
                    }
                case .addQuadCurveToPoint:
                    if let currentPoint = finishedContours.last?.first {
                        currentContour = [currentPoint, element.points[1]]
                    }
                case .addCurveToPoint:
                    if let currentPoint = finishedContours.last?.first {
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

        if let currentContour = currentContour {
            finishedContours.append(currentContour)
        }

        return finishedContours
    }
}
