import CoreGraphics

/// Tesselates paths into `VertexAttributes` for rendering triangles.
enum Tessellation {
    private typealias Coordinate = Float
    private typealias Vertex = SIMD2<Coordinate>
    private typealias Contour = [Vertex]

    private static let vertexSize = Int32(MemoryLayout<Vertex>.stride)

    /// Convert paths to on-contour vertex attributes to render a triangle tessellation.
    static func vertexAttributes(forPaths paths: [CGPath]) -> [VertexAttributes] {
        let tess = self.tesselation(forPaths: paths)

        let coordinates = UnsafeBufferPointer(start: tessGetVertices(tess), count: 2 * Int(tessGetVertexCount(tess)))
        let vertices = stride(from: 0, to: coordinates.count, by: 2).map { Vertex(coordinates[$0], coordinates[$0 + 1]) }
        let indices = UnsafeBufferPointer(start: tessGetElements(tess), count: 3 * Int(tessGetElementCount(tess))).map(Int.init)
        let triangleVertices = indices.map { vertices[$0] }

        tessDeleteTess(tess)

        return triangleVertices.map { ($0, [0, 1, 1]) }
    }

    // MARK: Private

    private static func tesselation(forPaths paths: [CGPath]) -> OpaquePointer? {
        let tesselation = tessNewTess(nil)
        tessSetOption(tesselation, Int32(TESS_CONSTRAINED_DELAUNAY_TRIANGULATION.rawValue), 1)

        self.contours(forPaths: paths)
            .filter { $0.count > 2 }
            .forEach { tessAddContour(tesselation, 2, $0, vertexSize, Int32($0.count)) }
        tessTesselate(tesselation, Int32(TESS_WINDING_ODD.rawValue), Int32(TESS_POLYGONS.rawValue), 3, 2, nil)

        return tesselation
    }

    private static func contours(forPaths paths: [CGPath]) -> [Contour] {
        paths
            .flatMap { $0.contours }
            .map { $0.map(Vertex.init) }
    }
}

private extension SIMD2 where Scalar == Float {
    init(point: CGPoint) {
        self.init(Scalar(point.x), Scalar(point.y))
    }
}
