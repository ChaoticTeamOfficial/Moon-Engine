package moon.hardcoded_shaders;

import flixel.system.FlxAssets.FlxShader;

class GrayscaleShader extends FlxShader
{
	@:glFragmentSource('
        #pragma header

        void main(void) {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            gl_FragColor = vec4(gray, gray, gray, color.a);
        }
    ')
	public function new()
	{
		super();
	}
}
