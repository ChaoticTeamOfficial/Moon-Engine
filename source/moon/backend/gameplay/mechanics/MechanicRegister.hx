package moon.backend.gameplay.mechanics;

using StringTools;

@:publicFields
/**
 * Registers and keeps track of every scripted mechanic in `data/mechanics/`.
 */
class MechanicRegister
{
	/**
	 * Every currently registered mechanic, mapped by name.
	 */
	static var mechanics:Map<String, Mechanic> = [];

	/**
	 * Scans `data/mechanics/` and registers (creates) every mechanic found there.
	 */
	static function init():Void
	{
		clear();

		for (file in Paths.readDir('data/mechanics', ['.hx'], true)) register(file);

		trace('[MECHANICS] Registered ${[for (k in mechanics.keys()) k]}', "DEBUG");
	}

	/**
	 * Registers (creates) a single mechanic by name if it isn't already registered.
	 * @param name The mechanic's name.
	 */
	static function register(name:String):Mechanic
	{
		if (mechanics.exists(name)) return mechanics.get(name);

		final mech = new Mechanic(name);
		mechanics.set(name, mech);
		return mech;
	}

	/**
	 * Returns a registered mechanic by name, or null (with a warning) if it doesn't exist.
	 * @param name The mechanic's name.
	 */
	static function get(name:String):Mechanic
	{
		if (!mechanics.exists(name))
		{
			trace('[MECHANICS] "$name" was not found or registered!', "WARNING");
			return null;
		}
		return mechanics.get(name);
	}

	/**
	 * Whether a mechanic with this name exists in the register.
	 */
	static function exists(name:String):Bool return mechanics.exists(name);

	/**
	 * Returns every registered mechanic.
	 */
	static function getAll():Array<Mechanic> return[for (m in mechanics) m];

	/**
	 * Calls `onUpdate` on every registered mechanic.
	 */
	static function updateAll(elapsed:Float):Void for (m in mechanics) m.update(elapsed);

	/**
	 * Unregisters and clears every mechanic.
	 */
	static function clear():Void mechanics.clear();
}
