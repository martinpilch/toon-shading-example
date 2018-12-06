#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct SceneNodeBuffer {
    float4x4 modelViewTransform;
    float4x4 modelViewProjectionTransform;
};

struct VertexIn {
    float3 position [[ attribute(SCNVertexSemanticPosition) ]];
    float3 normal [[ attribute(SCNVertexSemanticNormal) ]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 eye;
};

struct Light
{
    float3 position;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant Light light = {
    .position = { 10, 50, 0 },
    .ambientColor = { 0.05, 0.05, 0.05 },
    .diffuseColor = { 0.9, 0.9, 0.9 },
    .specularColor = { 1, 1, 1 }
};

struct Material
{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

constant Material material = {
    .ambientColor = { 1, 0, 0 },
    .diffuseColor = { 1, 0, 0 },
    .specularColor = { 1, 1, 1 },
    .specularPower = 100
};

vertex VertexOut lightingVertex(
                                VertexIn in [[ stage_in ]],
                                constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                                constant SceneNodeBuffer& scn_node [[buffer(1)]]
                                ) {
    VertexOut out;

    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1);
    out.normal = in.normal;
    out.eye = -(scn_node.modelViewTransform * float4(in.position, 1)).xyz;

    return out;
}

fragment float4 lightingFragment(VertexOut in [[stage_in]]) {

    float3 normal = normalize(in.normal);

    // For edges set color to yellow
    float3 V = normalize(in.eye - in.position.xyz);
    float edgeDetection = (abs(dot(V, normal)) > 0.1) ? 1 : 0;
    if ( edgeDetection != 1 ) {
        return float4(1, 1, 0, 1);
    }

    // Compute simple phong
    float3 lightDirection = normalize(light.position - in.position.xyz);
    float diffuseIntensity = saturate(dot(normal, lightDirection));
    float3 diffuseTerm = light.diffuseColor * material.diffuseColor * diffuseIntensity;

    // Ambient color
    float3 ambientTerm = light.ambientColor * material.ambientColor;

    return float4(ambientTerm + diffuseTerm, 1.0);
}
