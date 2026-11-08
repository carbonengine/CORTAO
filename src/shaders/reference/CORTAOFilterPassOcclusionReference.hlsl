// CORTAO Carbon Engine Implementation v1.0.0
//
// © 2026 Fenris Creations. All rights reserved.

//CORTAO defines
#define CORTAO_LARGE_FILTER 1
#define CORTAO_FILTER_SYMMETRY 1

//Include the shader
#include <CORTAOFilterPass.h>

//Parameters as root constants
ConstantBuffer<CORTAOFilterPassParameters> Parameters : register(b0);

//Texture resources
Texture2D<uint> PackedDataBuffer : register(t0); //R32_UINT
Texture2D<float> SsaoBuffer; //R8_UNORM

//Sampler resources
SamplerState NearestBorderSampler : register(s0); //FILTER_MIN_MAG_MIP_POINT, TEXTURE_ADDRESS_BORDER

//Image resources
RWTexture2D<float> OutputBuffer : register(u0); //R8_UNORM

//Input callback implementations
uint4 cortao_gatherPackedData(float2 texCoords, int2 offset) {
	return PackedDataBuffer.Gather(NearestBorderSampler, texCoords, offset); //requires SM6.7 for integer sampling
}

float4 cortao_gatherSSAO(float2 texCoords, int2 offset) {
	return SsaoBuffer.Gather(NearestBorderSampler, texCoords, offset);
}

//Output callback implementation
void cortao_writeFilterOutput(int2 pixelCoords, float ssao) {
	OutputBuffer[pixelCoords] = ssao;
}

//Main function
[numthreads(8, 8, 1)] //Each thread processes a 2x2 pixel block, so effectively 16x16
void Main(uint2 threadID : SV_DispatchThreadID) {
	CortaoFilterPass(threadID, Parameters);
}
