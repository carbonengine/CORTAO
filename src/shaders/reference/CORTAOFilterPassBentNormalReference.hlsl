// CORTAO Carbon Engine Implementation v1.0.0
//
// © 2026 Fenris Creations. All rights reserved.

//CORTAO defines
#define CORTAO_FILTER_BENT_NORMAL 1
#define CORTAO_LARGE_FILTER 1
#define CORTAO_FILTER_SYMMETRY 1

//Include the shader
#include <CORTAOFilterPass.h>

//Parameters as root constants
ConstantBuffer<CORTAOFilterPassParameters> Parameters : register(b0);

//Texture resources
Texture2D<uint> PackedDataBuffer : register(t0); //R32_UINT
Texture2D<uint> SsaoBuffer; //R32_UINT (packed R8G8B8A8_UNORM)

//Sampler resources
SamplerState NearestBorderSampler : register(s0); //FILTER_MIN_MAG_MIP_POINT, TEXTURE_ADDRESS_BORDER

//Image resources
RWTexture2D<float4> OutputBuffer : register(u0); //R8G8B8A8_SNORM

//Helper unpack function
float4 unpackSnorm4x8(uint p)
{
	int4 i = int4(uint4(p, p, p, p) << uint4(24u, 16u, 8u, 0u)) >> 24;
    return float4(i) * float(1.0 / 127.0);
}

//Input callback implementations
uint4 CortaoGatherPackedData(float2 texCoords, int2 offset) {
	return PackedDataBuffer.Gather(NearestBorderSampler, texCoords, offset); //requires SM6.7 for integer sampling
}

float4x4 CortaoGatherSSAO(float2 texCoords, int2 offset) {
	uint4 packedOcclusionAndBentNormal = SsaoBuffer.Gather(NearestBorderSampler, texCoords, offset); //requires SM6.7 for integer sampling
	return float4x4(
		 unpackSnorm4x8(packedOcclusionAndBentNormal[0]),
		 unpackSnorm4x8(packedOcclusionAndBentNormal[1]),
		 unpackSnorm4x8(packedOcclusionAndBentNormal[2]),
		 unpackSnorm4x8(packedOcclusionAndBentNormal[3])
	);
}

//Output callback implementation
void CortaoWriteFilterOutput(int2 pixelCoords, float4 ssao) {
	OutputBuffer[pixelCoords] = ssao;
}

//Main function
[numthreads(8, 8, 1)] //Each thread processes a 2x2 pixel block, so effectively 16x16
void Main(uint2 threadID : SV_DispatchThreadID) {
	CortaoFilterPass(threadID, Parameters);
}
