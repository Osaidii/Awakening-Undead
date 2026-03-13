shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D noiseTexture;
uniform float time;
uniform float textureZoom = 1.0;
uniform float fisheyeIntensity = 0.2;
uniform vec2 chromaticShift = vec2(0.002, 0.002);
uniform float chromaticBlendFactor = 0.5;
uniform float noiseScale = 1.0;
uniform float noiseBlendFactor = 0.3;
uniform float glitchIntensity = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 screen_center = vec2(0.5);
	uv = ((uv - 0.5) / textureZoom) + 0.5;
	vec2 uv_offset = uv - screen_center;
	float distortion = 1.0 + fisheyeIntensity * dot(uv_offset, uv_offset);
	vec2 distortedUV = screen_center + uv_offset * distortion;
	vec4 baseColor = texture(SCREEN_TEXTURE, distortedUV);
	float red   = texture(SCREEN_TEXTURE, distortedUV + chromaticShift).r;
	float green = texture(SCREEN_TEXTURE, distortedUV).g;
	float blue  = texture(SCREEN_TEXTURE, distortedUV - chromaticShift).b;
	vec3 chromatic = vec3(red, green, blue);
	vec3 finalColor = mix(baseColor.rgb, chromatic, chromaticBlendFactor);
	vec2 noiseUV = distortedUV + vec2(time * 0.05, sin(time) * 0.1);
	vec3 noiseSample = texture(noiseTexture, noiseUV * noiseScale).rgb;
	finalColor = mix(finalColor, finalColor * noiseSample, noiseBlendFactor);
	COLOR = vec4(finalColor, 1.0);
}