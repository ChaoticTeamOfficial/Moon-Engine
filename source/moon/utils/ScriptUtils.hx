package moon.utils;

@:publicFields

/**
 * This class will hold utilities for scripts.
 * Basically, lets you access some stuff that aren't available for scripts but are important!
 * If there's anything missing here, feel free to contribute by either messaging me or making a pull request.
 */
class ScriptUtils
{
    // --- FlxPoint stuff. ---

    /**
     * Creates a new FlxPoint (or reuses one from the pool).
     */
    public static function point(x:Float = 0, y:Float = 0)
        return flixel.math.FlxPoint.get(x, y);

    /**
     * Creates a FlxPoint from polar coordinates.
     */
    public static function pointPolar(angle:Float, length:Float = 1)
        return flixel.math.FlxPoint.get(Math.cos(angle) * length, Math.sin(angle) * length);
}