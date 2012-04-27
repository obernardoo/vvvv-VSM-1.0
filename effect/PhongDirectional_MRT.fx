//@author: vvvv group
//@help: basic pixel based lightning with directional light
//@tags: shading, blinn
//@credits:

// -----------------------------------------------------------------------------
// PARAMETERS:
// -----------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD ;        //the models world matrix
float4x4 tV: VIEW ;         //view matrix as set via Renderer (EX9)
float4x4 tWV: WORLDVIEW ;
float4x4 tWVP: WORLDVIEWPROJECTION ;
float4x4 tP: PROJECTION ;   //projection matrix as set via Renderer (EX9)

#include <effects\PhongDirectional.fxh>
float GI <String uiname="Gi amount";> = 1;	// amount of ambient occlusion and cubemap illumination

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{ 
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;
float4x4 tColor <string uiname="Color Transform";>;

struct vs2ps
{
    float4 PosWVP: POSITION ;
    float4 TexCd : TEXCOORD0 ;
    float3 LightDirV: TEXCOORD1 ;
    float3 NormWV: TEXCOORD2 ;
    float3 ViewDirV: TEXCOORD3 ;
    float3 PosWV : TEXCOORD4 ;

};

// -----------------------------------------------------------------------------
// VERTEXSHADERS
// -----------------------------------------------------------------------------

vs2ps VS(
    float4 PosO: POSITION ,
    float3 NormO: NORMAL ,
    float4 TexCdO : TEXCOORD0 )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //inverse light direction in view space
    Out.LightDirV = normalize(-mul(lDir, tV));
    
    //normal in view space
    Out.NormWV = normalize(mul(NormO, tWV));

    //position (projected)
	Out.PosWV = mul(PosO, tWV);
    Out.PosWVP  = mul(PosO, tWVP);

    Out.TexCd = mul(TexCdO, tTex);
    Out.ViewDirV = -normalize(mul(PosO, tWV));
	
    return Out;
}

// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------

struct col
{
    float4 c1 : COLOR0 ;
    float4 c2 : COLOR1 ;
    float4 c3 : COLOR2 ;
};

col PS(vs2ps In)
{
    col c;

    c.c1 = tex2D(Samp, In.TexCd);
    c.c1.rgb *= PhongDirectional(In.NormWV, In.ViewDirV, In.LightDirV);
    
    c.c2.xyz = In.PosWV;
    c.c2.w   = 1.0f;

    c.c3 = float4(normalize(In.NormWV),GI);

    return c;
}


// -----------------------------------------------------------------------------
// TECHNIQUES:
// -----------------------------------------------------------------------------

technique TPhongDirectional
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        ALPHABLENDENABLE = FALSE;
    	VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
