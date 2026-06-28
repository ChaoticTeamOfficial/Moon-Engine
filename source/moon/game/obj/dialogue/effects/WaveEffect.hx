package moon.game.obj.dialogue.effects;

/**
 * Waves characters up and down sinusoidally.
 */
class WaveEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
	{
		sprite.y += Math.sin(
			(globalTime * getValue("frequency", 3.0, 1) * Math.PI * 2) - (sprite.x * getValue("delay", 0.08, 2))
		) * getValue("intensity", 8.0, 0);
	}
}
