//@author: dottore
//@description: Draws a surface using the data position texture. shading by phong directional
//@tags: 3d surface
//@credits: 
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;        //the models world matrix
float4x4 tV: VIEW ;         //view matrix as set via Renderer (EX9)
float4x4 tVP: VIEWPROJECTION ;
float4x4 tWV: WORLDVIEW ;
float4x4 tWVP: WORLDVIEWPROJECTION ;

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{ 
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
	addressU = wrap;
};
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

#include "VSM.fxh"
#include "Blinn_Specular_VSM.fxh"

// -----------------------------------------------------------------------------
// STRUCT:
// -----------------------------------------------------------------------------

struct vs2ps2
{
    float4 PosWVP: POSITION ;
    float4 PosW: TEXCOORD0 ;
    float3 PosWV : TEXCOORD1 ;
    float3 NormWV: NORMAL ;
	float2 TexCdShadow : TEXCOORD2 ;
    float3 LightDirWV: TEXCOORD3 ;
    float3 ViewDirWV: TEXCOORD4 ;
	float2 TexCd: TEXCOORD5 ;
};

// -----------------------------------------------------------------------------
// VERTEXSHADERS:
// -----------------------------------------------------------------------------

// PLACE and DEFORM technique
vs2ps2 VS(
    float4 PosO : POSITION ,
    float3 NormO : NORMAL ,
    float4 TexCdO : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps2 Out = (vs2ps2)0;

    Out.PosW = mul(PosO, tW);
    Out.PosWV = mul(PosO, tWV);
    Out.PosWVP = mul(PosO, tWVP);

    //normal in view space
    Out.NormWV = normalize(mul(NormO, tWV));
    
    //inverse light direction in view space
    float3 LightDirW = normalize(lPos - Out.PosW);
    Out.LightDirWV = mul(LightDirW, tV);

	//Out.ViewDirV = -normalize(mul(Out.PosW, tWV));
    Out.ViewDirWV = -normalize(mul(PosO, tWV));
    
	// VSM texture coordinates:
    float4 surf_tex = mul(float4(Out.PosW.xyz, 1.0), light_tVP);
	surf_tex = surf_tex / surf_tex.w; 
	
	// Rescale viewport to be [0,1] (texture coordinate space)
	Out. TexCdShadow = surf_tex.xy * float2(0.5, -0.5) + 0.5;
    Out.TexCd = mul(TexCdO, tTex);
	
    return Out;
}

// -----------------------------------------------------------------------------
// MRT STRUCT:
// -----------------------------------------------------------------------------
struct col
{
    float4 color : COLOR0 ;
    float4 space : COLOR1 ;
    float4 normal : COLOR2 ;
};


// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

col PS1(vs2ps2 In): COLOR
{
    col c;
	c.color = Point_BlinnVSMcubemapSpecular(lPos, lCol, SpecAmount, 
									In.PosW, In.NormWV, In.ViewDirWV, 
									In.LightDirWV, In.TexCd);

	//POSITION
    c.space.xyz = In.PosWV;
    c.space.w   = 1.0f;
    
    //NORMALS
    float3 norm = In.NormWV;
    c.normal = float4(norm, gi);

    return c;
}

col PS2(vs2ps2 In): COLOR
{
    col c;
	c.color = Spot_BlinnVSMspecular(lPos, lCol, SpecAmount, 
									In.PosW, In.NormWV, In.ViewDirWV, 
									In.LightDirWV, In.TexCdShadow, In.TexCd);

	//POSITION
    c.space.xyz = In.PosWV;
    c.space.w   = 1.0f;
    
    //NORMALS
    float3 norm = In.NormWV;
    c.normal = float4(norm, gi);

    return c;
}

col PS3(vs2ps2 In): COLOR
{
    col c;
	c.color = Directional_BlinnVSMspecular(In.PosW, In.NormWV, In.ViewDirWV, 
											In.LightDirWV, In.TexCdShadow, In.TexCd);

	//POSITION
    c.space.xyz = In.PosWV;
    c.space.w   = 1.0f;
    
    //NORMALS
    float3 norm = In.NormWV;
    c.normal = float4(norm, gi);

    return c;
}

// -----------------------------------------------------------------------------
// TECHNIQUES:
// -----------------------------------------------------------------------------

technique Phong_PointLight
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
    	ALPHABLENDENABLE = FALSE;
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS1();
    }
}

technique Phong_SpotLight
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
    	ALPHABLENDENABLE = FALSE;
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS2();
    }
}

technique Phong_DirectionalLight
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
    	ALPHABLENDENABLE = FALSE;
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS3();
    }
}



