package moon.toolkit.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.FlxObject;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.math.FlxRect;
import openfl.geom.Rectangle;

/**
 * A UI Popup. :D
 */
class Popup extends FlxSpriteGroup
{
	public var overlay:FlxSprite;
	public var windowBg:FlxUI9SliceSprite;

	/**
	 * Creates a new popup window.
	 * @param width The width of the popup window.
	 * @param height The height of the popup window.
	 */
	public function new(width:Int, height:Int)
	{
		super();

		// LOL i made this a flxspritegroup but didn't really add anything else to it XD
		// I'll leave it like this until I decide what I'm going to do.
		final slice9:Array<Int> = [32, 32, 96, 96];
		windowBg = new FlxUI9SliceSprite(0, 0, Paths.image('toolkit/ui/popup'), new Rectangle(0, 0, 128, 128), slice9);
		add(windowBg);
		windowBg.resize(width, height);
	}
}
