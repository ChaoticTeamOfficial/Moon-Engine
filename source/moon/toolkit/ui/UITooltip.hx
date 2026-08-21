package moon.toolkit.ui;

/**
 * Small floating box that follows the mouse.
 */
class UITooltip extends FlxSpriteGroup
{
	public var maxWidth:Float = 280;
	public var offsetX:Float = 14;
	public var offsetY:Float = 18;

	var bg:FlxSprite;
	var label:FlxText;
	var _mp:FlxPoint = FlxPoint.get();
	var _hasContent:Bool = false;

	static inline final PAD:Float = 8;
	static inline final RADIUS:Float = 8;

	public function new()
	{
		super();

		bg = new FlxSprite();
		bg.makeGraphic(1, 1, FlxColor.WHITE);
		bg.color = 0xE018181C;
		bg.active = false;
		add(bg);

		label = new FlxText(PAD, PAD, 0, '', UITheme.FONT_SIZE);
		label.font = UITheme.FONT;
		label.color = UITheme.TEXT_COLOR;
		label.antialiasing = UITheme.FONT_ANTIALIASING;
		label.active = false;
		add(label);

		visible = false;
		active = true;
	}

	/**
	 * Show the tooltip with the given text (supports multiline via `\n`).
	 */
	public function show(content:String):Void
	{
		if (content == null || content.length == 0)
		{
			hide();
			return;
		}

		label.fieldWidth = 0;
		label.text = content;
		label.updateHitbox();

		if (label.width > maxWidth - PAD * 2)
		{
			label.fieldWidth = maxWidth - PAD * 2;
			label.text = content;
			label.updateHitbox();
		}

		final bw = Std.int(Math.ceil(label.width + PAD * 2));
		final bh = Std.int(Math.ceil(label.height + PAD * 2));
		bg.loadGraphic(RoundedRectCache.get(bw, bh, RADIUS, FlxColor.WHITE));
		bg.color = 0xE018181C;
		bg.setGraphicSize(bw, bh);
		bg.updateHitbox();

		label.setPosition(PAD, PAD);
		_hasContent = true;
		visible = true;
	}

	public function hide():Void
	{
		_hasContent = false;
		visible = false;
		label.text = '';
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!_hasContent || !visible) return;

		FlxG.mouse.getViewPosition(camera, _mp);

		var tx = _mp.x + offsetX;
		var ty = _mp.y + offsetY;

		if (tx + bg.width > FlxG.width - 4) tx = _mp.x - bg.width - 8;
		if (ty + bg.height > FlxG.height - 4) ty = _mp.y - bg.height - 8;
		if (tx < 4) tx = 4;
		if (ty < 4) ty = 4;

		// setPosition(tx, ty);
		bg.setPosition(tx, ty);
		label.x = bg.x + bg.width / 2 - label.width / 2;
		label.y = bg.y + bg.height / 2 - label.height / 2;
	}

	override public function destroy():Void
	{
		_mp.put();
		super.destroy();
	}
}
