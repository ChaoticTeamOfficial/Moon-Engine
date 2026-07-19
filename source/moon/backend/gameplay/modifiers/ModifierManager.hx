package moon.backend.gameplay.modifiers;

import moon.backend.gameplay.modifiers.Modifiers.ModifierIds;

class ModifierManager
{
	public static var all:Map<String, Modifier> = new Map();
	public static var active:Map<String, Modifier> = new Map();
	static var initialized:Bool = false;

	public static function init():Void
	{
		if (initialized) return;
		initialized = true;

		all = new Map();
		active = new Map();

		Modifiers.registerAll();
	}

	public static function register(mod:Modifier):Void
	{
		if (all.exists(mod.id))
		{
			trace('[ModifierManager] modifier "${mod.id}" already registered, overwriting.', "WARNING");
		}
		all.set(mod.id, mod);
	}

	public static function get(id:String):Modifier return all.get(id);

	public static function exists(id:String):Bool return all.exists(id);

	public static function isActive(id:String):Bool return active.exists(id);

	/**
	 * Returns the list of currently-active modifiers that conflict with the given id.
	 */
	public static function getBlockingModifiers(id:String):Array<Modifier>
	{
		var mod = all.get(id);
		if (mod == null) return [];

		var blockers:Array<Modifier> = [];

		for (activeMod in active)
		{
			if (activeMod.id == id) continue;

			var conflict = mod.conflicts.indexOf(activeMod.id) != -1 || activeMod.conflicts.indexOf(mod.id) != -1;

			if (conflict) blockers.push(activeMod);
		}

		return blockers;
	}

	public static function canActivate(id:String):Bool
	{
		if (!all.exists(id)) return false;
		return getBlockingModifiers(id).length == 0;
	}

	/**
	 * Attempts to activate a modifier.
	 * @param force If true, automatically deactivates any conflicting modifiers first.
	 * @param value Optional starting value for RANGE modifiers.
	 * @return true if the modifier ended up active, false otherwise (e.g. blocked without force).
	 */
	public static function activate(id:String, force:Bool = false, ?value:Float):Bool
	{
		var mod = all.get(id);
		if (mod == null)
		{
			trace('[ModifierManager] Tried to activate unknown modifier "$id"', "ERROR");
			return false;
		}

		if (mod.active)
		{
			if (value != null) setValue(id, value);
			return true;
		}

		var blockers = getBlockingModifiers(id);
		if (blockers.length > 0)
		{
			if (!force)
			{
				trace('[ModifierManager] "$id" blocked by: ' + blockers.map(m -> m.id).join(", "));
				return false;
			}

			for (blocker in blockers) deactivate(blocker.id);
		}

		if (value != null && mod.valueType == RANGE) mod.value = clampValue(mod, value);
		else if (mod.valueType == RANGE) mod.value = mod.defaultValue;

		mod.active = true;
		active.set(mod.id, mod);
		mod.onActivate();

		return true;
	}

	public static function deactivate(id:String):Void
	{
		var mod = all.get(id);
		if (mod == null || !mod.active) return;

		mod.active = false;
		active.remove(id);
		mod.onDeactivate();
	}

	public static function toggle(id:String, force:Bool = false):Bool
	{
		if (isActive(id))
		{
			deactivate(id);
			return false;
		}
		return activate(id, force);
	}

	public static function getValue(id:String):Float
	{
		var mod = all.get(id);
		if (mod == null || mod.valueType != RANGE) return 0;

		return mod.value;
	}

	public static function setValue(id:String, value:Float):Void
	{
		var mod = all.get(id);
		if (mod == null || mod.valueType != RANGE) return;

		mod.value = clampValue(mod, value);

		if (mod.active) mod.onValueChanged(mod.value);
	}

	static function clampValue(mod:Modifier, value:Float):Float
	{
		if (value < mod.minValue) return mod.minValue;
		if (value > mod.maxValue) return mod.maxValue;
		return value;
	}

	/**
	 * Deactivates every active modifier.
	 */
	public static function deactivateAll():Void
	{
		for (mod in active) deactivate(mod.id);
	}

	/**
	 * Returns ids of currently active modifiers.
	 */
	public static function getActiveIds():Array<String>
	{
		var ids:Array<String> = [];
		for (mod in active) ids.push(mod.id);
		return ids;
	}
}
