package moon.game.obj.dialogue.effects;

using StringTools;

/**
 * Base class for text effects. Effects can be static (applied once at creation) or dynamic (applied every frame).
 */
class TextEffect
{
    public var values:Dynamic;
    public function new(values:Dynamic) this.values = values;
	
	/**
     * Apply static modifications to the sprite.
     * Called once when creating the character sprite.
     */
    public function applyStatic(sprite:FlxText):Void {}
	
	/**
     * Apply dynamic modifications to the sprite.
     * Called every frame for visible characters.
     * @param sprite The character sprite to modify.
     * @param elapsed Time since last frame.
     * @param globalTime Current global time.
     * @param localTime Time since the character was revealed.
     */
    public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void {}

    /**
     * Safely returns a value from `values`.
     * Works with any objects, having a callback if none.
     *
     * @param name field name when `values` is an object
     * @param def default value if not found
     * @param index optional index when `values` is an Array
     */
    function getValue<T>(name:String, def:T, ?index:Int = 0):T {
        if (values == null)
            return def;

        // try object lookup
        var field:Dynamic = Reflect.field(values, name);
        if (field != null)
            return cast field;

        // try array lookup
        if (Std.isOfType(values, Array)) {
            var arr:Array<Dynamic> = cast values;
            if (index >= 0 && index < arr.length && arr[index] != null)
                return cast arr[index];
        }

        return def;
    }
}