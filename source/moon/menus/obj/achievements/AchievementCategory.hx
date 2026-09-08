package moon.menus.obj.achievements;

import flixel.group.FlxSpriteGroup;
import moon.dependency.user.MoonAchievements;

class AchievementCategory extends FlxSpriteGroup
{
	static var rowSize:Int = 9; // how many achievements can be side by side
	static var barSize:Int = 838; // full separator bar width

	public var achievementList:Array<AchievementIcon> = [];

	public function new(x:Float, y:Float, name:String, achievements:Array<AchievementData>)
	{
		super(x, y);

		var title = new FlxText(0, 0, 0, name);
		title.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.BLACK, LEFT);
		add(title);

		var bar = new MoonSprite().makeGraphic(Std.int(barSize - title.width), 3, FlxColor.BLACK);
		bar.x += title.width + 8;
		bar.y += 8;
		add(bar);

		for (x in 0...achievements.length)
		{
			var icon = new AchievementIcon(achievements[x]);
			icon.x += 8 + 96 * x % rowSize;
			icon.y += 32 + 96 * Math.floor(x / rowSize);
			icon.animation.frameIndex = icon.isUnlocked ? 0 : 1;
			icon.category = name;
			add(icon);

			achievementList.push(icon);
		}
	}
}
