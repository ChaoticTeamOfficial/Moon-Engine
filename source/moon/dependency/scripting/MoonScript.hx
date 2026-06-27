package moon.dependency.scripting;

import moon.dependency.scripting._internal.Printer;
import moon.dependency.scripting._internal.Parser;
import moon.dependency.scripting._internal.Interp;
import moon.dependency.scripting._internal.Expr;

/**
 * Class meant to handle scripts.
 */
class MoonScript
{
	/**
	 * Just some default variables that'll be set on upon initializing the script.
	 */
	public static final DEFAULT_VARIABLES:Map<String, Dynamic> = [
		"Paths" => Paths,
		"Constants" => Constants,
		"Global" => Global,
		"ScriptUtils" => ScriptUtils,
		"TweenUtils" => TweenUtils,
		// I hate the fact I gotta include these... aghh
		"Reflect" => Reflect,
		"Std" => Std,
		"TextScroll" => moon.global_obj.TextScroll,
		// Other stuff to be included.
		"FlxBackdrop" => flixel.addons.display.FlxBackdrop,
		"MoonTrail" => moon.dependency.MoonTrail,
		"FlxEffectSprite" => flixel.addons.effects.chainable.FlxEffectSprite,
		"FlxWaveEffect" => flixel.addons.effects.chainable.FlxWaveEffect,
		"FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
		"DropShadowShader" => moon.hardcoded_shaders.DropShadowShader,
		"ABotVisualizer" => moon.game.obj.ABotVisualizer,
		"RainShader" => moon.hardcoded_shaders.RainShader,
		"ShaderFilter" => openfl.filters.ShaderFilter
	];

	public var initialized:Bool;

	var parser:Parser;
	var interp:Interp;

	public function new()
	{
		parser = new Parser();
		initialized = false;

		interp = new Interp();
		for (key => value in DEFAULT_VARIABLES) interp.variables.set(key, value);
	}

	/**
	 * Loads up a script from a path. (NOTE: `Paths` USAGE IS NOT NEEDED!)
	 * @param path The path in which the script is at.
	 */
	public function load(path:String):Void
	{
		if (!Paths.exists(path))
		{
			trace('[MOON-SCRIPT] Script path at $path was not found!', "ERROR");
			return;
		}

		initialized = false;

		try
		{
			var decls:Array<ModuleDecl> = parser.parseModule(Paths.getFileContent(path), path);
			interp.registerModules(decls, path);
			initialized = true;

			trace([for (key => value in interp.variables) '[$key: $value]'].join(', '));
		}
		catch (e:Error)
		{
			trace('[MOON-SCRIPT] ${Printer.errorToString(e)}', "ERROR");
		}
		catch (e:Dynamic)
		{
			throw e;
		}
	}

	public function get(variable:String):Dynamic
	{
		return interp.variables.get(variable);
	}

	public function set(variable:String, value:Dynamic, ?allowOverride:Bool = true):Dynamic
	{
		interp.variables.set(variable, value);
		return value;
	}

	public function exists(variable:String):Bool
	{
		return interp.variables.exists(variable);
	}

	public function call(func:String, ?args:Null<Array<Dynamic>>):Dynamic
	{
		var field:Dynamic = get(func);
		return Reflect.callMethod(null, field, args);
	}
}
