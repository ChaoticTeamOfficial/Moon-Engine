package moon.toolkit.ui;

import flixel.addons.display.FlxSliceSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import moon.backend.Paths;
import openfl.display.BitmapData;

/**
 * Toolkit for the round rect thing.
 */
class RoundedRectCache
{
	static inline var SLICE = 8;

	public static function create(width:Float, height:Float, color:FlxColor = FlxColor.WHITE):FlxSliceSprite
	{
		final sprite = new FlxSliceSprite(Paths.image('toolkit/ui/button'), new FlxRect(SLICE, SLICE, 32 - SLICE * 2, 32 - SLICE * 2), width, height);
		sprite.stretchTop = sprite.stretchBottom = sprite.stretchLeft = sprite.stretchRight = sprite.stretchCenter = true;
		sprite.color = color;
		sprite.active = false;
		return sprite;
	}

	public static function resize(sprite:FlxSliceSprite, width:Float, height:Float):Void
	{
		sprite.width = width;
		sprite.height = height;
	}

	static var solidPixel:FlxGraphic;

	public static function getSolidPixel():FlxGraphic
	{
		if (solidPixel != null && solidPixel.bitmap != null) return solidPixel;

		solidPixel = FlxGraphic.fromBitmapData(new BitmapData(1, 1, true, FlxColor.WHITE), false, "ui_solid_pixel_1x1", false);
		solidPixel.destroyOnNoUse = false;
		return solidPixel;
	}

	public static function clear():Void
	{
		if (solidPixel != null && solidPixel.bitmap != null) solidPixel.destroyOnNoUse = true;
		solidPixel = null;
	}
}
