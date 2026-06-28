package moon.game.obj.dialogue.effects;

import flixel.util.FlxColor;
import flixel.text.FlxText;

/**
 * Bakes a drop-shadow onto the character.
 */
class ShadowEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyStatic(sprite:FlxText):Void sprite.setBorderStyle(
		FlxTextBorderStyle.SHADOW,
		parseColor(getValue("color", "#000000", 1)),
		getValue("size", 2, 0)
	);

	private function parseColor(val:Dynamic):FlxColor
	{
		if (Std.isOfType(val, Int)) return cast val;
		if (Std.isOfType(val, String))
		{
			var s:String = val;
			if (s.startsWith("#")) return FlxColor.fromString(s);
		}
		return FlxColor.BLACK;
	}
}
