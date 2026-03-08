package moon.ui;

class DefaultVideoUI extends FlxGroup
{
	var bg:MoonSprite = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
	var topB:MoonSprite = new MoonSprite(0, -400).makeGraphic(FlxG.width + 69, 232, FlxColor.BLACK);
	var bottomB:MoonSprite = new MoonSprite(0, FlxG.height + 64).makeGraphic(FlxG.width + 69, 232, FlxColor.BLACK);

	public var paused(default, set):Bool = false;
	public function new()
	{
		super();
		bg.alpha = 0;
		add(bg);

		topB.angle = bottomB.angle = -3;

		topB.screenCenter(X);
		bottomB.screenCenter(X);
		add(topB);
		add(bottomB);

		topB.antialiasing = bottomB.antialiasing = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		topB.y = FlxMath.lerp(topB.y, paused ? 96 - topB.height : -400, elapsed * 8);
		bottomB.y = FlxMath.lerp(bottomB.y, paused ? FlxG.height - 96 : FlxG.height + 64, elapsed * 8);
	}

	var bgTwn:FlxTween;
	@:noCompletion public function set_paused(paused:Bool):Bool
	{
		this.paused = paused;
		MoonUtils.cancelActiveTwn(bgTwn);
		bgTwn = FlxTween.tween(bg, {alpha: paused ? 0.8 : 0}, 0.08);

		return this.paused;
	}
}