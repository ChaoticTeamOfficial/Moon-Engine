package moon.hardcoded_shaders;

import flixel.system.FlxAssets.FlxShader;

/**
 * A shader that inverts colors, that's pretty much it.
 */
class InvertColor extends FlxShader
{
    @:glFragmentSource('
        #pragma header
        
        void main(void)
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            gl_FragColor = vec4(vec3(color.a) - color.rgb, color.a);
        }
    ')
    public function new()
    {
        super();
    }
}