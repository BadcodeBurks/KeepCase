#ifndef WINDPROPS_INCLUDED
#define WINDPROPS_INCLUDED

float3 _WindDirection;
float _NoisePower;
float _NoiseTimeScale;

float2 getNoise(float2 uv)
{
    return float2(
        frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453),
        frac(sin(dot(uv, float2(12.9898, 78.233) * 2.0)) * 43758.5453)
    );
}
//TODO: Expensive noise function, change this to use a texture if there is time left;
void GetWindFactor(inout float3 positionToWindDir)
{
    float2 uv = positionToWindDir.xy + _Time.y * _NoiseTimeScale;
    float2 uv1 = floor(uv);
    float2 uv2 = float2(floor(uv.x), ceil(uv.y));
    float2 uv3 = ceil(uv);
    float2 uv4 = float2(ceil(uv.x), floor(uv.y));
    float2 fracUV = sin((frac(uv) * 2 - 1) * 0.5 * PI)*.5 + .5; //Sine to smooth the noise frame corners
    float2 rand = lerp(lerp(getNoise(uv1), getNoise(uv2), fracUV.x), lerp(getNoise(uv4), getNoise(uv3), fracUV.x), fracUV.y) - float2(.5, .5);
    positionToWindDir = float3(rand.x, 0.0, rand.y)*_NoisePower + _WindDirection;
}

#endif