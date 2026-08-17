package moon.toolkit.ui;

import moon.toolkit.ui.UIEditFocus.ITextEditable;
import moon.toolkit.ui.UIEditFocus.IEditorChromeHideable;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.events.KeyboardEvent;
import openfl.events.TextEvent;

using StringTools;

/**
 * A simple and nice looking slider. Click the value text to type an exact
 * number instead of dragging/scrolling.
 */
class UISlider extends UIComponent implements ITextEditable implements IEditorChromeHideable
{
	public var value(default, set):Float;
	public var min:Float;
	public var max:Float;
	public var onChange:Float->Void;
	public var formatter:Float->String;

	var track:FlxSprite;
	var fill:FlxSprite;
	var handle:FlxSprite;
	var valueText:FlxText;
	var dragging:Bool = false;
	var trackWidth:Float = 90;
	var step:Float;
	var _mp:flixel.math.FlxPoint = flixel.math.FlxPoint.get();
	var editBox:FlxSprite;
	var editCaret:FlxSprite;
	var editing:Bool = false;
	var editText:String = "";
	var caretTimer:Float = 0;
	var caretVisible:Bool = true;

	static inline var TRACK_HEIGHT:Float = 6;
	static inline var HANDLE_SIZE:Float = 16;

	public function new(x:Float, y:Float, width:Float, labelText:String, min:Float, max:Float, defaultValue:Float, step:Float = 0.1, ?iconGraphic:Dynamic)
	{
		super(x, y, width, labelText, iconGraphic);
		this.min = min;
		this.max = max;
		this.step = step;

		var startX = rowWidth - UITheme.PADDING - (trackWidth + 10 + 50);

		track = new FlxSprite(startX, 0);
		track.loadGraphic(RoundedRectCache.get(Std.int(trackWidth), Std.int(TRACK_HEIGHT), TRACK_HEIGHT / 2, FlxColor.WHITE));
		track.color = UITheme.CONTROL_BG_ACTIVE;
		track.y = (rowHeight - TRACK_HEIGHT) / 2;
		add(track);

		fill = new FlxSprite(track.x, track.y);
		fill.loadGraphic(RoundedRectCache.getSolidPixel());
		fill.origin.set(0, 0);
		fill.color = UITheme.ACCENT;
		add(fill);

		handle = new FlxSprite();
		handle.loadGraphic(RoundedRectCache.get(Std.int(HANDLE_SIZE / 2), Std.int(HANDLE_SIZE), HANDLE_SIZE / 2, UITheme.ACCENT));
		handle.y = (rowHeight - HANDLE_SIZE) / 2;
		add(handle);

		var valueTextWidth = rowWidth - UITheme.PADDING - (track.x + trackWidth + 10);

		editBox = new FlxSprite(track.x + trackWidth + 6, 0);
		editBox.loadGraphic(
			RoundedRectCache.get(Std.int(valueTextWidth + 8), Std.int(rowHeight - 6), UITheme.CORNER_RADIUS - 2, UITheme.CONTROL_BG_HOVER, UITheme.ACCENT, 1)
		);
		editBox.y = (rowHeight - editBox.height) / 2;
		editBox.visible = false;
		add(editBox);

		valueText = new FlxText(track.x + trackWidth + 10, 0, valueTextWidth, "", UITheme.FONT_SIZE);
		valueText.font = UITheme.FONT;
		valueText.color = UITheme.TEXT_COLOR;
		valueText.wordWrap = false;
		valueText.y = (rowHeight - valueText.height) / 2;
		valueText.antialiasing = UITheme.FONT_ANTIALIASING;
		add(valueText);

		editCaret = new FlxSprite();
		editCaret.loadGraphic(RoundedRectCache.getSolidPixel());
		editCaret.origin.set(0, 0);
		editCaret.color = UITheme.TEXT_COLOR;
		editCaret.visible = false;
		add(editCaret);
		editCaret.active = valueText.active = editBox.active = false;

		value = defaultValue;

		openfl.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		openfl.Lib.current.stage.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
	}

	function set_value(v:Float):Float
	{
		value = Math.max(min, Math.min(max, v));
		final ratio = (max > min) ? (value - min) / (max - min) : 0;
		if (fill != null)
		{
			fill.scale.set(Math.max(0.001, trackWidth * ratio), TRACK_HEIGHT);
			handle.x = track.x + trackWidth * ratio - handle.width / 2;
		}
		if (valueText != null && !editing) valueText.text = formatter != null ? formatter(value) : (Math.round(value * 100) / 100) + "x";
		return value;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		final mp = FlxG.mouse.getWorldPosition(null, _mp);

		if (FlxG.mouse.justPressed)
		{
			if (editing)
			{
				if (!containsPoint(mp, editBox)) commitEdit();
			}
			else if (containsPoint(mp, valueText)) beginEdit();
			else if (containsPoint(mp, track) || containsPoint(mp, handle)) dragging = true;
		}

		if (FlxG.mouse.justReleased) dragging = false;

		if (!editing && dragging)
		{
			var ratio = (mp.x - track.x) / trackWidth;
			ratio = Math.max(0, Math.min(1, ratio));
			value = min + ratio * (max - min);
			if (onChange != null) onChange(value);
		}

		if (editing)
		{
			caretTimer += elapsed;
			if (caretTimer > 0.5)
			{
				caretTimer = 0;
				caretVisible = !caretVisible;
				updateEditCaret();
			}
		}
	}

	inline function containsPoint(p:flixel.math.FlxPoint, s:FlxSprite):Bool return p.x >= s.x && p.x <= s.x + s.width && p.y >= s.y && p.y <= s.y + s.height;

	function beginEdit():Void
	{
		UIEditFocus.request(this);
		editing = true;
		dragging = false;
		editText = trimTrailingZeros(value);
		editBox.visible = true;
		valueText.text = editText;
		valueText.color = UITheme.TEXT_COLOR;
		caretTimer = 0;
		caretVisible = true;
		updateEditCaret();
	}

	function commitEdit():Void
	{
		final parsed = Std.parseFloat(editText);
		if (!Math.isNaN(parsed))
		{
			value = parsed;
			if (onChange != null) onChange(value);
		}
		endEdit();
	}

	function endEdit():Void
	{
		editing = false;
		editBox.visible = false;
		editCaret.visible = false;
		UIEditFocus.release(this);
		valueText.text = formatter != null ? formatter(value) : (Math.round(value * 100) / 100) + "x";
	}

	public function blurEdit():Void
	{
		if (editing) commitEdit();
	}

	public function forceHideEditorChrome():Void
	{
		if (editing) commitEdit();
		editBox.visible = false;
		editCaret.visible = false;
	}

	function updateEditCaret():Void
	{
		final caretH = Math.max(10, valueText.height > 0 ? valueText.height : rowHeight - 10);
		final topY = editBox.y + (editBox.height - caretH) / 2;
		editCaret.setPosition(valueText.x + measureWidth(editText), topY);
		editCaret.scale.set(2, caretH);
		editCaret.visible = editing && caretVisible;
	}

	function isCharAllowed(c:String):Bool
	{
		if (c >= "0" && c <= "9") return true;
		if (c == "." && editText.indexOf(".") == -1) return true;
		if (c == "-" && editText.length == 0 && min < 0) return true;
		return false;
	}

	function onKeyDown(e:KeyboardEvent):Void
	{
		if (!editing) return;

		switch (e.keyCode)
		{
			case 8: // backspace
				if (editText.length > 0) editText = editText.substring(0, editText.length - 1);
				resetCaretBlink();
				valueText.text = editText;
				updateEditCaret();

			case 13: // enter
				commitEdit();

			case 27: // escape
				endEdit();

			default:
		}
	}

	function onTextInput(e:TextEvent):Void
	{
		if (!editing) return;
		for (i in 0...e.text.length)
		{
			final c = e.text.charAt(i);
			if (isCharAllowed(c) && editText.length < 12) editText += c;
		}
		resetCaretBlink();
		valueText.text = editText;
		updateEditCaret();
	}

	inline function resetCaretBlink():Void
	{
		caretTimer = 0;
		caretVisible = true;
	}

	function trimTrailingZeros(v:Float):String
	{
		var s = Std.string(Math.round(v * 1000) / 1000);
		if (s.indexOf(".") != -1)
		{
			while (s.endsWith("0"))
				s = s.substr(0, s.length - 1);
			if (s.endsWith(".")) s = s.substr(0, s.length - 1);
		}
		return s;
	}

	static var measurer:FlxText;

	static function measureWidth(s:String):Float
	{
		if (s == null || s.length == 0) return 0;
		if (measurer == null)
		{
			measurer = new FlxText(0, 0, 0, "");
			measurer.font = UITheme.FONT;
			measurer.size = UITheme.FONT_SIZE;
			measurer.wordWrap = false;
			measurer.antialiasing = UITheme.FONT_ANTIALIASING;
			measurer.active = false;
		}
		measurer.text = s;
		return measurer.width;
	}

	override public function destroy():Void
	{
		UIEditFocus.release(this);
		openfl.Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		openfl.Lib.current.stage.removeEventListener(TextEvent.TEXT_INPUT, onTextInput);
		super.destroy();
	}
}
