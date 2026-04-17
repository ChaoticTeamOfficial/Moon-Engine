package moon.dependency.scripting;

import moon.hardcoded_shaders.DropShadowShader;
import moon.global_obj.TextScroll;
import openfl.display.BlendMode;
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;

/**
 * Class meant to handle scripts.
 */
class MoonScript
{
    /**
     * The script content itself.
     */
    public var code:Iris;

    /**
     * Just some default variables that'll be set on upon initializng the script.
     */
    public var DEFAULT_VARIABLES:Map<String, Dynamic> = [
        "Paths" => Paths,
        "Constants" => Constants,
        "Global" => Global,

        // I hate the fact I gotta include these... aghh
        "Reflect" => Reflect,
        "Std" => Std,

        "TextScroll" => TextScroll,

        // Other stuff to be included.
        "FlxBackdrop" => flixel.addons.display.FlxBackdrop,
        "MoonTrail" => moon.dependency.MoonTrail,

        "FlxEffectSprite" => flixel.addons.effects.chainable.FlxEffectSprite,
        "FlxWaveEffect" => flixel.addons.effects.chainable.FlxWaveEffect,
        "FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
        "DropShadowShader" => DropShadowShader,
        "ABotVisualizer" => moon.game.obj.ABotVisualizer,
        "RainShader" => moon.hardcoded_shaders.RainShader,
        "ShaderFilter" => openfl.filters.ShaderFilter
    ];

    public function new(){}

    /**
     * Loads up a script from a path. (NOTE: `Paths` USAGE IS NOT NEEDED!)
     * @param path The path in which the script is at.
     */
    inline public function load(path:String)
    {
        if(Paths.exists(path))
        {
            code = new Iris(Paths.getFileContent(path));
            for(variableName => variableValue in DEFAULT_VARIABLES)
                code.set(variableName, variableValue);
        }
        else trace('[MOON-SCRIPT] Script path at $path was not found!', "ERROR");
    }

    @:inheritDoc(Iris.get)
    public function get(variable:String):Dynamic
        return (code != null) ? ((exists(variable)) ? code.get(variable) : null) : null;

    @:inheritDoc(Iris.set)
    public function set(variable:String, value:Dynamic, ?allowOverride:Bool = true)
        return (code != null) ? code.set(variable, value, allowOverride) : null;

    @:inheritDoc(Iris.exists)
    public function exists(variable:String):Bool
        return (code != null) ? code.exists(variable) : false;

    @:inheritDoc(Iris.call)
    public function call(func:String, ?args:Null<Array<Dynamic>>)
        return (code != null) ? ((exists(func)) ? code.call(func, args) : null) : null;
}