package moon.hardcoded_shaders;

import flixel.system.FlxAssets.FlxShader;

/**
 * Pulls colors toward gold and adds a cute little moving highlight.
 */
class GoldenShimmerShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;
		uniform float uIntensity;

		void main()
		{
			vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);
			if (tex.a < 0.01) {
				gl_FragColor = tex;
				return;
			}
			
			float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
			vec3 gold = vec3(1.0, 0.82, 0.28);
			vec3 tinted = mix(tex.rgb, gold * (0.55 + luma * 0.7), uIntensity);

			float wave = sin((openfl_TextureCoordv.x + openfl_TextureCoordv.y) * 8.0 - uTime * 4.0);
			wave = wave * 0.5 + 0.5; // 0..1
			float sparkle = smoothstep(0.65, 1.0, wave) * uIntensity;

			tinted += vec3(1.0, 0.95, 0.6) * sparkle * 0.35;

			gl_FragColor = vec4(tinted, tex.a);
		}
	')
	public function new(intensity:Float = 0.85)
	{
		super();
		uTime.value = [0.0];
		uIntensity.value = [intensity];
	}

	var wow:Float = 0;

	public function update(elapsed:Float):Void
	{
		wow += elapsed;
		uTime.value[0] = wow;
	}

	public function setIntensity(v:Float):Void
	{
		uIntensity.value[0] = v;
	}
}
