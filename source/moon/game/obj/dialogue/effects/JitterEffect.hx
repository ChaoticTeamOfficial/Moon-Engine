package moon.game.obj.dialogue.effects;

/**
 * High-frequency tiny positional jitter.
 */
class JitterEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
	{
		final intensity:Float = getValue("intensity", 1.5, 0);

		final t = globalTime * getValue("frequency", 20.0, 1) * Math.PI * 2;

		sprite.x += Math.sin(t + sprite.x) * intensity;
		sprite.y += Math.cos(t * 1.3 + sprite.x * 2) * intensity;
	}
}
