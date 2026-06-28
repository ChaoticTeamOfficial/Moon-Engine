package moon.game.obj.dialogue.effects;

import flixel.util.FlxColor;
import flixel.text.FlxText;

/**
 * Bakes an outline onto the character.
 */
class OutlineEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyStatic(sprite:FlxText):Void
	{
		sprite.setBorderStyle(FlxTextBorderStyle.OUTLINE, parseColor(getValue("color", "#000000", 1)), getValue("size", 1, 0));
	}

	// TODO: put this on the base text effect class...

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
