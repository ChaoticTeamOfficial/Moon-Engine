package moon.hardcoded_shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxFrame;
import moon.dependency.MoonSprite;

class SilhouetteGlowShader extends FlxShader
{
	/**
	 * How much of the original color bleeds into the silhouette.
	 */
	public var brightness(default, set):Float = 0.04;

	/**
	 * Base color of the silhouette body.
	 */
	public var silhouetteColor(default, set):FlxColor = 0xFF0A0A14;

	/**
	 * Luminance above which pixels are treated as the brightness.
	 */
	public var brightThreshold(default, set):Float = 0.86;

	/**
	 * Softness of the brightness mask.
	 */
	public var brightSoftness(default, set):Float = 0.07;

	/**
	 * Brightness multiplier.
	 */
	public var brightBoost(default, set):Float = 1.45;

	/**
	 * Tint applied to the surviving bright pixels.
	 */
	public var brightTint(default, set):FlxColor = 0xAA80E0FF;

	/**
	 * The sprite this shader is attached to.
	 */
	public var attachedSprite(default, set):MoonSprite;

	@:glFragmentSource('
		#pragma header

		uniform float ubrightness;
		uniform vec3 uSilhouetteColor;
		uniform float ubrightThreshold;
		uniform float ubrightSoftness;
		uniform float ubrightBoost;
		uniform vec4 ubrightTint;

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

			vec3 rgb = color.a > 0.0 ? color.rgb / color.a : color.rgb;
			float lum = dot(rgb, vec3(0.299, 0.587, 0.114));

			float eyeMask = smoothstep(
				ubrightThreshold - ubrightSoftness,
				ubrightThreshold + ubrightSoftness * 0.35,
				lum
			);
			vec3 body = mix(uSilhouetteColor, rgb, ubrightness);
			vec3 eyes = rgb * ubrightBoost;
			eyes = mix(eyes, ubrightTint.rgb, ubrightTint.a);

			vec3 finalRGB = mix(body, eyes, eyeMask);

			gl_FragColor = vec4(finalRGB * color.a, color.a);
		}
	')
	public function new()
	{
		super();
		brightness = 0.0;
		silhouetteColor = 0xFF050810;
		brightThreshold = 1.15;
		brightSoftness = 0.8;
		brightBoost = 2.4;
		brightTint = 0xC790F0FF;
	}

	function set_brightness(v:Float):Float
	{
		ubrightness.value = [v];
		return brightness = v;
	}

	function set_silhouetteColor(c:FlxColor):FlxColor
	{
		uSilhouetteColor.value = [c.redFloat, c.greenFloat, c.blueFloat];
		return silhouetteColor = c;
	}

	function set_brightThreshold(v:Float):Float
	{
		ubrightThreshold.value = [v];
		return brightThreshold = v;
	}

	function set_brightSoftness(v:Float):Float
	{
		ubrightSoftness.value = [v];
		return brightSoftness = v;
	}

	function set_brightBoost(v:Float):Float
	{
		ubrightBoost.value = [v];
		return brightBoost = v;
	}

	function set_brightTint(c:FlxColor):FlxColor
	{
		ubrightTint.value = [c.redFloat, c.greenFloat, c.blueFloat, c.alphaFloat];
		return brightTint = c;
	}

	function set_attachedSprite(spr:MoonSprite):MoonSprite
	{
		attachedSprite = spr;
		attachedSprite.shader = this;

		if (attachedSprite != null && attachedSprite.isAnimate && !attachedSprite.useRenderTexture) attachedSprite.useRenderTexture = true;

		return spr;
	}
}
