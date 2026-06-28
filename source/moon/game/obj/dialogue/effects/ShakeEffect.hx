package moon.game.obj.dialogue.effects;

/**
 * Randomly shakes characters each frame.
 */
class ShakeEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
	{
		final intensity:Float = getValue("intensity", 3.0, 0);
		sprite.x += (Math.random() * 2 - 1) * intensity;
		sprite.y += (Math.random() * 2 - 1) * intensity;
	}
}
