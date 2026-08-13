package moon.backend.gameplay.mechanics;

import moon.dependency.scripting.MoonScript;

/**
 * A single scripted mechanic, loaded from `data/mechanics/<name>.hx`.
 */
class Mechanic extends MoonScript
{
	/**
	 * This mechanic's name.
	 */
	public var name:String;

	/**
	 * Whether the mechanic settings was enabled at creation time or not.
	 */
	public var settingEnabled:Bool = true;

	/**
	 * Whether this mechanic is enabled or not.
	 */
	public var enabled:Bool = false;

	/**
	 * Whether the script actually loaded successfully.
	 */
	public var valid(get, never):Bool;

	inline function get_valid():Bool return code != null;

	public function new(name:String)
	{
		super();
		this.name = name;
		settingEnabled = MoonSettings.callSetting('Mechanics') ?? true;

		final path = 'data/mechanics/$name.hx';
		if (Paths.exists(path)) load(path);
		else
			trace('[MECHANIC] "$name" does not have a script at $path!', "ERROR");

		if (valid)
		{
			set('mechanic', this);
			set('MechanicHelper', MechanicHelper);

			if (exists('onCreate')) call('onCreate');
		}
	}

	/**
	 * Calls a function on the mechanic's script, but only if it's both valid AND settingEnabled.
	 * @param func The function name.
	 * @param args The function's arguments.
	 */
	public function callSafe(func:String, ?args:Array<Dynamic>):Dynamic return (settingEnabled && valid) ? call(func, args) : null;

	public inline function update(elapsed:Float):Void callSafe('onUpdate', [elapsed]);
}
