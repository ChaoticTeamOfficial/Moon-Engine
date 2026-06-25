package moon.backend;

import haxe.Timer;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

using flixel.util.FlxStringUtil;

@:dox(hide)
class BetaBuild extends TextField
{
	public function new(x:Float, y:Float)
	{
		super();

		autoSize = LEFT;
		selectable = false;
		this.x = x;
		this.y = x;

		defaultTextFormat = new TextFormat(Paths.font('monsterrat/Montserrat-BoldItalic.ttf'), 20, 0xEBEBEB);
		text = 'INDEV V.${Constants.INDEV_VERSION}';
		alpha = 0.5;
		visible = true;
	}
}
