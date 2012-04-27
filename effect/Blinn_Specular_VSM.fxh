
//Light:
float3 lPos <string uiname="Light Position";> = {0, 5, -2};       //light position in world space
float3 lDir <string uiname="Light Direction";> = {0, -5, 2};
float4 lCol : COLOR <String uiname="Light Color";> = {0.5, 0.5, 0.5, 1};
float lAtt0 <String uiname="Light Attenuation 0"; float uimin=0.0;> = 0;
float lAtt1 <String uiname="Light Attenuation 1"; float uimin=0.0;> = 0.3;
float lAtt2 <String uiname="Light Attenuation 2"; float uimin=0.0;> = 0;

//Object Material:

float4 colDiff  : COLOR <String uiname="Object Color";>  = {.8, .8, .8, 1};
float DiffAmount <String uiname="Diffuse Amount"; float uimin=0.0;> = 1;
float SpecAmount <String uiname="Specular Amount"; float uimin=0.0;> = .75;
float lPower <String uiname="Power"; float uimin=0.0;> = 25.0;     //shininess of specular highlight

//Ambient:
float4 colAmb  : COLOR <String uiname="Ambient Color";>  = {0.15, 0.15, 0.15, 1};
float gi <string uiname="Global Illumination Intensity";> = 1;

//--------------------

float4 Point_BlinnVSMcubemapSpecular(	float3 lPos,
										float4 lCol,
										float SpecAmount,
										float4 PosW,
										float3 NormWV,
										float3 ViewDirWV,
										float3 LightDirWV,
										float2 TexCd	)
{
// Unnormalized light vector
	float3 dir_to_light = lPos - PosW;
	// distance from light
	float d = length(dir_to_light);
	// attenuation factor
	float atten = 1/(saturate(lAtt0) + saturate(lAtt1) * d + saturate(lAtt2) * pow(d, 2));
    			
// BLINN
    float3 H = normalize(ViewDirWV + LightDirWV); //halfvector
    float3 blinn = lit(dot(NormWV, LightDirWV), dot(NormWV, H), lPower)  * atten;

// DARK
    float dark = 1;

// SHADOWS
float shadow = 1;
if(shadowMult!=0)
	{
	 shadow = 1-(1-VSM_Cubemap(-dir_to_light, d)) * shadowMult;  
	
	
	dark = min(blinn.y, shadow);
	}
else{	dark = blinn.y;	}	
		
// SPECULAR
    //reflection vector (view space)
    float3 R = normalize(2 * dot(NormWV, LightDirWV) * NormWV - LightDirWV);
    //normalized view direction (view space)
    float3 V = normalize(ViewDirWV);
    //calculate specular light
    float4 spec = pow(max(dot(R, V),0), lPower*.2) * dark * SpecAmount;
	
	
float4 FinalCol = (colDiff * tex2D(Samp, TexCd) * (dark + colAmb * atten) +  spec) * lCol ; 
FinalCol.a = 1;
return FinalCol;
}

//-------------------

float4 Spot_BlinnVSMspecular(	float3 lPos,
								float4 lCol,
								float SpecAmount,
								float4 PosW,
								float3 NormWV,
								float3 ViewDirWV,
								float3 LightDirWV,
								float2 TexCdShadow,
								float2 TexCd	)
{
// Unnormalized light vector
	float3 dir_to_light = lPos - PosW;
	// distance from light
	float d = length(dir_to_light);
	// attenuation factor
	float atten = 1/(saturate(lAtt0) + saturate(lAtt1) * d + saturate(lAtt2) * pow(d, 2));
    			
// BLINN
    float3 H = normalize(ViewDirWV + LightDirWV); //halfvector
    float3 blinn = lit(dot(NormWV, LightDirWV), dot(NormWV, H), lPower)  * atten;

// DARK
    float dark = 1;

// SHADOWS
float shadow = 1;
if(shadowMult!=0)
	{
	 shadow = 1-(1-VSM_A(TexCdShadow, d)) * shadowMult;  
	// Radial attenuation
    	dir_to_light = normalize(dir_to_light);
    	float2 cos_angle_atten = cos_light_angle_atten;
    	float  cos_angle = dot(-dir_to_light, lDir);   	
    	float angle_atten_amount = clamp((cos_angle - cos_angle_atten.x) /
                  					(cos_angle_atten.y - cos_angle_atten.x),
            	   					0.0, 1.0);
	
	shadow *= 1.0 - angle_atten_amount * shadowMult;
	dark = min(blinn.y, shadow);
	}
else{	dark = blinn.y;	}	
		
// SPECULAR
    //reflection vector (view space)
    float3 R = normalize(2 * dot(NormWV, LightDirWV) * NormWV - LightDirWV);
    //normalized view direction (view space)
    float3 V = normalize(ViewDirWV);
    //calculate specular light
    float4 spec = pow(max(dot(R, V),0), lPower*.2) * dark * SpecAmount;
	
	
float4 FinalCol = (colDiff * tex2D(Samp, TexCd) * (dark + colAmb * atten) +  spec) * lCol ; 
FinalCol.a = 1;
return FinalCol;
}

// ----------------------------

float4 Directional_BlinnVSMspecular(	float4 PosW,
										float3 NormWV,
										float3 ViewDirWV,
										float3 LightDirWV,
										float2 TexCdShadow,
										float2 TexCd	)
{
	// Unnormalized light vector
    float3 dir_to_light = lPos - PosW;
	// distance from light
	float d = length(dir_to_light);
		
	// BLINN
    	float3 H = normalize(ViewDirWV + LightDirWV); //halfvector
    	float3 blinn = lit(dot(NormWV, LightDirWV), dot(NormWV, H), lPower);

	// DARK
    	float dark = 1;

	// SHADOWS
	float shadow = 1;
	if(shadowMult!=0)
		{
		float shadow = 1-(1-VSM_A(TexCdShadow, d)) * shadowMult; 
	   	dark = min(blinn.y, shadow);
		}
	else{	dark = blinn.y;	}
	
	// SPECULAR
    	//reflection vector (view space)
    	float3 R = normalize(2 * dot(NormWV, LightDirWV) * NormWV - LightDirWV);
    	//normalized view direction (view space)
    	float3 V = normalize(ViewDirWV);
    	//calculate specular light
    	float4 spec = pow(max(dot(R, V),0), lPower*.2) * dark * SpecAmount;
    		
	float4 FinalCol = (colDiff * tex2D(Samp, TexCd) * (dark + colAmb) + spec) * lCol * DiffAmount;
	FinalCol.a = 1;
	return FinalCol;
}
	