package moon.toolkit.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;

/**
 * Generates rounded-rect textures ONCE per unique
 * (width, height, radius, color, borderColor, borderThickness) combo, then
 * hands back the cached FlxGraphic on every subsequent call.
 */
class RoundedRectCache
{
	static var cache:Map<String, FlxGraphic> = new Map();

	public static function get(width:Int, height:Int, radius:Float, color:FlxColor, ?borderColor:FlxColor, borderThickness:Float = 0):FlxGraphic
	{
		width = Std.int(Math.max(1, width));
		height = Std.int(Math.max(1, height));

		final key = 'rr_${width}_${height}_${radius}_${color}_${borderColor}_${borderThickness}';

		final cached = cache.get(key);
		if (cached != null && isAlive(cached)) return cached;
		if (cached != null) cache.remove(key);

		final existing = FlxG.bitmap.get(key);
		if (existing != null && isAlive(existing))
		{
			existing.destroyOnNoUse = false;
			cache.set(key, existing);
			return existing;
		}

		var stamp = new FlxSprite();
		stamp.pixels = new BitmapData(width, height, true, FlxColor.TRANSPARENT);

		if (borderColor != null && borderThickness > 0)
		{
			FlxSpriteUtil.drawRoundRect(stamp, 0, 0, width, height, radius, radius, color, {
				color: borderColor,
				thickness: borderThickness
			});
		}
		else
			FlxSpriteUtil.drawRoundRect(stamp, 0, 0, width, height, radius, radius, color);

		var graphic = FlxG.bitmap.add(stamp.pixels, false, key);
		graphic.destroyOnNoUse = false;
		cache.set(key, graphic);
		return graphic;
	}

	static inline function isAlive(g:FlxGraphic):Bool return g != null && g.bitmap != null;

	static var solidPixel:FlxGraphic;

	/**
	 * A single shared 1x1 white pixel graphic, meant to be tinted via
	 * `sprite.color` and sized via `sprite.scale`...
	 */
	public static function getSolidPixel():FlxGraphic
	{
		if (solidPixel != null && isAlive(solidPixel)) return solidPixel;

		var stamp = new FlxSprite();
		stamp.pixels = new BitmapData(1, 1, true, FlxColor.WHITE);
		solidPixel = FlxG.bitmap.add(stamp.pixels, false, "ui_solid_pixel_1x1");
		solidPixel.destroyOnNoUse = false;
		return solidPixel;
	}

	public static function clear():Void
	{
		for (g in cache) if (isAlive(g)) g.destroyOnNoUse = true;
		if (solidPixel != null && isAlive(solidPixel)) solidPixel.destroyOnNoUse = true;

		cache.clear();
	}
}
