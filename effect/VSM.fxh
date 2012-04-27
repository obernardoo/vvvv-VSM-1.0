float shadowMult <String uiname="Shadow Intensity";> = 1;

texture VSM_texture;
sampler light_shadow_map = sampler_state
{
    texture   = <VSM_texture>;
    AddressU  = border;
    AddressV  = border;
};

//ShadowMap Camera Transforms
float4x4 light_tVP <String uiname="Light View Projection";>;
float4x4 light_tVi <String uiname="Light inverse View";>;

float light_shadow_bias < string UIName = "Shadow Bias";> = 0.001;
float light_vsm_epsilon < string UIName = "VSM Epsilon";> = 0.0001;
float light_angle_atten_begin : lightumbra <string UIName = "Light Umbra"; >;
float light_angle_atten_end : lightpenumbra <string UIName = "Light Penumbra"; >;

static float2 light_angle_atten = float2(light_angle_atten_begin, light_angle_atten_end) * 0.5;
static float2 cos_light_angle_atten = cos(light_angle_atten);

float Amount = 0.2;

float2 lightRange;

//FUNCTIONS:
 
float linstep(float min, float max, float v)  
 	{  	return clamp((v - min) / (max - min), 0, 1);  }  
 
float ReduceLightBleeding(float p_max, float Amount)  
 	{  	// Remove the [0, Amount] tail and linearly rescale (Amount, 1].  
    	return linstep(Amount, 1, p_max);  }  



// SOLUTION A  from FXcomposer file
// Variance Shadow Mapping:
float3 VSM_A (float2 shadow_tex, float lightDistance)
  	{
    	float4 moments;
    	// TODO: Emulate bilinear filtering on unsupporting hardware
      	moments = tex2D(light_shadow_map, shadow_tex);
	
    	// Rescale light distance and check if we're in shadow
    	float rescaled_dist_to_light = (lightDistance-lightRange.x)*lightRange.y;
    	rescaled_dist_to_light -= light_shadow_bias;
    	float lit_factor = (rescaled_dist_to_light <= moments.x);
    	
    	// Variance shadow mapping
    	float E_x2 = moments.y;
    	float Ex_2 = moments.x * moments.x;
    	float variance = min(max(E_x2 - Ex_2, 0.0) + light_vsm_epsilon, 1.0);
    	float m_d = (moments.x - rescaled_dist_to_light);
    	float p = variance / (variance + m_d * m_d);
    	
    	// Adjust the light color based on the shadow attenuation
    	return ReduceLightBleeding(max(lit_factor, p), Amount);
  	}

// 360 Variance Shadow Mapping :
float3 VSM_Cubemap (float3 lightVec, float lightDistance)
  	{
    	float4 moments;
    	// TODO: Emulate bilinear filtering on unsupporting hardware
      	moments = texCUBE(light_shadow_map, lightVec);
	
    	// Rescale light distance and check if we're in shadow
    	float rescaled_dist_to_light = (lightDistance-lightRange.x)*lightRange.y;
    	rescaled_dist_to_light -= light_shadow_bias;
    	float lit_factor = (rescaled_dist_to_light <= moments.x);
    	
    	// Variance shadow mapping
    	float E_x2 = moments.y;
    	float Ex_2 = moments.x * moments.x;
    	float variance = min(max(E_x2 - Ex_2, 0.0) + light_vsm_epsilon, 1.0);
    	float m_d = (moments.x - rescaled_dist_to_light);
    	float p = variance / (variance + m_d * m_d);
    	
    	// Adjust the light color based on the shadow attenuation
    	return ReduceLightBleeding(max(lit_factor, p), Amount);
  	}
