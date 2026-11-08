// CORTAO Carbon Engine Implementation v1.0.0
//
// © 2026 Fenris Creations. All rights reserved.

//CORTAO defines
#define CORTAO_SAMPLE_COUNT 16
#define CORTAO_RAY_COUNT 16
#define CORTAO_USE_OCCLUDER_LOOKUP_TABLE 1
#define CORTAO_BENT_NORMAL_LOOKUP_TABLE 1

//Include the shader
#include <CORTAOMainPass.h>

//Parameters as root constants
ConstantBuffer<CORTAOMainPassParameters> Parameters : register(b0);

//Texture resources
Texture2D<uint> PackedDataBuffer : register(t0); //R32_UINT
Texture2D<float3> NormalBuffer : register(t1); //User defined format
Texture3D<uint> OccluderLookupTable : register(t2); //R16_UINT to match CORTAO_RAY_COUNT
Buffer<float2> BentNormalLookupTable : register(t3); //R8G8_SNORM

//Sampler resources
SamplerState NearestBorderSampler : register(s0); //FILTER_MIN_MAG_MIP_POINT, TEXTURE_ADDRESS_BORDER
SamplerState NearestClampSampler : register(s1); //FILTER_MIN_MAG_MIP_POINT, TEXTURE_ADDRESS_CLAMP

//Image resources
RWTexture2D<float4> OutputBuffer : register(u0); //R8G8B8A8_SNORM

//Input callback implementations
uint CortaoSamplePackedData(float2 texCoords, float mipmap) {
	return PackedDataBuffer.SampleLevel(NearestBorderSampler, texCoords, mipmap); //requires SM6.7 for integer sampling
}

float3 CortaoLoadNormal(int2 pixelCoords) {
	//Do any normal transformation/unpacking/decoding here.
	return NormalBuffer.Load(int3(pixelCoords, 0));
}

uint CortaoSampleOccluderLookupTable(float3 texCoords) {
	return OccluderLookupTable.SampleLevel(NearestClampSampler, texCoords, 0.0); //requires SM6.7 for integer sampling
}

float3 CortaoLoadBentNormalLookupTable(uint rayBits) {
	float2 bentNormal = BentNormalLookupTable.Load(int(rayBits));
	return float3(bentNormal, sqrt(float(1.0) - dot(bentNormal, bentNormal))); //reconstruct z
}

//Output callback implementation
void CortaoWriteResult(int2 pixelCoords, float occlusion, float3 bentNormal, float3x3 tangentSpaceTransform, uint rayBits) {
	//Do any bent normal transformation/packing/encoding here.
	OutputBuffer[pixelCoords] = float4(occlusion, bentNormal);
}

//Reorders the threads inside the workgroup to be more cache coherent
uint2 Deinterleave(uint index) {
	uint2 p = uint2(index, index) >> uint2(0, 1);

	p = (p ^ (p >> 1u)) & 0x3333u;
	p = (p ^ (p >> 2u)) & 0x0f0fu;
	p = (p ^ (p >> 4u)) & 0x00ffu;

	return p;
}

#define WORKGROUP_SIZE 16 //or 32
[numthreads(WORKGROUP_SIZE, WORKGROUP_SIZE, 1)]
void Main(uint2 workgroupID : SV_GroupID, uint localIndex : SV_GroupIndex) {
	uint2 pixelCoords = workgroupID * uint2(WORKGROUP_SIZE, WORKGROUP_SIZE) + Deinterleave(localIndex);
	CortaoMainPass(pixelCoords, Parameters);
}

