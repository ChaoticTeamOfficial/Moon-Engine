package moon.game.obj.dialogue.effects;

import flixel.util.FlxColor;

/**
 * Cycles each character through the hue wheel continuously.
 */
class RainbowEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
	{
		final hue:Float = ((globalTime * getValue("speed", 0.5, 0) * 360) + sprite.x * getValue("spread", 30.0, 1)) % 360;
		sprite.color = FlxColor.fromHSB(hue, 1.0, 1.0);
	}
}
