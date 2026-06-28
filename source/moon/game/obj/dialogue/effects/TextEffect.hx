package moon.game.obj.dialogue.effects;

using StringTools;

/**
 * Base class for text effects.
 */
class TextEffect
{
	public var values:Dynamic;

	public function new(values:Dynamic) this.values = values;

	/** 
	 * Called once when building the glyph. 
	 */
	public function applyStatic(sprite:FlxText):Void
	{
	}

	/**
	 * Called every frame for visible characters.
	 * @param sprite  The per-character FlxText (position is reset to baseX/baseY before this).
	 * @param elapsed Seconds since last frame.
	 * @param globalTime Seconds since game start.
	 * @param localTime  Seconds since this character was revealed.
	 */
	public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
	{
	}

	/**
	 * Safely read a named field, array index, or return a default.
	 */
	function getValue<T>(name:String, def:T, ?index:Int = 0):T
	{
		if (values == null) return def;
		var field:Dynamic = Reflect.field(values, name);
		if (field != null) return cast field;
		if (Std.isOfType(values, Array))
		{
			var arr:Array<Dynamic> = cast values;
			if (index >= 0 && index < arr.length && arr[index] != null) return cast arr[index];
		}
		return def;
	}
}
