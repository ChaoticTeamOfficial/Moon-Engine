package moon.hardcoded_shaders;

import flixel.system.FlxAssets.FlxShader;

class MosaicShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float blockSize;
		
		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			
			if (blockSize <= 1.0)
			{
				gl_FragColor = flixel_texture2D(bitmap, uv);
				return;
			}
			
			vec2 blocks = openfl_TextureSize / blockSize;
			gl_FragColor = flixel_texture2D(bitmap, floor(uv * blocks) / blocks);
		}
	')
	
	public var bSize(default,set):Float = 0;
	public function new()
	{
		super();
	}

	public function set_bSize(b:Float):Float
	{
		this.bSize = b;

		blockSize.value = [b];
		return this.bSize;
	}
}