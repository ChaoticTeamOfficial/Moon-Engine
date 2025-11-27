package moon.toolkit.level_editor;

import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteContainer;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import openfl.geom.ColorTransform;
import moon.toolkit.ui.*;

import moon.game.obj.Song;
import moon.game.obj.notes.*;
import moon.backend.data.Chart.NoteStruct;

//TODO
interface IUndoAction {
    function undo(action:String):Void;
    function redo(action:String):Void;
}