import CoreText

extension String {
    /// `VertexAttributes` to render the receiver with a given font.
    ///
    /// - parameter fontName: The name of the font.
    ///
    /// - returns: Vertex attributes.
    ///
    /// - note: To illustrate rendering, this function returns tessellation and curve vertex attributes separately.
    func vertexAttributes(forFontName fontName: String) -> [[VertexAttributes]] {
        let paths = self.paths(forFontName: fontName)
        let tesselationVertexAttributes = Tessellation.vertexAttributes(forPaths: paths)
        let cubicBezierCurveVertexAttributes = paths
            .flatMap { $0.cubicBézierCurves }
            .compactMap { $0.vertexAttributes }
            .flatMap { $0 }
        return [tesselationVertexAttributes, cubicBezierCurveVertexAttributes]
    }

    // MARK: Private

    private func paths(forFontName fontName: String) -> [CGPath] {
        let font = CTFontCreateWithName(fontName as CFString, 0.0, nil)
        var glyphs = self.glyphs(forFont: font)
        let boundingRect = CTFontGetBoundingRectsForGlyphs(font, CTFontOrientation.default, &glyphs, nil, self.utf16.count)

        return glyphs.compactMap { CTFontCreatePathForGlyph(font, $0, [boundingRect.inverseTransform]) }
    }

    private func glyphs(forFont font: CTFont) -> [CGGlyph] {
        var glyphs: [CGGlyph] = []
        CTFontGetGlyphsForCharacters(font, Array(self.utf16), &glyphs, self.utf16.count)
        return UnsafeBufferPointer(start: glyphs, count: self.utf16.count).filter { $0 != 0 }
    }
}
