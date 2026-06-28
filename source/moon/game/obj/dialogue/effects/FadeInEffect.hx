package moon.game.obj.dialogue.effects;

class FadeInEffect extends TextEffect
{
	public function new(values:Dynamic) super(values);

	override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
	{
		sprite.alpha = Math.min(1.0, localTime / getValue("duration", 0.25, 0));
	}
}
