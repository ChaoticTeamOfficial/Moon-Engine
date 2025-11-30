package moon.toolkit.level_editor;

import flixel.addons.display.shapes.FlxShapeCircle;

class Strums extends FlxSpriteGroup
{
	public function new(x:Float = 0, y:Float = 0, color:FlxColor = FlxColor.RED)
	{
		super(x, y);

		var line = new MoonSprite().makeGraphic(Std.int(LevelEditor.LANE_WIDTH * (LevelEditor.NUM_LANES + 1)), 2, color);
		add(line);

		var circle = new FlxShapeCircle(0, 0, 8, {thickness: 4, color: color}, color);
		add(circle);
		circle.antialiasing = false;
		circle.y = line.y + line.height / 2 - circle.height / 2;
		circle.x += line.width;
	}
}
