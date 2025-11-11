package moon.menus.obj.main;

import flixel.math.FlxMath;
import moon.game.obj.*;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

class MenuItem extends FlxSpriteGroup
{
	public var selected(default, set):Bool = false;

	var background:MoonSprite;
	var label:FlxText;

	public var targetX:Float = 0.0;
	public var targetY:Float = 0.0;
	public var targetAlpha:Float = 1.0;
	public var targetScale:Float = 1.0;
    public function new(?x:Float = 0, ?y:Float = 0, name:String = 'Hello.')
    {
        super(x, y);

        background = new MoonSprite().makeGraphic(316, 32, FlxColor.WHITE);
        add(background);

        label = new FlxText(5, -32);
        label.setFormat(Paths.font('phantomuff/difficulty.ttf'), 48, CENTER);
        label.text = name;
        label.setBorderStyle(SHADOW, FlxColor.PURPLE, 2);
        add(label);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }

    @:noCompletion public function set_selected(value:Bool):Bool
    {
        this.selected = value;
        background.color = (selected) ? FlxColor.WHITE : FlxColor.BLACK;
        label.color = (selected) ? FlxColor.BLACK : FlxColor.WHITE;
        return selected;
    }
}
