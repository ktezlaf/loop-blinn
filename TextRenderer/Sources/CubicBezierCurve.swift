import simd

/// A cubic Bézier curve.
struct CubicBézierCurve {
    private let origin: SIMD2<Double>
    private let control0: SIMD2<Double>
    private let control1: SIMD2<Double>
    private let destination: SIMD2<Double>

    /// Creates a cubic Bézier curve.
    ///
    /// - parameter origin:      The initial point.
    /// - parameter control0:    The first control point, defining the initial slope.
    /// - parameter control1:    The second control point, defining the final slope.
    /// - parameter destination: The final point.
    init(origin: SIMD2<Double>, control0: SIMD2<Double>, control1: SIMD2<Double>, destination: SIMD2<Double>) {
        self.origin = origin
        self.control0 = control0
        self.control1 = control1
        self.destination = destination
    }

    /// Creates a cubic Bézier curve from quadratic Bézier curve origin, control, and destination points.
    ///
    /// - parameter origin:      The quadratic Bézier curve initial point.
    /// - parameter control:     The quadratic Bézier curve control point, defining both initial and final slopes.
    /// - parameter destination: The quadratic Bézier curve final point.
    init(origin: SIMD2<Double>, control: SIMD2<Double>, destination: SIMD2<Double>) {
        self.origin = origin
        self.destination = destination

        let originContribution = origin / 3
        let controlContribution = control * 2/3
        let destinationContribution = destination / 3

        self.control0 = originContribution + controlContribution
        self.control1 = destinationContribution + controlContribution
    }

    /// `VertexAttributes` to render the receiver with the Loop-Blinn algorithm.
    var vertexAttributes: [VertexAttributes]? {
        guard let textureCoordinates = self.textureCoordinates else {
            return nil
        }

        let origin = VertexAttributes(position: SIMD2(self.origin), textureCoordinates: SIMD3(textureCoordinates.origin))
        let control1 = VertexAttributes(position: SIMD2(self.control1), textureCoordinates: SIMD3(textureCoordinates.control1))
        let destination = VertexAttributes(position: SIMD2(self.destination), textureCoordinates: SIMD3(textureCoordinates.destination))

        return [origin, destination, control1]
    }

    // MARK: Private

    private var textureCoordinates: TextureCoordinates? {
        let b₀ = SIMD3(self.origin, 1)
        let b₁ = SIMD3(self.control0, 1)
        let b₂ = SIMD3(self.control1, 1)
        let b₃ = SIMD3(self.destination, 1)

        let cross₁ = cross(b₃, b₂)
        let cross₂ = cross(b₀, b₃)
        let cross₃ = cross(b₁, b₀)

        let a₁ = dot(b₀, cross₁)
        let a₂ = dot(b₁, cross₂)
        let a₃ = dot(b₂, cross₃)

        let d₁ = a₁ - 2*a₂ + 3*a₃
        let d₂ = -a₂ + 3*a₃
        let d₃ = 3*a₃

        let D = 3*d₂*d₂ - 4*d₁*d₃
        let discriminant = d₁*d₁*D

        let isZero: (Double) -> Bool = { abs($0) <= .ulpOfOne }

        let curveType: CurveType
        switch (discriminant, isZero(d₁), isZero(d₂), isZero(d₃), D) {
        case (_, true, true, true, _):
            curveType = .lineOrPoint
        case (_, true, true, _, _):
            curveType = .quadratic(d₃: d₃)
        case (0, false, _, _, _):
            curveType = .cusp(d₂: d₂, d₃: d₃)
        case let (0, _, _, _, D) where D < 0:
            curveType = .loop(d₁: d₁, d₂: d₂, d₃: d₃)
        case (0, _, _, _, _):
            curveType = .serpentine(d₁: d₁, d₂: d₂, d₃: d₃)
        case let (discriminant, _, _, _, _) where discriminant > 0:
            curveType = .serpentine(d₁: d₁, d₂: d₂, d₃: d₃)
        default:
            curveType = .loop(d₁: d₁, d₂: d₂, d₃: d₃)
        }

        return curveType.textureCoordinates
    }
}

private struct TextureCoordinates {
    let origin: SIMD3<Double>
    let control0: SIMD3<Double>
    let control1: SIMD3<Double>
    let destination: SIMD3<Double>

    init(_ matrix: double3x4) {
        let rows = matrix.transpose

        self.origin = rows[0]
        self.control0 = rows[1]
        self.control1 = rows[2]
        self.destination = rows[3]
    }
}

private enum CurveType {
    case serpentine(d₁: Double, d₂: Double, d₃: Double)
    case loop(d₁: Double, d₂: Double, d₃: Double)
    case cusp(d₂: Double, d₃: Double)
    case quadratic(d₃: Double)
    case lineOrPoint

    var textureCoordinates: TextureCoordinates? {
        let O = double3x3(rows: [
            [-1, 0, 0],
            [0, -1, 0],
            [0, 0, +1],
        ])

        switch self {
        case let .serpentine(d₁: d₁, d₂: d₂, d₃: d₃):
            // serpentine or cusp with inflection at infinity
            let ls = 3*d₂ - sqrt(9*d₂*d₂ - 12*d₁*d₃)
            let lt = 6*d₁
            let ms = 3*d₂ + sqrt(9*d₂*d₂ - 12*d₁*d₃)
            let mt = 6*d₁

            var M = double3x4()
            M[0][0] = ls*ms
            M[0][1] = (3*ls*ms - ls*mt - lt*ms)/3
            M[0][2] = (lt*(mt - 2*ms) + ls*(3*ms - 2*mt))/3
            M[0][3] = (lt - ls)*(mt - ms)

            M[1][0] = ls*ls*ls
            M[1][1] = ls*ls*(ls - lt)
            M[1][2] = (lt - ls)*(lt - ls)*ls
            M[1][3] = -(lt - ls)*(lt - ls)*(lt - ls)

            M[2][0] = ms*ms*ms
            M[2][1] = ms*ms*(ms - mt)
            M[2][2] = (mt - ms)*(mt - ms)*ms
            M[2][3] = -(mt - ms)*(mt - ms)*(mt - ms)

            if d₁ < 0 {
                M *= O
            }

            return TextureCoordinates(M)
        case let .loop(d₁: d₁, d₂: d₂, d₃: d₃):
            // loop
            let ls = d₂ - sqrt(4*d₁*d₃ - 3*d₂*d₂)
            let lt = 2*d₁
            let ms = d₂ + sqrt(4*d₁*d₃ - 3*d₂*d₂)
            let mt = 2*d₁

            var M = double3x4()
            M[0][0] = ls*ms
            M[0][1] = (-ls*mt - lt*ms + 3*ls*ms)/3
            M[0][2] = (lt*(mt - 2*ms) + ls*(3*ms - 2*mt))/3
            M[0][3] = (lt - ls)*(mt - ms)

            M[1][0] = ls*ls*ms
            M[1][1] = -ls*(ls*(mt - 3*ms) + 2*lt*ms)/3
            M[1][2] = (lt - ls)*(ls*(2*mt - 3*ms) + lt*ms)/3
            M[1][3] = -((lt - ls)*(lt - ls)) * (mt - ms)

            M[2][0] = ls*ms*ms
            M[2][1] = -ms*(ls*(2*mt - 3*ms) + lt*ms)/3
            M[2][2] = (mt - ms)*(ls*(mt - 3*ms) + 2*lt*ms)/3
            M[2][3] = -(lt - ls)*(mt - ms)*(mt - ms)

            if d₁ < 0 {
                M *= O
            }

            return TextureCoordinates(M)
        case let .cusp(d₂: d₂, d₃: d₃):
            // cusp with cusp at infinity
            let ls = d₃
            let lt = 3*d₂

            var M = double3x4()
            M[0][0] = ls
            M[0][1] = ls - lt/3
            M[0][2] = ls - 2*lt/3
            M[0][3] = ls - lt

            M[1][0] = ls*ls*ls
            M[1][1] = ls*ls*(ls - lt)
            M[1][2] = (ls - lt)*(ls - lt)*ls
            M[1][3] = (ls - lt)*(ls - lt)*(ls - lt)

            M[2][0] = 1
            M[2][1] = 1
            M[2][2] = 1
            M[2][3] = 1

            return TextureCoordinates(M)
        case let .quadratic(d₃: d₃):
            // quadratic
            var M = double3x4()
            M[0][0] = 0
            M[0][1] = 1.0/3.0
            M[0][2] = 2.0/3.0
            M[0][3] = 1

            M[1][0] = 0
            M[1][1] = 0
            M[1][2] = 1.0/3.0
            M[1][3] = 1

            M[2][0] = 0
            M[2][1] = 1.0/3.0
            M[2][2] = 2.0/3.0
            M[2][3] = 1

            if d₃ < 0 {
                M *= O
            }

            return TextureCoordinates(M)
        default:
            return nil
        }
    }
}
