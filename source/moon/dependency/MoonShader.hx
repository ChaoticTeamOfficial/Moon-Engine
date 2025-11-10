package moon.dependency;

import moon.dependency.scripting.MoonScript;
import openfl.Assets;
import flixel.addons.display.FlxRuntimeShader;

class MoonShader extends FlxRuntimeShader
{
    public var script:MoonScript;
    public function new(shader:String)
    {
        super(Assets.getText(Paths.getPath('data/shaders/$shader.frag')));

        script = new MoonScript();
        script.load('data/shaders/$shader.hx');
        script.set('shader', this);
    }
}