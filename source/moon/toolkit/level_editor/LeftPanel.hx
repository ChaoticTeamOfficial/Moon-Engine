package moon.toolkit.level_editor;

// atp everything here are flxspritegroups '-'
class LeftPanel extends FlxSpriteGroup
{
	var bg:MoonSprite;
	public function new()
	{
		super();

		bg = new MoonSprite().makeGraphic(80, FlxG.height, 0xFF080808);
		add(bg);
	}
}