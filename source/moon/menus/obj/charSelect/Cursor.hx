package moon.menus.obj.charSelect;

import flixel.group.FlxGroup.FlxTypedGroup;

class Cursor extends FlxTypedGroup<MoonSprite>
{
	private final colors = [FlxColor.BLUE, FlxColor.CYAN, FlxColor.YELLOW];
    private final alpha = [0.6, 0.8, 1.0];
    private final speed = [6, 9, 16];

    public function new()
    {
        super();
        initSprites(Paths.image('menus/charSelect/box'));
    }

    private function initSprites(graphic:flixel.graphics.FlxGraphic):Void
    {
        for (i in 0...3)
        {
            var spr = new MoonSprite().loadGraphic(graphic);
            spr.screenCenter();
            spr.color = colors[i];
            spr.alpha = alpha[i];
            if (i < 2) spr.blend = ADD;

            add(spr);
        }
    }

    public function follow(x:Float, y:Float, elapsed:Float):Void
    {
        for (i in 0...members.length)
        {
            members[i].setPosition(
                l(members[i].x, x - members[i].width / 2, elapsed * speed[i]),
                l(members[i].y, y - members[i].height / 2, elapsed * speed[i])
            );
        }
    }

    private function l(val1:Float, val2:Float, ease:Float):Float
        return FlxMath.lerp(val1, val2, ease);
}