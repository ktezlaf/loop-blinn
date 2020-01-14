#include <metal_stdlib>
using namespace metal;

/// Input vertex attributes defining a vertex's position and texture coordinates for determining coverage in the Loop-Blinn algorithm.
typedef struct VertexAttributesInput {
    /// The vertex position.
    float2 position [[attribute(0)]];

    /// The vertex texture coordinates.
    float3 klm [[attribute(1)]];
} VertexAttributesInput;

/// Vertex attributes defining a vertex's position and texture coordinates for determining coverage in the Loop-Blinn algorithm, suitable for passing directly
/// to the rasterizer.
typedef struct VertexAttributes {
    /// The vertex position.
    float4 position [[position]];

    /// The vertex texture coordinates.
    float3 klm;
} VertexAttributes;

/// Uniforms that define the colors used in a fragment shader.
typedef struct Uniforms {
    /// The foreground color.
    float4 foreground;

    /// The background color.
    float4 background;
} Uniforms;

/// A passthrough vertex shader that converts `VertexAttributesInput` to a `VertexAttributes`.
vertex VertexAttributes cubicVertexFunction(const VertexAttributesInput input [[stage_in]]) {
    return {
        .position = float4(input.position, 0, 1),
        .klm = input.klm,
    };
}

/// A fragment shader that implements the Loop-Blinn algorithm for rendering cubic Bézier curves.  Shades fragments under (inside) the curve as
/// uniforms.foreground and fragments above (outside) the curve as uniforms.background.
float4 fragment cubicFragmentFunction(const VertexAttributes input [[stage_in]],
                                      constant Uniforms &uniforms [[buffer(0)]] )
{
    float k = input.klm.x;
    float l = input.klm.y;
    float m = input.klm.z;

    float k3 = k*k*k;
    float lm = l*m;
    float diff = k3 - lm;

    return diff < 0 ? uniforms.foreground : uniforms.background;
}
