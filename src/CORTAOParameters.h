// CORTAO Carbon Engine Implementation v1.0.0
//
// © 2026 Fenris Creations. All rights reserved.


#include <cstdint>
#include <cmath>

namespace CORTAO
{

struct CORTAOConfigurationParameters
{
	uint32_t width;
	uint32_t height;
	uint32_t mipCount;
	uint32_t randomSeed;

	bool flipY;
	float projectionMatrix[4][4];
	float inverseProjectionMatrix[4][4];
	float nearPlane;
	float farPlane;

	float maxScreenspaceRadiusHeightRatio = 0.2f;
	float mipBias = -4.0f;
	float maxSlopeCompensation = 4.0f;
	float backfaceThreshold = 0.5f;
	float backfaceBoost = 0.5f;

	//Filter parameters
	float filterDepthSensitivity = 512.0f;
	float filterNormalSensitivity = 16.0f;
};

struct CORTAOPrepassParameters
{
	uint32_t packedResolution;
	float depthScale;
	float depthOffset;
	uint32_t randomSeed;

	uint32_t mipCount;
	uint32_t _padding0;
	uint32_t _padding1;
	uint32_t _padding2;
};

void PopulatePrepassParameters( const CORTAOConfigurationParameters& configuration, CORTAOPrepassParameters* parameters )
{

	parameters->packedResolution = configuration.width | ( configuration.height << 16u );

	float nearPlane = configuration.nearPlane;
	float farPlane = configuration.farPlane;
	if( std::isinf( nearPlane ) )
	{
		//infinite nearPlane plane (reverse depth)
		parameters->depthScale = 1.0f / farPlane;
		parameters->depthOffset = 0.0f;
	}
	else if( std::isinf( farPlane ) )
	{
		//infinite farPlane plane
		parameters->depthScale = -1.0f / nearPlane;
		parameters->depthOffset = 1.0f / nearPlane;
	}
	else
	{
		//standard case with finite nearPlane and farPlane planes (reverse depth is supported).
		parameters->depthScale = ( nearPlane - farPlane ) / ( nearPlane * farPlane );
		parameters->depthOffset = 1.0f / nearPlane;
	}

	parameters->randomSeed = configuration.randomSeed;
	parameters->mipCount = configuration.mipCount;
}

struct CORTAOMainPassParameters
{

	uint32_t packedResolution;
	uint32_t randomSeed;
	float normalBias;
	float maxApparentCircleRadiusCoefficient;

	float unprojectParamsX;
	float unprojectParamsY;
	float unprojectParamsZ;
	float unprojectParamsW;

	float projectionParamsX;
	float projectionParamsY;
	float projectionParamsZ;
	float projectionParamsW;

	float mipBias;
	float inverseMaxSlopeCompensation;
	float backfaceThreshold;
	float backfaceBoost;
};

void PopulateMainPassParameters( const CORTAOConfigurationParameters& configuration, CORTAOMainPassParameters* parameters )
{

	float projX = configuration.projectionMatrix[0][0];
	float projY = configuration.projectionMatrix[1][1];
	float projOffsetX = configuration.projectionMatrix[2][0];
	float projOffsetY = configuration.projectionMatrix[2][1];

	float invX = configuration.inverseProjectionMatrix[0][0];
	float invY = configuration.inverseProjectionMatrix[1][1];
	float invOffsetX = configuration.inverseProjectionMatrix[3][0];
	float invOffsetY = configuration.inverseProjectionMatrix[3][1];

	parameters->packedResolution = configuration.width | ( configuration.height << 16u );
	parameters->randomSeed = configuration.randomSeed;
	parameters->normalBias = invX / (float)configuration.width * std::sqrtf( 2.0f );

	if( configuration.flipY )
	{
		parameters->unprojectParamsX = +2.0f * invX;
		parameters->unprojectParamsY = -2.0f * invY;
		parameters->unprojectParamsZ = -invX + invOffsetX;
		parameters->unprojectParamsW = +invY - invOffsetY;

		parameters->projectionParamsX = +0.5f * projX;
		parameters->projectionParamsY = -0.5f * projY;
		parameters->projectionParamsZ = -0.5f + 0.5f * projOffsetX;
		parameters->projectionParamsW = -0.5f - 0.5f * projOffsetY;
	}
	else
	{
		parameters->unprojectParamsX = +2.0f * invX;
		parameters->unprojectParamsY = +2.0f * invY;
		parameters->unprojectParamsZ = -invX + invOffsetX;
		parameters->unprojectParamsW = -invY + invOffsetY;

		parameters->projectionParamsX = +0.5f * projX;
		parameters->projectionParamsY = +0.5f * projY;
		parameters->projectionParamsZ = -0.5f + 0.5f * projOffsetX;
		parameters->projectionParamsW = -0.5f + 0.5f * projOffsetY;
	}

	float maxApparentCircleRadius = invY * configuration.maxScreenspaceRadiusHeightRatio * 2.0f;
	parameters->maxApparentCircleRadiusCoefficient = maxApparentCircleRadius / std::sqrtf( maxApparentCircleRadius * maxApparentCircleRadius + 1.0f );
	parameters->mipBias = std::log2f( projY * (float)configuration.height * 0.5f ) + configuration.mipBias;
	parameters->inverseMaxSlopeCompensation = 1.0f / configuration.maxSlopeCompensation;
	parameters->backfaceThreshold = configuration.backfaceThreshold;

	parameters->backfaceBoost = configuration.backfaceBoost;
}


struct CORTAOFilterPassParameters
{
	uint32_t packedResolution;
	float depthSensitivity;
	float normalSensitivity;
};

void PopulateFilterPassParameters( const CORTAOConfigurationParameters& configuration, CORTAOFilterPassParameters* parameters )
{
	parameters->packedResolution = configuration.width | ( configuration.height << 16u );
	parameters->depthSensitivity = configuration.filterDepthSensitivity;
	parameters->normalSensitivity = configuration.filterNormalSensitivity;
}
}