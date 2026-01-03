package moon.toolkit.level_editor;

import moon.backend.gameplay.InputHandler;
import flixel.util.FlxColor;
import flixel.FlxG;
import moon.game.obj.notes.Strumline;
import flixel.group.FlxSpriteGroup;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;

class Miniplayer extends FlxSpriteGroup
{
    public function new(?x:Float = 0, ?y:Float = 0, chartEditor:LevelEditor)
    {
        super(x, y);

        // size: 596x387
        // gameplay size: 582x328
    }
}