/*
	shaders.metal
	
	Metal shaders for Mini vMac rendering
	
	Copyright (C) 2024 Mini vMac ARM Project
	
	You can redistribute this file and/or modify it under the terms
	of version 2 of the GNU General Public License as published by
	the Free Software Foundation.
*/

#include <metal_stdlib>
using namespace metal;

/* Vertex shader output structure */
struct VertexOut {
	float4 position [[position]];
	float2 texCoord [[user(locn0)]];
};

/* Vertex shader: Renders a full-screen quad */
vertex VertexOut vertex_main(uint vertexID [[vertex_id]])
{
	/* Full-screen quad positions (in clip space: -1 to 1) */
	float2 positions[4] = {
		float2(-1.0,  1.0),  // top-left
		float2( 1.0,  1.0),  // top-right
		float2(-1.0, -1.0),  // bottom-left
		float2( 1.0, -1.0)   // bottom-right
	};
	
	/* Texture coordinates (0 to 1) */
	float2 texCoords[4] = {
		float2(0.0, 0.0),  // top-left
		float2(1.0, 0.0),  // top-right
		float2(0.0, 1.0),  // bottom-left
		float2(1.0, 1.0)   // bottom-right
	};
	
	VertexOut out;
	out.position = float4(positions[vertexID], 0.0, 1.0);
	out.texCoord = texCoords[vertexID];
	
	return out;
}

/* Fragment shader: Samples texture and outputs color */
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> texture [[texture(0)]])
{
	/* Nearest neighbor sampling for pixel-perfect rendering */
	constexpr sampler textureSampler(mag_filter::nearest,
	                                 min_filter::nearest,
	                                 address::clamp_to_edge);
	
	/* Sample the texture and return the color */
	return texture.sample(textureSampler, in.texCoord);
}

