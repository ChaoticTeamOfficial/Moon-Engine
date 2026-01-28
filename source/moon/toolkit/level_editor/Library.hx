package moon.toolkit.level_editor;

import lime.app.Future;

class Library extends FlxGroup
{
	public var bg:MoonSprite;
	public var bgCopy:MoonSprite;
	public var bg2:MoonSprite;
	public var tabIndicator:FlxText;

	public var editing:Bool = false;
	//public var accessing(default, set):String = 'Notes';
	public function new()
	{
		super();

		final bgSize:FlxPoint = FlxPoint.get(532, 263);
		bg = new MoonSprite(116, FlxG.height - 300).makeGraphic(Std.int(bgSize.x), Std.int(bgSize.y), FlxColor.TRANSPARENT);
		add(bg);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, Std.int(bgSize.x), Std.int(bgSize.y), 24, 24, FlxColor.BLACK);
		bg.antialiasing = true;
		bg.alpha = 0.4;

		bgCopy = new MoonSprite(bg.x, bg.y).makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.TRANSPARENT);
		bgCopy.shader = new BorderGlowShader();
		add(bgCopy);
		bgCopy.blend = ADD;

		bg2 = new MoonSprite().makeGraphic(Std.int(bg.width - 32), Std.int(bg.height / 1.5 + 16), FlxColor.TRANSPARENT);
		add(bg2);
		FlxSpriteUtil.drawRoundRect(bg2, 0, 0, bg2.width, bg2.height, 24, 24, FlxColor.BLACK);
		bg2.antialiasing = true;
		bg2.alpha = 0.3;

		bg2.setPosition(bg.x + bg.width / 2 - bg2.width / 2, bg.y + bg.height / 2 - bg2.height / 2 + 16);

        var icon = new MoonSprite(bg.x, bg.y - 6);
        icon.frames = Tilemap.getAtlasFrames("btnIcons");
        icon.frame = Tilemap.getFrame('library', 'btnIcons');
        icon.active = false;
        icon.antialiasing = true;
        icon.setGraphicSize(32, 32);
        add(icon);

        tabIndicator = new FlxText(bg.x + (48), bg.y + 16);
        add(tabIndicator);
        tabIndicator.setFormat(Paths.font('Inconsolata-Black.ttf'), 16, LEFT);
        tabIndicator.text = 'Loading...';
        tabIndicator.antialiasing = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if(bgCopy.shader != null)
		{
			var shader:BorderGlowShader = cast bgCopy.shader;
		    shader.update(elapsed);

		    //shader.enabled = editing;
		    shader.enabled = FlxG.keys.pressed.EIGHT;
		}
	}

	public function updateTab()
	{
		tabIndicator.text = 'Library // ${LevelEditor.instance.curType}';
	}
}