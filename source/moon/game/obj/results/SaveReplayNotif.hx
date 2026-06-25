package moon.game.obj.results;

import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.addons.display.FlxRadialGauge;

class SaveReplayNotif extends FlxSpriteGroup
{
	public var parameters(default, set):ReplayNotifParams;
	public var bar:RoundBar;
	public var circle:FlxShapeCircle;
	public var text:FlxText;

	var bg:MoonSprite;
	var pie:FlxRadialGauge;

	public var onFinish:FlxSignal = new FlxSignal();

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		bg = new MoonSprite().makeGraphic(317, 69, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, bg.width, bg.height, 12, 12, 0xFF1b1b1b);
		add(bg);

		circle = new FlxShapeCircle(12, 12, 24, {
			thickness: 4,
			color: FlxColor.WHITE
		}, FlxColor.WHITE);
		add(circle);
		circle.antialiasing = false;

		var replayIcon = new MoonSprite(14, 14);
		replayIcon.frames = Tilemap.getAtlasFrames("mainUI");
		replayIcon.frame = Tilemap.getFrame('folder', 'mainUI');
		add(replayIcon);
		// replayIcon.setPosition(x + (circle.width - replayIcon.width) * 0.5, y + (circle.height - replayIcon.height) * 0.5);

		bar = new RoundBar(0, 0, LEFT_TO_RIGHT, 317, 5, null, null, 0, 100, false, 5);
		bar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.WHITE);
		add(bar);

		text = new FlxText(72, 0);
		text.setFormat(Paths.font('phantomuff/full.ttf'), 14, LEFT);
		text.antialiasing = true;
		text.fieldWidth = bg.width - 72;
		add(text);

		pie = new FlxRadialGauge();
		pie.makeShapeGraphic(CIRCLE, 20, 10, FlxColor.WHITE);
		pie.replaceColor(FlxColor.BLACK, 0x8AC5C4C4);
		pie.amount = 0;
		add(pie);

		alpha = 0.00001;
		allowHolding = true;
	}

	var twn:FlxTween;
	var held:Float = 0;
	var allowHolding = true;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (allowHolding)
		{
			if (FlxG.keys.pressed.TAB) held += elapsed;
			else
				held -= elapsed;

			if (held <= 0) held = 0;

			if (held >= 1)
			{
				allowHolding = false;
				pie.visible = false;
				onFinish.dispatch();
			}

			pie.amount = held;
			pie.alpha = 1;
		}
	}

	public function resetBar()
	{
		TweenUtils.cancelTwn(twn);
		bar.value = 101;
		bar.color = circle.color = parameters?.color ?? FlxColor.WHITE;
		text.text = parameters?.text ?? 'Text not found.';
		text.y = y + bg.height / 2 - text.height / 2;

		pie.x = x + bg.width + 16;
		pie.y = y + bg.height / 2 - pie.height / 2;

		bar.y = y + bg.height - 4;

		function doTheRest()
		{
			twn = FlxTween.tween(bar, {
				value: 0
			}, parameters?.duration ?? 5, {
				onComplete: _ ->
				{
					// aaaaa
					fade(false, null);
				}
			});
		}

		if (this.alpha < 1) fade(true, doTheRest);
		else
			doTheRest();
	}

	public function flash()
	{
		bg.brightness = 1;
		FlxTween.tween(bg, {
			brightness: 0
		}, 1);
	}

	function fade(fadeIn:Bool = false, onComplete:Void->Void) twn = FlxTween.tween(this, {
		alpha: fadeIn ? 1 : 0.000001
	}, 0.6, {
		onComplete: _ -> (onComplete != null) ? onComplete() : {
		}
	});

	@:noCompletion
	public function set_parameters(parameters:ReplayNotifParams):ReplayNotifParams
	{
		this.parameters = parameters;
		resetBar();
		return this.parameters;
	}
}

typedef ReplayNotifParams =
{
	var ?color:FlxColor;
	var text:String;
	var ?duration:Float;
};
