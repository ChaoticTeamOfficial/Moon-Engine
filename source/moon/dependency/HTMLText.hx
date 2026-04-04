package moon.dependency;

import flixel.text.*;

/**
 * A slightly modified `FlxText` specifically for HTML-like usage.
 */
class HTMLText extends FlxText
{
	public function new(x:Float = 0, y:Float = 0, size:Int = 24)
	{
		super(x, y, 0, '', size);
		this.alignment = CENTER;
	}

	override function set_text(Text:String):String
	{
		text = Text;
		if (textField != null)
		{
			final ot:String = textField.htmlText;
			textField.htmlText = Text;
			_regen = (textField.htmlText != ot) || _regen;
		}
		return Text;
	}

	override function applyFormats(_:openfl.text.TextFormat, __:Bool = false):Void
	{
		// this shouldn't get called because it messes up with htmlText.
	}
}