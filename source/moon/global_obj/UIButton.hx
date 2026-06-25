package moon.global_obj;

@:publicFields
class UIButton extends FlxSpriteGroup
{
	var button:MoonSprite;
	var dText:FlxText;
	var text:String;
	var selected(default, set):Bool;

	public function new(?x:Float = 0, ?y:Float = 0, text:String = 'Hello, World!')
	{
		super(x, y);
		this.text = text;

		// TODO: find a way to use FlxScaledSliceSprite
		/**
				 		final slice = new FlxRect(21, 23, 202, 20);
			button = new FlxScaledSliceSprite(Paths.image('toolkit/ui/uiStuff'), slice, 242, 67);
		 */

		button = new MoonSprite();
		button.frames = Tilemap.getAtlasFrames("mainUI");
		button.frame = Tilemap.getFrame('button-regular', 'mainUI');
		add(button);
		button.updateHitbox();
		button.active = false;

		dText = new FlxText();
		dText.text = text;
		dText.setFormat(Paths.font('phantomuff/full.ttf'), 20, CENTER);
		dText.antialiasing = button.antialiasing = true;
		add(dText);

		button.setPosition(x, y);
		dText.x = x + (button.width - dText.width) / 2;
		dText.y = y + (button.height - dText.height) / 2;

		selected = false;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	var thisTwn:FlxTween;

	function set_selected(selected:Bool):Bool
	{
		this.selected = selected;
		final thing = (selected) ? 'selected' : 'regular';
		button.frame = Tilemap.getFrame('button-$thing', 'mainUI');
		dText.color = selected ? FlxColor.BLACK : FlxColor.WHITE;
		TweenUtils.cancelTwn(thisTwn);

		if (selected)
		{
			scale.set(0.8, 0.8);
			thisTwn = FlxTween.tween(this, {
				"scale.x": 1.12,
				"scale.y": 1.12
			}, 0.15, {
				ease: FlxEase.elasticOut
			});
		}
		else
			thisTwn = FlxTween.tween(this, {
				"scale.x": 1,
				"scale.y": 1
			}, 0.2, {
				ease: FlxEase.expoOut
			});

		return selected;
	}
}
