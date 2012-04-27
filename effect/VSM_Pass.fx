
//------------------------------------------------------------------------------
// Untweakables
//------------------------------------------------------------------------------
float4x4 tW : WORLD ;
float4x4 tV : VIEW ;
float4x4 tVP : VIEWPROJECTION ;

float3 lightPos;
float2 lightRange;

//------------------------------------------------------------------------------
// VERTEX SHADER
//------------------------------------------------------------------------------
struct vs2ps
{
	float4 PosWVP    : POSITION ;
	float depth      : TEXCOORD0 ;
};

vs2ps VS( float4 PosO : POSITION )
{
	vs2ps Out   = (vs2ps)0;
	
	float4 PosW   = mul(PosO, tW);
    Out.PosWVP    = mul(PosW, tVP);
    Out.depth = length(lightPos - PosW);//(length(lightPos - PosW)-lightRange.x)*lightRange.y;
    
	return Out;
}

//------------------------------------------------------------------------------
// PIXEL SHADER
//------------------------------------------------------------------------------

float4 PS_A(vs2ps In): COLOR
{	
	// Work out the depth of this fragment from the light, normalized to 0->1
	float distNormalized = (In.depth-lightRange.x)*lightRange.y;
	float2 depth;
    depth.x = distNormalized;
    depth.y = distNormalized.x * distNormalized.x;

    return depth.xyxy;
}

//------------------------------------------------------------------------------
// Techniques
//------------------------------------------------------------------------------

technique VSM_A_Depth
{
    pass P0
    {
        ALPHABLENDENABLE = FALSE;
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_A();
    }
}

