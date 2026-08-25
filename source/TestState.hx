package;

import moon.toolkit.ui.*;
import moon.game.submenus.*;

using StringTools;

class TestState extends FlxState
{
	override public function create():Void
	{
		super.create();
		FlxG.cameras.bgColor = 0xFF2E2543;
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		new FlxTimer().start(1, _ -> openSubState(new PauseMenu(FlxG.camera)));
	}
}
