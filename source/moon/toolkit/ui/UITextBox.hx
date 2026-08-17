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

class UITextBox extends UIComponent implements ITextEditable implements IEditorChromeHideable
{
	public var text(get, set):String;
	public var placeholder:String;
	public var onChange:String->Void;
	public var onEnter:String->Void;
	public var maxLength:Int = 64;

	var _text:String = "";
	var box:FlxSprite;
	var textDisplay:FlxText;
	var caret:FlxSprite;
	var selectionHighlight:FlxSprite;
	var focused:Bool = false;
	var caretTimer:Float = 0;
	var caretVisible:Bool = true;
	var cursorIndex:Int = 0;
	var selectionAnchor:Int = -1;
	var isSelecting:Bool = false;

	static inline final BOX_WIDTH:Float = 160;

	public function new(x:Float, y:Float, width:Float, labelText:String, placeholder:String = "", ?iconGraphic:Dynamic)
	{
		super(x, y, width, labelText, iconGraphic);
		this.placeholder = placeholder;

		box = new FlxSprite();
		box.loadGraphic(
			RoundedRectCache.get(Std.int(BOX_WIDTH), Std.int(rowHeight - 6), UITheme.CORNER_RADIUS - 2, UITheme.CONTROL_BG_HOVER, UITheme.CONTROL_BORDER, 1)
		);
		box.y = (rowHeight - box.height) / 2;
		addValueWidget(box, BOX_WIDTH);
		box.active = false;

		selectionHighlight = new FlxSprite();
		selectionHighlight.loadGraphic(RoundedRectCache.getSolidPixel());
		selectionHighlight.origin.set(0, 0);
		selectionHighlight.color = UITheme.ACCENT_DIM;
		selectionHighlight.alpha = 0.6;
		selectionHighlight.visible = selectionHighlight.active = false;
		add(selectionHighlight);

		textDisplay = new FlxText(box.x + 8, 0, BOX_WIDTH - 16, placeholder, UITheme.FONT_SIZE);
		textDisplay.font = UITheme.FONT;
		textDisplay.color = UITheme.TEXT_DIM;
		textDisplay.wordWrap = false;
		textDisplay.y = (rowHeight - textDisplay.height) / 2;
		textDisplay.active = false;
		textDisplay.antialiasing = UITheme.FONT_ANTIALIASING;
		add(textDisplay);

		caret = new FlxSprite();
		caret.loadGraphic(RoundedRectCache.getSolidPixel());
		caret.origin.set(0, 0);
		caret.color = UITheme.TEXT_COLOR;
		caret.visible = false;
		caret.active = false;
		add(caret);

		openfl.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		openfl.Lib.current.stage.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
	}

	inline function get_text():String return _text;

	function set_text(v:String):String
	{
		_text = v;
		cursorIndex = _text.length;
		selectionAnchor = -1;
		refreshDisplay();
		if (onChange != null) onChange(_text);
		return v;
	}

	function commitText(v:String):Void
	{
		_text = v;
		refreshDisplay();
		if (onChange != null) onChange(_text);
	}

	function refreshDisplay():Void
	{
		if (_text.length == 0 && !focused)
		{
			textDisplay.text = placeholder;
			textDisplay.color = UITheme.TEXT_DIM;
		}
		else
		{
			textDisplay.text = _text;
			textDisplay.color = UITheme.TEXT_COLOR;
		}
		updateCaretAndSelection();
	}

	public function forceHideEditorChrome():Void
	{
		if (focused) applyFocus(false);
		isSelecting = false;
		caret.visible = false;
		selectionHighlight.visible = false;
	}

	public function blurEdit():Void
	{
		applyFocus(false);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (focused && UIEditFocus.current != this)
		{
			focused = false;
			isSelecting = false;
			selectionAnchor = -1;
			caret.visible = false;
			selectionHighlight.visible = false;
		}

		if (FlxG.mouse.justPressed)
		{
			var mp = FlxG.mouse.getWorldPosition();
			if (containsPoint(mp.x, mp.y, box.x, box.y, box.width, box.height))
			{
				requestFocus();
				cursorIndex = indexFromLocalX(mp.x - (box.x + 8));
				selectionAnchor = cursorIndex;
				isSelecting = true;
				resetCaretBlink();
				updateCaretAndSelection();
			}
			else if (UIEditFocus.current == this) UIEditFocus.release(this);
		}
		else if (isSelecting)
		{
			if (FlxG.mouse.pressed)
			{
				var mp = FlxG.mouse.getWorldPosition();
				var newIndex = indexFromLocalX(mp.x - (box.x + 8));
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

		if (focused)
		{
			caretTimer += elapsed;
			if (caretTimer > 0.5)
			{
				caretTimer = 0;
				caretVisible = !caretVisible;
				updateCaretAndSelection();
			}
		}
	}

	inline function containsPoint(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool return
		px >= rx
		&& px <= rx + rw
		&& py >= ry
		&& py <= ry + rh;

	function requestFocus():Void
	{
		UIEditFocus.request(this);
		applyFocus(true);
	}

	public static function clearFocus():Void UIEditFocus.request(null);

	function applyFocus(f:Bool):Void
	{
		focused = f;
		if (!f)
		{
			selectionAnchor = -1;
			isSelecting = false;
		}
		resetCaretBlink();
		setBackgroundState(f ? Active : Normal);
		box.loadGraphic(
			RoundedRectCache.get(
				Std.int(BOX_WIDTH),
				Std.int(rowHeight - 6),
				UITheme.CORNER_RADIUS - 2,
				UITheme.CONTROL_BG_HOVER,
				f ? UITheme.ACCENT : UITheme.CONTROL_BORDER,
				1
			)
		);
		refreshDisplay();
	}

	inline function resetCaretBlink():Void
	{
		caretTimer = 0;
		caretVisible = true;
	}

	inline function hasSelection():Bool return selectionAnchor != -1 && selectionAnchor != cursorIndex;

	inline function selStart():Int return Std.int(Math.min(selectionAnchor, cursorIndex));

	inline function selEnd():Int return Std.int(Math.max(selectionAnchor, cursorIndex));

	inline function selectedText():String return hasSelection() ? _text.substring(selStart(), selEnd()) : "";

	function deleteSelection():Void
	{
		if (!hasSelection()) return;
		var s = selStart(), e = selEnd();
		var newText = _text.substring(0, s) + _text.substring(e);
		cursorIndex = s;
		selectionAnchor = -1;
		commitText(newText);
	}

	function insertAtCursor(s:String):Void
	{
		if (s == null || s.length == 0) return;
		if (hasSelection()) deleteSelection();

		var room = maxLength - _text.length;
		if (room <= 0) return;
		if (s.length > room) s = s.substring(0, room);

		var newText = _text.substring(0, cursorIndex) + s + _text.substring(cursorIndex);
		cursorIndex += s.length;
		commitText(newText);
	}

	function updateCaretAndSelection():Void
	{
		final textX = box.x + 8;
		final caretH = Math.max(10, textDisplay.height > 0 ? textDisplay.height : rowHeight - 10);
		final topY = box.y + (box.height - caretH) / 2;

		caret.setPosition(textX + measureWidth(_text.substring(0, cursorIndex)), topY);
		caret.scale.set(2, caretH);
		caret.visible = focused && caretVisible && !hasSelection();

		if (hasSelection())
		{
			final sX = textX + measureWidth(_text.substring(0, selStart()));
			final eX = textX + measureWidth(_text.substring(0, selEnd()));
			selectionHighlight.setPosition(sX, topY);
			selectionHighlight.scale.set(Math.max(1, eX - sX), caretH);
			selectionHighlight.visible = focused;
		}
		else
			selectionHighlight.visible = false;
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
			measurer.active = false;
			measurer.antialiasing = UITheme.FONT_ANTIALIASING;
		}
		measurer.text = s;
		return measurer.width;
	}

	function indexFromLocalX(localX:Float):Int
	{
		if (localX <= 0) return 0;
		for (i in 0..._text.length + 1)
		{
			var w = measureWidth(_text.substring(0, i));
			if (w >= localX)
			{
				if (i == 0) return 0;
				var prevW = measureWidth(_text.substring(0, i - 1));
				return (localX - prevW < w - localX) ? i - 1 : i;
			}
		}
		return _text.length;
	}

	function onKeyDown(e:KeyboardEvent):Void
	{
		if (!focused) return;
		var ctrl = e.ctrlKey || e.commandKey;

		switch (e.keyCode)
		{
			case 8: // backspace
				if (hasSelection()) deleteSelection();
				else if (cursorIndex > 0)
				{
					var newText = _text.substring(0, cursorIndex - 1) + _text.substring(cursorIndex);
					cursorIndex -= 1;
					commitText(newText);
				}
				resetCaretBlink();

			case 46: // delete
				if (hasSelection()) deleteSelection();
				else if (cursorIndex < _text.length)
				{
					var newText = _text.substring(0, cursorIndex) + _text.substring(cursorIndex + 1);
					commitText(newText);
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
					cursorIndex = Std.int(Math.min(_text.length, cursorIndex + 1));
				}
				else
				{
					cursorIndex = hasSelection() ? selEnd() : Std.int(Math.min(_text.length, cursorIndex + 1));
					selectionAnchor = -1;
				}
				resetCaretBlink();
				updateCaretAndSelection();

			case 36: // home
				if (e.shiftKey) if (selectionAnchor == -1) selectionAnchor = cursorIndex;
				else
					selectionAnchor = -1;
				cursorIndex = 0;
				resetCaretBlink();
				updateCaretAndSelection();

			case 35: // end
				if (e.shiftKey) if (selectionAnchor == -1) selectionAnchor = cursorIndex;
				else
					selectionAnchor = -1;
				cursorIndex = _text.length;
				resetCaretBlink();
				updateCaretAndSelection();

			case 65 if (ctrl): // ctrl+A
				selectionAnchor = 0;
				cursorIndex = _text.length;
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
				UIEditFocus.release(this);
				if (onEnter != null) onEnter(_text);

			case 27: // escape
				UIEditFocus.release(this);

			default: // typed characters arrive via onTextInput
		}
	}

	function onTextInput(e:TextEvent):Void
	{
		if (!focused) return;
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

	override public function destroy():Void
	{
		UIEditFocus.release(this);
		openfl.Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		openfl.Lib.current.stage.removeEventListener(TextEvent.TEXT_INPUT, onTextInput);
		super.destroy();
	}
}
