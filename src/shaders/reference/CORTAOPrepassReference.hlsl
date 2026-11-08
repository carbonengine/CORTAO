// CORTAO Carbon Engine Implementation v1.0.0
//
// © 2026 Fenris Creations. All rights reserved.

//Include the shader
#include <CORTAOPrepass.h>

//Parameters as root constants
ConstantBuffer<CORTAOPrepassParameters> Parameters : register(b0);

//Texture resources
Texture2D<float> DepthBuffer : register(t0); //User defined format
Texture2D<float3> NormalBuffer : register(t1); //User defined format

//Image resources
RWTexture2D<uint> PackedDataBufferMipmaps[8] : register(u0); //R32_UINT mipmaps

//Input callback implementations
float CortaoLoadDepth(int2 pixelCoords) {
	return DepthBuffer.Load(int3(pixelCoords, 0));
}

float3 CortaoLoadNormal(int2 pixelCoords) {
	float3 normal = NormalBuffer.Load(int3(pixelCoords, 0)).xyz;
	//Do any normal transformation/unpacking/decoding here.
	return normal;
}

//Output callback implementation
void CortaoWritePackedData(int2 pixelCoords, int mipLevel, uint data) {
	PackedDataBufferMipmaps[mipLevel][pixelCoords] = data;
}

[numthreads(8, 8, 1)]
void Main(uint2 pixelCoords : SV_DispatchThreadID) {
	CortaoPrepass(pixelCoords, Parameters);
}
