package moon.game.obj.dialogue.effects;

/**
 * Characters spring upward when they are revealed, then settle.
 */
class BounceEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
	{
		final height:Float = getValue("height", 12.0, 0);
		final duration:Float = getValue("duration", 0.35, 1);
		final stiffness:Float = getValue("stiffness", 10.0, 2);

		if (localTime > duration * 2) return;

		final decay = Math.exp(-stiffness * localTime);
		final osc = Math.sin(Math.PI * localTime / duration);
		sprite.y -= height * decay * osc;
	}
}
