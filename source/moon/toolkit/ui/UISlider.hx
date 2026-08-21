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
 * A simple and nice looking slider.
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
	var defaultValue:Float;
	var _mp:flixel.math.FlxPoint = flixel.math.FlxPoint.get();
	var editBox:FlxSprite;
	var editCaret:FlxSprite;
	var selectionHighlight:FlxSprite;
	var editing:Bool = false;
	var editText:String = "";
	var caretTimer:Float = 0;
	var caretVisible:Bool = true;
	var cursorIndex:Int = 0;
	var selectionAnchor:Int = -1;
	var isSelecting:Bool = false;

	static inline var TRACK_HEIGHT:Float = 6;
	static inline var HANDLE_SIZE:Float = 16;
	static inline var MAX_EDIT_LEN:Int = 12;

	public function new(x:Float, y:Float, width:Float, labelText:String, min:Float, max:Float, defaultValue:Float, step:Float = 0.1, ?iconGraphic:Dynamic)
	{
		super(x, y, width, labelText, iconGraphic);
		this.min = min;
		this.max = max;
		this.step = step;
		this.defaultValue = defaultValue;

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

		selectionHighlight = new FlxSprite();
		selectionHighlight.loadGraphic(RoundedRectCache.getSolidPixel());
		selectionHighlight.origin.set(0, 0);
		selectionHighlight.color = UITheme.ACCENT_DIM;
		selectionHighlight.alpha = 0.6;
		selectionHighlight.visible = selectionHighlight.active = false;
		add(selectionHighlight);

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

	function resetToDefault():Void
	{
		if (editing) endEdit();
		if (value == defaultValue) return;
		value = defaultValue;
		if (onChange != null) onChange(value);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		final mp = FlxG.mouse.getWorldPosition(null, _mp);

		if (FlxG.mouse.justPressedMiddle && !UIDropdown.isAnyOpen() && !UIColorPicker.isAnyOpen())
		{
			if (
				containsPoint(mp, track)
				|| containsPoint(mp, handle)
				|| containsPoint(mp, valueText)
				|| (editing && containsPoint(mp, editBox))
			) resetToDefault();
			return;
		}

		if (FlxG.mouse.justPressed && !UIDropdown.isAnyOpen() && !UIColorPicker.isAnyOpen())
		{
			if (editing)
			{
				if (containsPoint(mp, editBox))
				{
					cursorIndex = indexFromLocalX(mp.x - valueText.x);
					selectionAnchor = cursorIndex;
					isSelecting = true;
					resetCaretBlink();
					updateCaretAndSelection();
				}
				else
					commitEdit();
			}
			else if (containsPoint(mp, valueText))
			{
				beginEdit();
				cursorIndex = indexFromLocalX(mp.x - valueText.x);
				selectionAnchor = cursorIndex;
				isSelecting = true;
				resetCaretBlink();
				updateCaretAndSelection();
			}
			else if (containsPoint(mp, track) || containsPoint(mp, handle)) dragging = true;
		}
		else if (isSelecting)
		{
			if (FlxG.mouse.pressed)
			{
				final newIndex = indexFromLocalX(mp.x - valueText.x);
				if (newIndex != cursorIndex)
				{
					cursorIndex = newIndex;
					resetCaretBlink();
					updateCaretAndSelection();
				}
			}
			else
			{
				isSelecting = false;
				if (selectionAnchor == cursorIndex) selectionAnchor = -1;
				updateCaretAndSelection();
			}
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
			if (UIEditFocus.current != this)
			{
				endEdit();
				return;
			}
			caretTimer += elapsed;
			if (caretTimer > 0.5)
			{
				caretTimer = 0;
				caretVisible = !caretVisible;
				updateCaretAndSelection();
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
		cursorIndex = editText.length;
		selectionAnchor = -1;
		isSelecting = false;
		editBox.visible = true;
		valueText.text = editText;
		valueText.color = UITheme.TEXT_COLOR;
		resetCaretBlink();
		updateCaretAndSelection();
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
		isSelecting = false;
		selectionAnchor = -1;
		editBox.visible = false;
		editCaret.visible = false;
		selectionHighlight.visible = false;
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
		selectionHighlight.visible = false;
	}

	inline function resetCaretBlink():Void
	{
		caretTimer = 0;
		caretVisible = true;
	}

	inline function hasSelection():Bool return selectionAnchor != -1 && selectionAnchor != cursorIndex;

	inline function selStart():Int return Std.int(Math.min(selectionAnchor, cursorIndex));

	inline function selEnd():Int return Std.int(Math.max(selectionAnchor, cursorIndex));

	inline function selectedText():String return hasSelection() ? editText.substring(selStart(), selEnd()) : "";

	function deleteSelection():Void
	{
		if (!hasSelection()) return;
		editText = editText.substring(0, selStart()) + editText.substring(selEnd());
		cursorIndex = selStart();
		selectionAnchor = -1;
		valueText.text = editText;
		updateCaretAndSelection();
	}

	function insertAtCursor(s:String):Void
	{
		if (s == null || s.length == 0) return;
		if (hasSelection()) deleteSelection();

		var filtered = "";
		for (i in 0...s.length)
		{
			final c = s.charAt(i);
			if (isCharAllowed(c, filtered)) filtered += c;
		}
		if (filtered.length == 0) return;

		final room = MAX_EDIT_LEN - editText.length;
		if (room <= 0) return;
		if (filtered.length > room) filtered = filtered.substring(0, room);

		editText = editText.substring(0, cursorIndex) + filtered + editText.substring(cursorIndex);
		cursorIndex += filtered.length;
		valueText.text = editText;
		updateCaretAndSelection();
	}

	function updateCaretAndSelection():Void
	{
		final textX = valueText.x;
		final caretH = Math.max(10, valueText.height > 0 ? valueText.height : rowHeight - 10);
		final topY = editBox.y + (editBox.height - caretH) / 2;

		editCaret.setPosition(textX + measureWidth(editText.substring(0, cursorIndex)), topY);
		editCaret.scale.set(2, caretH);
		editCaret.visible = editing && caretVisible && !hasSelection();

		if (hasSelection())
		{
			selectionHighlight.setPosition(textX + measureWidth(editText.substring(0, selStart())), topY);
			selectionHighlight.scale.set(Math.max(1, measureWidth(editText.substring(0, selEnd())) - measureWidth(editText.substring(0, selStart()))), caretH);
			selectionHighlight.visible = editing;
		}
		else
			selectionHighlight.visible = false;
	}

	function isCharAllowed(c:String, current:String):Bool
	{
		if (c >= "0" && c <= "9") return true;
		if (c == "." && current.indexOf(".") == -1 && editText.indexOf(".") == -1) return true;
		if (c == "-" && current.length == 0 && cursorIndex == 0 && min < 0 && editText.indexOf("-") == -1) return true;
		return false;
	}

	function indexFromLocalX(localX:Float):Int
	{
		if (localX <= 0) return 0;
		for (i in 0...editText.length + 1)
		{
			final w = measureWidth(editText.substring(0, i));
			if (w >= localX)
			{
				if (i == 0) return 0;
				final prevW = measureWidth(editText.substring(0, i - 1));
				return (localX - prevW < w - localX) ? i - 1 : i;
			}
		}
		return editText.length;
	}

	function onKeyDown(e:KeyboardEvent):Void
	{
		if (!editing) return;
		final ctrl = e.ctrlKey || e.commandKey;

		switch (e.keyCode)
		{
			case 8: // backspace
				if (hasSelection()) deleteSelection();
				else if (cursorIndex > 0)
				{
					editText = editText.substring(0, cursorIndex - 1) + editText.substring(cursorIndex);
					cursorIndex -= 1;
					valueText.text = editText;
					updateCaretAndSelection();
				}
				resetCaretBlink();

			case 46: // delete
				if (hasSelection()) deleteSelection();
				else if (cursorIndex < editText.length)
				{
					editText = editText.substring(0, cursorIndex) + editText.substring(cursorIndex + 1);
					valueText.text = editText;
					updateCaretAndSelection();
				}
				resetCaretBlink();

			case 37: // left
				if (e.shiftKey)
				{
					if (selectionAnchor == -1) selectionAnchor = cursorIndex;
					cursorIndex = Std.int(Math.max(0, cursorIndex - 1));
				}
				else
				{
					cursorIndex = hasSelection() ? selStart() : Std.int(Math.max(0, cursorIndex - 1));
					selectionAnchor = -1;
				}
				resetCaretBlink();
				updateCaretAndSelection();

			case 39: // right
				if (e.shiftKey)
				{
					if (selectionAnchor == -1) selectionAnchor = cursorIndex;
					cursorIndex = Std.int(Math.min(editText.length, cursorIndex + 1));
				}
				else
				{
					cursorIndex = hasSelection() ? selEnd() : Std.int(Math.min(editText.length, cursorIndex + 1));
					selectionAnchor = -1;
				}
				resetCaretBlink();
				updateCaretAndSelection();

			case 36: // home
				if (e.shiftKey)
				{
					if (selectionAnchor == -1) selectionAnchor = cursorIndex;
				}
				else
					selectionAnchor = -1;
				cursorIndex = 0;
				resetCaretBlink();
				updateCaretAndSelection();

			case 35: // end
				if (e.shiftKey)
				{
					if (selectionAnchor == -1) selectionAnchor = cursorIndex;
				}
				else
					selectionAnchor = -1;
				cursorIndex = editText.length;
				resetCaretBlink();
				updateCaretAndSelection();

			case 65 if (ctrl): // ctrl+A
				selectionAnchor = 0;
				cursorIndex = editText.length;
				updateCaretAndSelection();

			case 67 if (ctrl): // ctrl+C
				if (hasSelection()) copyToClipboard(selectedText());

			case 88 if (ctrl): // ctrl+X
				if (hasSelection())
				{
					copyToClipboard(selectedText());
					deleteSelection();
				}

			case 86 if (ctrl): // ctrl+V
				final pasted = pasteFromClipboard();
				if (pasted != null) insertAtCursor(pasted.replace("\r", "").replace("\n", ""));

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
		insertAtCursor(e.text);
		resetCaretBlink();
	}

	function copyToClipboard(s:String):Void
	{
		try
			lime.system.Clipboard.text = s
		catch (_:Dynamic)
		{
		}
	}

	function pasteFromClipboard():String
	{
		try
			return lime.system.Clipboard.text
		catch (_:Dynamic)
			return null;
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
		_mp.put();
		super.destroy();
	}
}
