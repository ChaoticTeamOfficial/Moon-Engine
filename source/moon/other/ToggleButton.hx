package moon.other;

import flixel.FlxG;
import flixel.util.FlxColor;

class ToggleButton extends MoonSprite
{
	public var callback:Void->Void;
	public var icon:MoonSprite;
	public var isPressed:Bool = false;
	public var selected:Bool = false;

	/**
	 * @param x      X position of the button
	 * @param y      Y position of the button
	 * @param width  Width of the button
	 * @param height Height of the button
	 * @param color  Fill color of the button
	 * @param iconPath Asset path to the icon graphic
	 * @param callback Function to call when button is clicked
	 */
	public function new(x:Float, y:Float, width:Int, height:Int, color:FlxColor, iconPath:Dynamic, callback:Void->Void)
	{
		super(x, y);
		makeGraphic(width, height, color);

		icon = new MoonSprite();
		icon.loadGraphic(iconPath);
		icon.x = x + (width - icon.width) / 2;
		icon.y = y + (height - icon.height) / 2;

		this.callback = callback;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.mouse.overlaps(this) && active)
		{
			if (FlxG.mouse.justPressed) isPressed = true;

			if (isPressed && FlxG.mouse.justReleased)
			{
				isPressed = false;
				callback();
			}
		}

		final a = (selected) ? 1 : 0.8;
		scale.set(a, a);
		icon.alpha = alpha = a;
		icon.scale.x = scale.x;
		icon.scale.y = scale.y;
	}
}
