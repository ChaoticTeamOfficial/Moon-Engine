package moon.toolkit.offset;

import haxe.Json;
import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import openfl.geom.ColorTransform;
import moon.toolkit.ui.*;
import moon.game.obj.*;
import moon.game.*;
import moon.game.obj.notes.*;
import moon.backend.data.Chart.NoteStruct;
import moon.menus.MainMenu;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class OffsetEditor extends FlxState
{
	override public function create():Void
	{
		super.create();
	}
}
