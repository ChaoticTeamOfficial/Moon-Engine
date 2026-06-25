package moon.game.obj;

import flixel.graphics.FlxGraphic;

class HealthIcon extends MoonSprite
{
	public var icon(default, set):String;

	public function new()
	{
		super();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	/**
	 * Will update the icon's framed based on the given health.
	 * @param health the health value.
	 */
	public dynamic function updateAnim(health:Float) animation.curAnim.curFrame = (health < 20) ? 1 : 0;

	@:noCompletion
	public function set_icon(val:String)
	{
		final char = (Paths.exists('characters/$val/icon.png')) ? val : 'asmile-erect';
		this.icon = char;

		centerAnimations = true;

		final graphic:FlxGraphic = Paths.image('$char/icon', 'characters');
		loadGraphic(graphic, true, Std.int(graphic.width / 2), Std.int(graphic.height));

		animation.add('icon', [0, 1], 0, false);
		playAnim('icon');
		scrollFactor.set();

		updateHitbox();
		return val;
	}
}
