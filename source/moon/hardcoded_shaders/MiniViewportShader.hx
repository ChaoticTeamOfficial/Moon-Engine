package moon.hardcoded_shaders;

import flixel.system.FlxAssets.FlxShader;

/**
 * A shader used for the level editor's mini player.
 * Huge thanks to DiogoTV for the idea!
 */
class MiniViewportShader extends FlxShader
{
	public var scale(get, set):Float;
	public var offsetX(get, set):Float;
	public var offsetY(get, set):Float;

	function get_scale():Float return uScale.value[0];

	function set_scale(v:Float):Float
	{
		uScale.value[0] = v;
		return v;
	}

	function get_offsetX():Float return uOffsetX.value[0];

	function set_offsetX(v:Float):Float
	{
		uOffsetX.value[0] = v;
		return v;
	}

	function get_offsetY():Float return uOffsetY.value[0];

	function set_offsetY(v:Float):Float
	{
		uOffsetY.value[0] = v;
		return v;
	}

	@:glFragmentSource('
		#pragma header

		uniform float uScale;
		uniform float uOffsetX;
		uniform float uOffsetY;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;

			vec2 rectMin = vec2(uOffsetX, uOffsetY);
			vec2 rectMax = rectMin + vec2(uScale, uScale);

			if (uv.x < rectMin.x || uv.y < rectMin.y || uv.x > rectMax.x || uv.y > rectMax.y)
			{
				gl_FragColor = vec4(0.0);
				return;
			}
			
			vec2 local = (uv - rectMin) / max(uScale, 0.0001);
			gl_FragColor = flixel_texture2D(bitmap, local);
		}
	')
	public function new()
	{
		super();
		uScale.value = [1.0];
		uOffsetX.value = [0.0];
		uOffsetY.value = [0.0];
	}
}
