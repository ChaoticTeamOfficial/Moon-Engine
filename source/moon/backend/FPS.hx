package moon.backend;

import haxe.Timer;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

using flixel.util.FlxStringUtil;

@:dox(hide)
class FPS extends TextField
{
    var times:Array<Float> = [];
	var memPeak:UInt = 0;

	public function new(x:Float, y:Float)
	{
		super();

		autoSize = LEFT;
		selectable = false;
		this.x = x;
		this.y = x;

		defaultTextFormat = new TextFormat(Paths.font('monsterrat/Montserrat-BoldItalic.ttf'), 20, 0xEBEBEB);
		text = "";

		addEventListener(Event.ENTER_FRAME, update);
	}

	function update(_:Event)
	{
		var now:Float = Timer.stamp();
		times.push(now);
		while (times[0] < now - 1)
			times.shift();

		var mem = System.totalMemory;
		if (mem > memPeak)
			memPeak = mem;

		if (visible)
			text = (times.length + " FPS\n");
	}
}