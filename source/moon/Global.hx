package moon;

import moon.dependency.scripting.MoonScript;
import haxe.io.Bytes;

@:publicFields
/**
 * This class has global variables and multiple utilities that are used anywhere in the game.
 */
class Global
{
	/**
	 * Whether or not to allow inputs on the game (Only applied when MoonInput is used).
	 */
	static var allowInputs:Bool = true;

	// ------ SCRIPTING STUFF ------ //

	/**
	 * A Map containing all loaded & active scripts.
	 */
	static var scripts:Map<String, MoonScript> = [];

	/**
	 * Registers a new script on the map.
	 * @param scriptName The name for the script, used for identifying.
	 * @param script The script itself.
	 */
	static function registerScript(scriptName:String, script:MoonScript)
	{
		if (!scripts.exists(scriptName))
		{
			scripts.set(scriptName, script);
			trace('[SCRIPTS] Registered a new script: $scriptName', "DEBUG");
		}
	}

	/**
	 * Un-Registers a script from the map.
	 * @param scriptName The script's name, given at `registerScript()`.
	 */
	static function unregisterScript(scriptName:String)
	{
		if (scripts.exists(scriptName))
		{
			scripts.remove(scriptName);
			trace('[SCRIPTS] Un-Registered a script: $scriptName', "DEBUG");
		}
	}

	/**
	 * Calls a field/method in all the scripts if they exist.
	 * @param field The field's name. Can be a function or a variable.
	 * @param args The arguments needed for said field.
	 */
	static function scriptCall(field:String, ?args:Null<Array<Dynamic>>)
	{
		for (script in scripts.iterator()) if (script != null && script.exists(field)) script.call(field, args);
	}

	/**
	 * Sets a field on all the scripts.
	 * @param variable The field name (used for the scripts).
	 * @param value The field itself.
	 * @param allowOverride whether to allow override or not
	 */
	static function scriptSet(variable:String, value:Dynamic, ?allowOverride:Bool = true)
	{
		for (script in scripts.iterator()) if (script != null) script.set(variable, value, allowOverride);
	}

	/**
	 * Removes all the scripts from the list.
	 */
	static function clearScriptList()
	{
		trace('[SCRIPTS] CLEARING SCRIPT LIST!', "WARNING");
		for (name => script in scripts) unregisterScript(name);
	}

	// --- MODIFIERS
	static var scrollSpeedMult:Float = 1;
}
