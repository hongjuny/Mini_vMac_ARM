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

/* Vertex shader: Renders a full-screen quad with aspect ratio preservation */
vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                             constant float2 &viewportSize [[buffer(0)]],
                             constant float2 &textureSize [[buffer(1)]])
{
	/* Full-screen quad positions (in clip space: -1 to 1) */
	float2 positions[4] = {
		float2(-1.0,  1.0),  // top-left
		float2( 1.0,  1.0),  // top-right
		float2(-1.0, -1.0),  // bottom-left
		float2( 1.0, -1.0)   // bottom-right
	};
	
	/* Calculate aspect ratios */
	float viewportAspect = viewportSize.x / viewportSize.y;
	float textureAspect = textureSize.x / textureSize.y;
	
	/* Scale positions to maintain aspect ratio and center */
	float2 scaledPos;
	if (viewportAspect > textureAspect) {
		/* Viewport is wider - letterbox (black bars on sides) */
		float scale = textureAspect / viewportAspect;
		/* Center horizontally */
		float offsetX = 0.0;  /* Already centered since we scale around origin */
		scaledPos = float2(positions[vertexID].x * scale + offsetX, positions[vertexID].y);
	} else {
		/* Viewport is taller - pillarbox (black bars on top/bottom) */
		float scale = viewportAspect / textureAspect;
		/* Center vertically */
		float offsetY = 0.0;  /* Already centered since we scale around origin */
		scaledPos = float2(positions[vertexID].x, positions[vertexID].y * scale + offsetY);
	}
	
	/* Texture coordinates (0 to 1) */
	float2 texCoords[4] = {
		float2(0.0, 0.0),  // top-left
		float2(1.0, 0.0),  // top-right
		float2(0.0, 1.0),  // bottom-left
		float2(1.0, 1.0)   // bottom-right
	};
	
	VertexOut out;
	out.position = float4(scaledPos, 0.0, 1.0);
	out.texCoord = texCoords[vertexID];
	
	return out;
}

/* Fragment shader: Samples texture with configurable filtering */
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> texture [[texture(0)]],
                              constant bool &useSmoothFiltering [[buffer(0)]])
{
	/* Use linear filtering for smooth scaling, nearest for pixel-perfect */
	if (useSmoothFiltering) {
		constexpr sampler textureSampler(mag_filter::linear,
		                                 min_filter::linear,
		                                 address::clamp_to_edge);
		return texture.sample(textureSampler, in.texCoord);
	} else {
		constexpr sampler textureSampler(mag_filter::nearest,
		                                 min_filter::nearest,
		                                 address::clamp_to_edge);
		return texture.sample(textureSampler, in.texCoord);
	}
}

/* Fragment shader for grayscale (R8) textures */
fragment float4 fragment_main_grayscale(VertexOut in [[stage_in]],
                                       texture2d<float> texture [[texture(0)]],
                                       constant bool &useSmoothFiltering [[buffer(0)]])
{
	/* Use linear filtering for smooth scaling, nearest for pixel-perfect */
	float gray;
	if (useSmoothFiltering) {
		constexpr sampler textureSampler(mag_filter::linear,
		                                 min_filter::linear,
		                                 address::clamp_to_edge);
		gray = texture.sample(textureSampler, in.texCoord).r;
	} else {
		constexpr sampler textureSampler(mag_filter::nearest,
		                                 min_filter::nearest,
		                                 address::clamp_to_edge);
		gray = texture.sample(textureSampler, in.texCoord).r;
	}
	
	/* Convert to RGB (white = 1.0, black = 0.0) */
	return float4(gray, gray, gray, 1.0);
}

