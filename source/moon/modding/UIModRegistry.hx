package moon.modding;

@:publicFields
// TODO: get this to work somewhere!
/**
 * A registry for moddable objects, mostly being used for UI stuff.
 */
class UIModRegistry
{
	static var elements:Map<String, FlxBasic> = [];
	static var groups:Map<String, FlxSpriteGroup> = [];

	/**
	 * Registers an object into the elements.
	 * @param id The identifier for getting this object.
	 * @param element The element itself.
	 */
	static function register(id:String, element:FlxBasic):Void
	{
		if (elements.exists(id)) trace('[UIMod] Overwriting registered element: $id', "WARNING");
		elements.set(id, element);

		if (Std.isOfType(element, FlxSpriteGroup)) groups.set(id, cast element);
	}

	/**
	 * Returns an FlxBasic by its id.
	 * @param id
	 */
	static function get(id:String):Null<FlxBasic> return elements.get(id);

	/**
	 * Returns a group by its id.
	 * @param id 
	 */
	static function getGroup(id:String):Null<FlxSpriteGroup> return groups.get(id);

	/**
	 * Returns a FlxObject by its id.
	 * @param id 
	 */
	static function getObject(id:String):Null<FlxObject>
	{
		final e = elements.get(id);
		return (e != null && Std.isOfType(e, FlxObject)) ? cast e : null;
	}

	static function clear():Void
	{
		elements.clear();
		groups.clear();
	}

	/** 
	 * Applies a layout descriptor.
	 */
	static function applyLayout(id:String, data:UILayoutData):Void
	{
		final obj = getObject(id);
		if (obj == null || !Std.isOfType(obj, FlxSprite)) return;

		final spr = cast(obj, FlxSprite);

		if (data.x != null) spr.x = data.x;
		if (data.y != null) spr.y = data.y;
		if (data.scale != null)
		{
			spr.scale.set(data.scale, data.scale);
			spr.updateHitbox();
		}
		if (data.alpha != null) spr.alpha = data.alpha;
		if (data.visible != null) spr.visible = data.visible;
		if (data.scrollFactor != null) spr.scrollFactor.set(data.scrollFactor[0] ?? 1, data.scrollFactor[1] ?? 1);
	}
}

typedef UILayoutData =
{
	var ?x:Float;
	var ?y:Float;
	var ?scale:Float;
	var ?alpha:Float;
	var ?visible:Bool;
	var ?scrollFactor:Array<Float>;
}
