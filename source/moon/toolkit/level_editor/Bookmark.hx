package moon.toolkit.level_editor;

import flixel.addons.display.shapes.FlxShapeCircle;

class Bookmark extends FlxSpriteGroup
{
    public var text:String = 'Lorem ipsum dolor sit amet...';
    public var col:FlxColor;
    public function new(x:Float = 0, y:Float = 0, size:Int = 32)
    {
        super(x, y);

        final colors = [
            0xFFfc0349, 0xff03f4fc, 0xfffcba03, 0xff03fc88, 0xff3dfc03, 0xff7703fc,
            0xfff403fc, 0xff2b1f42, 0xff505050
        ];
        col = colors[FlxG.random.int(0, colors.length - 1)];
        
        var circle = new FlxShapeCircle(0, 0, size, {thickness: 1, color: col}, col);
		add(circle);
		circle.antialiasing = true;

        var cutie = new MoonSprite().loadGraphic(Paths.image('toolkit/level-editor/bookmark'));
        cutie.setGraphicSize(size, size);
        cutie.updateHitbox();
        add(cutie);
        cutie.setPosition(x + circle.width / 2 - cutie.width / 2, y + circle.height / 2 - cutie.height / 2);
    }
}