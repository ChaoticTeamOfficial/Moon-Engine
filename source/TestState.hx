package;

import moon.toolkit.ui.*;

using StringTools;

class TestState extends FlxState
{
	override public function create():Void
	{
		super.create();
		FlxG.cameras.bgColor = 0xFF2E2543;
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
	}
}
