package moon.hardcoded_shaders;
import flixel.system.FlxAssets.FlxShader;

class VinylDiskShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header
     
        uniform float outerRadius;
        uniform float innerRadius;
        uniform float outerOutlineWidth;
        uniform float innerHoleRadius;
     
        void main()
        {
            vec2 uv = openfl_TextureCoordv;
            vec2 center = vec2(0.5, 0.5);
            float dist = distance(uv, center);

            float totalRadius = outerRadius + outerOutlineWidth;
            float maxRadius = 0.5;
            float radiusScale = min(1.0, maxRadius / totalRadius);
            float scaledOuterRadius = outerRadius * radiusScale;
            float innerScale = innerRadius * radiusScale;
            float innerHoleScale = innerHoleRadius * radiusScale;
            float outerOutline = outerOutlineWidth * radiusScale;
         
            vec4 texColor = flixel_texture2D(bitmap, uv);
         
            // shape mask
            float outerAlpha = 1.0 - smoothstep(scaledOuterRadius + outerOutline - 0.005, scaledOuterRadius + outerOutline, dist);
            float holeAlpha = smoothstep(innerHoleScale - 0.005, innerHoleScale, dist);
            float alpha = outerAlpha * holeAlpha;
         
            // black areas
            float innerBlack = 1.0 - smoothstep(innerScale - 0.005, innerScale, dist);           // full black inside innerRadius, blends over last 0.005 px
            float outlineBlack = smoothstep(scaledOuterRadius, scaledOuterRadius + 0.005, dist);              // transition starts exactly at outerRadius (no darkening of main disk)
            float blackFactor = max(innerBlack, outlineBlack);
         
            vec3 color = mix(texColor.rgb, vec3(0.0), blackFactor);
         
            gl_FragColor = vec4(color, texColor.a * alpha);
        }
    ')

    public function new(outer:Float = 0.5, inner:Float = 0.1, outerOutlineWidth:Float = 0.03, innerHoleRadius:Float = 0.02)
    {
        super();
        this.outerRadius.value = [outer];
        this.innerRadius.value = [inner];
        this.outerOutlineWidth.value = [outerOutlineWidth];
        this.innerHoleRadius.value = [innerHoleRadius];
    }
}