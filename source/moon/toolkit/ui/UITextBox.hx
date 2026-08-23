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
	var defaultText:String = "";
	var defaultCaptured:Bool = false;
	var box:FlxSprite;
	var textDisplay:FlxText;
	var textClip:FlxSprite;
	var caret:FlxSprite;
	var selectionHighlight:FlxSprite;
	var focused:Bool = false;
	var caretTimer:Float = 0;
	var caretVisible:Bool = true;
	var cursorIndex:Int = 0;
	var selectionAnchor:Int = -1;
	var isSelecting:Bool = false;
	var scrollX:Float = 0;

	static inline final BOX_WIDTH:Float = 160;
	static inline final TEXT_PAD:Float = 8;

	public function new(x:Float, y:Float, width:Float, labelText:String, placeholder:String = "", ?iconGraphic:Dynamic)
	{
		super(x, y, width, labelText, iconGraphic);
		this.placeholder = placeholder;
		this.defaultText = "";

		box = RoundedRectCache.create(Std.int(BOX_WIDTH), Std.int(rowHeight - 6), UITheme.CONTROL_BG_HOVER);
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

		textDisplay = new FlxText(0, 0, 0, placeholder, UITheme.FONT_SIZE);
		textDisplay.font = UITheme.FONT;
		textDisplay.color = UITheme.TEXT_DIM;
		textDisplay.wordWrap = false;
		textDisplay.active = false;
		textDisplay.visible = false;
		textDisplay.antialiasing = UITheme.FONT_ANTIALIASING;
		add(textDisplay);

		textClip = new FlxSprite(box.x + TEXT_PAD, 0);
		textClip.makeGraphic(Std.int(textAreaWidth()), Std.int(rowHeight - 6), FlxColor.TRANSPARENT, true);
		textClip.y = (rowHeight - textClip.height) / 2;
		textClip.active = false;
		textClip.antialiasing = UITheme.FONT_ANTIALIASING;
		add(textClip);

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
		if (!defaultCaptured)
		{
			defaultText = v;
			defaultCaptured = true;
		}
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
		UIEditFocus.release(this);
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

		if (focused && UIEditFocus.current != this) applyFocus(false);

		if (FlxG.mouse.justPressedMiddle && !UIDropdown.isAnyOpen() && !UIColorPicker.isAnyOpen())
		{
			var mp = FlxG.mouse.getWorldPosition();
			if (containsPoint(mp.x, mp.y, box.x, box.y, box.width, box.height))
			{
				if (focused) UIEditFocus.release(this);
				if (_text != defaultText) text = defaultText;
			}
			return;
		}

		if (FlxG.mouse.justPressed && !UIDropdown.isAnyOpen() && !UIColorPicker.isAnyOpen())
		{
			var mp = FlxG.mouse.getWorldPosition();
			if (containsPoint(mp.x, mp.y, box.x, box.y, box.width, box.height))
			{
				requestFocus();
				cursorIndex = indexFromLocalX(mp.x - (box.x + TEXT_PAD) + scrollX);
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
				var newIndex = indexFromLocalX(mp.x - (box.x + TEXT_PAD) + scrollX);
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
			scrollX = 0;
		}
		resetCaretBlink();
		setBackgroundState(f ? Active : Normal);
		box.color = f ? UITheme.ACCENT : UITheme.CONTROL_BG_HOVER;
		refreshDisplay();
	}

	inline function textAreaWidth():Float return BOX_WIDTH - TEXT_PAD * 2;

	static inline final SCROLL_EDGE_PAD:Float = 4;

	function ensureCaretVisible():Void
	{
		final area = textAreaWidth();
		final total = Math.max(measureWidth(_text), textDisplay.frameWidth > 0 ? textDisplay.frameWidth : 0);
		final caretOff = (cursorIndex >= _text.length) ? total : measureWidth(_text.substring(0, cursorIndex));

		if (caretOff - scrollX > area - SCROLL_EDGE_PAD) scrollX = caretOff - (area - SCROLL_EDGE_PAD);
		if (caretOff - scrollX < 0) scrollX = caretOff;
		scrollX = Math.max(0, Math.min(Math.max(0, total - area + SCROLL_EDGE_PAD), scrollX));
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
		if (focused) ensureCaretVisible();
		else
			scrollX = 0;

		final viewL = box.x + TEXT_PAD;
		final viewR = box.x + BOX_WIDTH - TEXT_PAD;
		final caretH = Math.max(10, textDisplay.height > 0 ? textDisplay.height : rowHeight - 10);
		final topY = box.y + (box.height - caretH) / 2;

		bakeTextClip(viewL, textAreaWidth());

		final caretWorldX = viewL + measureWidth(_text.substring(0, cursorIndex)) - scrollX;
		caret.setPosition(caretWorldX, topY);
		caret.scale.set(2, caretH);
		caret.visible = focused && caretVisible && !hasSelection() && caretWorldX >= viewL - 1 && caretWorldX <= viewR + 1;

		if (hasSelection())
		{
			final visL = Math.max(viewL + measureWidth(_text.substring(0, selStart())) - scrollX, viewL);
			final visR = Math.min(viewL + measureWidth(_text.substring(0, selEnd())) - scrollX, viewR);
			if (visR > visL)
			{
				selectionHighlight.setPosition(visL, topY);
				selectionHighlight.scale.set(visR - visL, caretH);
				selectionHighlight.visible = focused;
			}
			else
				selectionHighlight.visible = false;
		}
		else
			selectionHighlight.visible = false;
	}

	function bakeTextClip(viewL:Float, areaW:Float):Void
	{
		final w = Std.int(Math.max(1, Math.ceil(areaW)));
		final h = Std.int(Math.max(1, rowHeight - 6));

		if (textClip.pixels == null || textClip.pixels.width != w || textClip.pixels.height != h) textClip.makeGraphic(w, h, FlxColor.TRANSPARENT, true);
		else
			textClip.pixels.fillRect(textClip.pixels.rect, FlxColor.TRANSPARENT);

		textClip.x = viewL;
		textClip.y = box.y + (box.height - h) / 2;

		if (textDisplay.graphic != null && textDisplay.frameWidth > 0)
		{
			textDisplay.drawFrame(true);
			final stampX = -Math.round(scrollX);
			final stampY = Std.int(Math.max(0, (h - textDisplay.frameHeight) / 2));
			textClip.stamp(textDisplay, stampX, stampY);
		}
		textClip.dirty = true;
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
				Paths.playSFX('toolkit/moon-ui/typer/erase.wav', 'sounds', true, FlxG.random.float(0.85, 1.2));
				resetCaretBlink();

			case 46: // delete
				if (hasSelection()) deleteSelection();
				else if (cursorIndex < _text.length)
				{
					var newText = _text.substring(0, cursorIndex) + _text.substring(cursorIndex + 1);
					commitText(newText);
				}
				resetCaretBlink();
				Paths.playSFX('toolkit/moon-ui/typer/erase.wav', 'sounds', true, FlxG.random.float(0.85, 1.2));

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
				Paths.playSFX('toolkit/moon-ui/typer/move.wav', 'sounds', true, FlxG.random.float(0.85, 1.2));
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
				Paths.playSFX('toolkit/moon-ui/typer/move.wav', 'sounds', true, FlxG.random.float(0.85, 1.2));
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
		Paths.playSFX('toolkit/moon-ui/typer/type${FlxG.random.int(1, 11)}.wav', 'sounds');
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
