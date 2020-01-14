import Metal
import QuartzCore

private let kMaximumVertexCount = 1024
private let kVertexFunctionName = "cubicVertexFunction"
private let kFragmentFunctionName = "cubicFragmentFunction"

private let kRed: Color = [1, 0, 0, 1]
private let kBlack: Color = [0, 0, 0, 1]
private let kWhite: Color = [1, 1, 1, 1]
private let kTesselationUniforms = Uniforms(foreground: kBlack, background: kWhite)
private let kCurveUniforms = Uniforms(foreground: kRed, background: kWhite)

private typealias ColorComponent = Float
private typealias Color = SIMD4<ColorComponent>

private struct Uniforms {
    let foreground: Color
    let background: Color
}

/// Renders text in a `CAMetalLayer`.
public struct TextRenderer {
    private let metalLayer: CAMetalLayer
    private let metalDevice: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let renderPipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let multisampleTexture: MTLTexture
    private let uniformsBuffer: MTLBuffer

    public init(metalLayer: CAMetalLayer) {
        self.metalLayer = metalLayer
        self.metalDevice = metalLayer.device!
        self.commandQueue = self.metalDevice.makeCommandQueue()!

        let positionVertexAttributeDescriptor = MTLVertexAttributeDescriptor()
        positionVertexAttributeDescriptor.format = .float2
        positionVertexAttributeDescriptor.offset = 0
        positionVertexAttributeDescriptor.bufferIndex = 0

        let klmVertexAttributeDescriptor = MTLVertexAttributeDescriptor()
        klmVertexAttributeDescriptor.format = .float3
        klmVertexAttributeDescriptor.offset = MemoryLayout<SIMD4<Float>>.stride
        klmVertexAttributeDescriptor.bufferIndex = 0

        let vertexBufferLayoutDescriptor = MTLVertexBufferLayoutDescriptor()
        vertexBufferLayoutDescriptor.stepFunction = .perVertex
        vertexBufferLayoutDescriptor.stepRate = 1
        vertexBufferLayoutDescriptor.stride = MemoryLayout<VertexAttributes>.stride

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0] = positionVertexAttributeDescriptor
        vertexDescriptor.attributes[1] = klmVertexAttributeDescriptor
        vertexDescriptor.layouts[0] = vertexBufferLayoutDescriptor

        let metalLibrary = self.metalDevice.makeDefaultLibrary()!
        let vertexFunction = metalLibrary.makeFunction(name: kVertexFunctionName)
        let fragmentFunction = metalLibrary.makeFunction(name: kFragmentFunctionName)

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        renderPipelineDescriptor.sampleCount = 4
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        self.renderPipelineState = try! self.metalDevice.makeRenderPipelineState(descriptor: renderPipelineDescriptor)

        let vertexBufferLength = kMaximumVertexCount * MemoryLayout<VertexAttributes>.stride
        self.vertexBuffer = self.metalDevice.makeBuffer(length: vertexBufferLength)!

        let uniformsBufferLength = 2 * MemoryLayout<Uniforms>.stride
        self.uniformsBuffer = self.metalDevice.makeBuffer(length: uniformsBufferLength)!
        self.uniformsBuffer.contents().copyMemory(from: [kTesselationUniforms, kCurveUniforms], byteCount: uniformsBufferLength)

        let multisampleTextureDescriptor = MTLTextureDescriptor()
        multisampleTextureDescriptor.pixelFormat = metalLayer.pixelFormat
        multisampleTextureDescriptor.textureType = .type2DMultisample
        multisampleTextureDescriptor.width = Int(metalLayer.drawableSize.width)
        multisampleTextureDescriptor.height = Int(metalLayer.drawableSize.height)
        multisampleTextureDescriptor.usage = .renderTarget
        multisampleTextureDescriptor.sampleCount = 4
        self.multisampleTexture = self.metalDevice.makeTexture(descriptor: multisampleTextureDescriptor)!
    }

    /// Render text into the receiver's `CAMetalLayer`.
    ///
    /// - parameter text: The text.
    /// - parameter font: The name of a font in which to render `text`.
    public func render(_ text: String, fontName: String) {
        let vertexAttributes = text.vertexAttributes(forFontName: fontName)
        let verticesLength = vertexAttributes.flatMap { $0 }.count * MemoryLayout<VertexAttributes>.stride
        self.vertexBuffer.contents().copyMemory(from: vertexAttributes.flatMap { $0 }, byteCount: verticesLength)

        let commandBuffer = self.commandQueue.makeCommandBuffer()!

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = self.multisampleTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve

        autoreleasepool {
            let drawable = self.metalLayer.nextDrawable()!
            renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
            let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderCommandEncoder.setRenderPipelineState(self.renderPipelineState)
            renderCommandEncoder.setFrontFacing(.counterClockwise)
            renderCommandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
            renderCommandEncoder.setFragmentBuffer(self.uniformsBuffer, offset: 0, index: 0)

            // To illustrate rendering, draw tessellation and curve vertex attributes separately.
            var drawCall = 0
            vertexAttributes.tallying { vertexStart, vertexAttributes in
                renderCommandEncoder.setFragmentBufferOffset(drawCall * MemoryLayout<Uniforms>.stride, index: 0)
                renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: vertexStart, vertexCount: vertexAttributes.count)
                drawCall += 1
            }

            renderCommandEncoder.endEncoding()
            commandBuffer.present(drawable)
        }

        commandBuffer.commit()
    }
}

private extension Sequence where Element: Collection {
    func tallying(body: (Int, Element) -> Void) -> Void {
        var tally = 0
        self.forEach {
            body(tally, $0)
            tally += $0.count
        }
    }
}
