package moon.backend.gameplay.modifiers;

enum ModifierCategory
{
	ACCURACY;
	SPEED;
	NOTE_BEHAVIOR;
	VISIBILITY;
	HEALTH;
	MISC;
}

enum ModifierValueType
{
	TOGGLE;
	RANGE;
}

class Modifier
{
	/**
	 * The modifier's identifier.
	 */
	public var id:String;

	/**
	 * The modifier's display name.
	 */
	public var name:String;

	/**
	 * The modifier's description.
	 */
	public var description:String;

	/**
	 * The category in which this modifier belongs to.
	 */
	public var category:ModifierCategory;

	/**
	 * The modifier's value type, which displays and has a different value based on what it is.
	 */
	public var valueType:ModifierValueType;

	public var minValue:Float = 0;
	public var maxValue:Float = 1;
	public var defaultValue:Float = 1;
	public var value:Float = 1;

	/**
	 * A list of modifiers which when active will disable and lock this one.
	 */
	public var conflicts:Array<String> = [];

	public var active:Bool = false;

	public function new(id:String, name:String, description:String, category:ModifierCategory, ?valueType:ModifierValueType, ?conflicts:Array<String>)
	{
		this.id = id;
		this.name = name;
		this.description = description;
		this.category = category;
		this.valueType = valueType ?? TOGGLE;
		this.conflicts = conflicts ?? [];
	}

	/**
	 * Called right after this modifier becomes active.
	 */
	public dynamic function onActivate():Void
	{
	}

	/**
	 * Called right after this modifier becomes inactive.
	 */
	public dynamic function onDeactivate():Void
	{
	}

	/**
	 * Called whenever `value` changes on a RANGE modifier while it's active
	 */
	public dynamic function onValueChanged(newValue:Float):Void
	{
	}
}
