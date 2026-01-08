package moon.toolkit.level_editor;

class Library extends FlxGroup
{
	public var bg:MoonSprite;
	public var bg2:MoonSprite;
	public function new()
	{
		super();

		final bgSize:FlxPoint = FlxPoint.get(532, 263);
		bg = new MoonSprite(116, FlxG.height - 300).makeGraphic(Std.int(bgSize.x), Std.int(bgSize.y), FlxColor.TRANSPARENT);
		add(bg);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, Std.int(bgSize.x), Std.int(bgSize.y), 48, 48, FlxColor.BLACK);
		bg.antialiasing = true;
		bg.alpha = 0.4;

		bg2 = new MoonSprite().makeGraphic(Std.int(bg.width - 32), Std.int(bg.height / 1.5 + 16), FlxColor.TRANSPARENT);
		add(bg2);
		FlxSpriteUtil.drawRoundRect(bg2, 0, 0, bg2.width, bg2.height, 48, 48, FlxColor.BLACK);
		bg2.antialiasing = true;
		bg2.alpha = 0.3;

		bg2.setPosition(bg.x + bg.width / 2 - bg2.width / 2, bg.y + bg.height / 2 - bg2.height / 2 + 16);
	}
}