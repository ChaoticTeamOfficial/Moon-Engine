package moon.menus.obj.story;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

class StoryWeek extends FlxSpriteGroup
{
    public var weekId:String;
    public var weekDisplayName:String;
    public var weekColor:FlxColor;
    public var weekData:Week;

    public var text:FlxText;
    public var icon:MoonSprite;

    var fontSize:Int = 40;

    public function new(x:Float = 0, y:Float = 0, weekId:String = 'week1')
    {
        super(x, y);

        this.weekData = Week.get(weekId);
        this.weekId = weekId;
        this.weekDisplayName = weekData.displayName;
        this.weekColor = FlxColor.fromRGB(weekData.color[0], weekData.color[1], weekData.color[2]);

        text = new FlxText(0, 0, 0, weekDisplayName);
        text.setFormat(Paths.font('phantomuff/difficulty.ttf'), fontSize);
		text.color = weekColor;
		add(text);

        icon = new MoonSprite(text.width + 25, 0, Paths.image('menus/story/lock'));
        add(icon);
    }
}