package moon.hardcoded_shaders;

import flixel.system.FlxAssets.FlxShader;
import Math.exp;

class BorderGlowShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform float uTime;
		uniform float uAspect; // width / height
		uniform float uIntensity; // 0.0 to 1.0 fade control

		// Simple 2D noise function (value noise approximation)
		float hash(vec2 p)
		{
			return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
		}

		float noise(vec2 p)
		{
			vec2 i = floor(p);
			vec2 f = fract(p);
			vec2 u = f * f * (3.0 - 2.0 * f);
			return mix(mix(hash(i + vec2(0.0,0.0)),
						   hash(i + vec2(1.0,0.0)), u.x),
					   mix(hash(i + vec2(0.0,1.0)),
						   hash(i + vec2(1.0,1.0)), u.x), u.y);
		}

		float fbm(vec2 p)
		{
			float amp = 0.5;
			float freq = 1.0;
			float n = 0.0;
			for (int i = 0; i < 3; i++) // 3 octaves
			{
				n += amp * noise(p * freq);
				amp *= 0.5;
				freq *= 2.2;
			}
			return n;
		}

		void main()
		{
			vec2 uv = openfl_TextureCoordv;

			float thickX = 0.07;
			float thickY = thickX * uAspect;

			float dx = min(uv.x, 1.0 - uv.x);
			float dy = min(uv.y, 1.0 - uv.y);

			// Properly aspect-corrected normalized distance
			float distX = dx / thickX;
			float distY = dy / thickY;
			float edgeDistNorm = min(distX, distY);

			// Wobble distortion (computed in UV space first)
			vec2 noiseUV = uv * 1.8 + vec2(uTime * 0.08, uTime * 0.11);
			float noiseVal = fbm(noiseUV * 2.5) * 2.0 - 1.0; // [-1..1]

			float wave = sin(uv.x * 12.0 + uTime * 1.3) * 0.014 +
						 sin(uv.y * 15.0 + uTime * 1.6) * 0.012 +
						 cos(uv.x * 9.0 - uTime * 0.9) * 0.009;

			float distortionAmount = noiseVal * 0.022 + wave;

			// Convert to normalized distortion and fade it deeper inside
			float distortionNorm = distortionAmount / thickX;
			distortionNorm *= (1.0 - smoothstep(0.0, 0.21, edgeDistNorm));

			// Final distorted normalized distance
			float distNorm = edgeDistNorm + distortionNorm;

			// Glow layers
			float glowBase = 0.0;
			glowBase += 1.2 * exp(-distNorm * 14.0);
			glowBase += 0.7 * exp(-distNorm * 5.5);
			glowBase += 0.35 * exp(-distNorm * 1.8);

			// Sharp rim with extra highlight on outward wobble
			float rim = exp(-distNorm * 38.0) * (1.0 + 0.6 * max(0.0, distortionAmount * 30.0));

			vec3 cyanBase = vec3(0.0, 0.7, 1.2);
			vec3 rimHighlight = vec3(0.4, 1.3, 2.0);

			vec3 col = cyanBase * glowBase * 1.1;
			col += rimHighlight * rim * 2.2;

			// Subtle chromatic pulse
			col.r += 0.08 * sin(uTime * 2.0 + uv.y * 20.0) * glowBase;
			col.g += 0.05 * cos(uTime * 1.7 + uv.x * 25.0) * glowBase;

			// Apply fade intensity
			col *= uIntensity;

			// Clamp for bloom safety
			col = clamp(col, 0.0, 5.0);

			gl_FragColor = vec4(col, 1.0);
		}
	')
	public var time(default, set):Float = 0.0;

	function set_time(v:Float):Float
	{
		uTime.value = [v];
		return time = v;
	}

	public var aspect(default, set):Float = 1.0;

	function set_aspect(v:Float):Float
	{
		uAspect.value = [v];
		return aspect = v;
	}

	public var enabled:Bool = true;
	public var fadeSpeed:Float = 11.0;

	private var _intensity:Float = 1.0;

	public function new()
	{
		super();
		uTime.value = [0.0];
		uAspect.value = [1.0];
		uIntensity.value = [0.0];
	}

	public function update(elapsed:Float):Void
	{
		time += elapsed * 5;

		var target:Float = enabled ? 1.0 : 0.0;
		_intensity = target + (_intensity - target) * exp(-fadeSpeed * elapsed);
		uIntensity.value = [_intensity];
	}
}
