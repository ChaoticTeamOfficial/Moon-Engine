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
 * A simple and nice-looking stepper.
 */
class UIStepper extends UIComponent implements ITextEditable implements IEditorChromeHideable
{
	public var value(get, set):Int;

	@:isVar
	var _value:Int;

	public var min:Int;
	public var max:Int;
	public var step:Int;
	public var onChange:Int->Void;
	public var formatter:Int->String;

	/**
	 * When true, this stepper still accepts input while a color-picker popup
	 * is open.
	 */
	public var allowDuringColorPicker:Bool = false;

	var minusBtn:FlxSprite;
	var plusBtn:FlxSprite;
	var minusLabel:FlxText;
	var plusLabel:FlxText;
	var valueText:FlxText;
	var heldDir:Int = 0;
	var holdTime:Float = 0;
	var timeSinceLastRepeat:Float = 0;
	var defaultValue:Int;
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
	var _mp:flixel.math.FlxPoint = flixel.math.FlxPoint.get();

	static inline final BTN_SIZE:Float = 22;
	static inline final VALUE_WIDTH:Float = 50;
	static inline final HOLD_INITIAL_DELAY:Float = 0.4;
	static inline final HOLD_ACCEL_TIME:Float = 2.0;
	static inline final HOLD_MAX_INTERVAL:Float = 0.35;
	static inline final HOLD_MIN_INTERVAL:Float = 0.03;
	static inline final MAX_EDIT_LEN:Int = 12;

	public function new(x:Float, y:Float, width:Float, labelText:String, min:Int, max:Int, defaultValue:Int, step:Int = 1, ?iconGraphic:Dynamic, isVertical:Bool = false)
	{
		super(x, y, width, labelText, iconGraphic);
		this.min = min;
		this.max = max;
		this.step = step;
		this.defaultValue = defaultValue;

		var totalWidth = BTN_SIZE * 2 + VALUE_WIDTH;
		var startX = rowWidth - UITheme.PADDING - totalWidth;

		minusBtn = new FlxSprite(startX, 0);
		minusBtn.loadGraphic(RoundedRectCache.get(Std.int(BTN_SIZE), Std.int(BTN_SIZE), 5, FlxColor.WHITE));
		minusBtn.color = UITheme.CONTROL_BG_HOVER;
		minusBtn.y = (rowHeight - BTN_SIZE) / 2;
		minusBtn.active = false;
		add(minusBtn);

		minusLabel = new FlxText(0, 0, 0, isVertical ? "v" : "<", UITheme.FONT_SIZE);
		minusLabel.font = UITheme.FONT;
		minusLabel.color = UITheme.TEXT_COLOR;
		minusLabel.antialiasing = UITheme.FONT_ANTIALIASING;
		minusLabel.active = false;
		add(minusLabel);
		centerLabelOnButton(minusLabel, minusBtn);

		editBox = new FlxSprite(minusBtn.x + BTN_SIZE, 0);
		editBox.loadGraphic(
			RoundedRectCache.get(Std.int(VALUE_WIDTH), Std.int(rowHeight - 6), UITheme.CORNER_RADIUS - 2, UITheme.CONTROL_BG_HOVER, UITheme.ACCENT, 1)
		);
		editBox.y = (rowHeight - editBox.height) / 2;
		editBox.visible = false;
		editBox.active = false;
		add(editBox);

		selectionHighlight = new FlxSprite();
		selectionHighlight.loadGraphic(RoundedRectCache.getSolidPixel());
		selectionHighlight.origin.set(0, 0);
		selectionHighlight.color = UITheme.ACCENT_DIM;
		selectionHighlight.alpha = 0.6;
		selectionHighlight.visible = selectionHighlight.active = false;
		add(selectionHighlight);

		valueText = new FlxText(minusBtn.x + BTN_SIZE, 0, VALUE_WIDTH, "", UITheme.FONT_SIZE);
		valueText.font = UITheme.FONT;
		valueText.color = UITheme.TEXT_COLOR;
		valueText.alignment = CENTER;
		valueText.y = (rowHeight - valueText.height) / 2;
		valueText.antialiasing = UITheme.FONT_ANTIALIASING;
		valueText.active = false;
		add(valueText);

		editCaret = new FlxSprite();
		editCaret.loadGraphic(RoundedRectCache.getSolidPixel());
		editCaret.origin.set(0, 0);
		editCaret.color = UITheme.TEXT_COLOR;
		editCaret.visible = false;
		editCaret.active = false;
		add(editCaret);

		plusBtn = new FlxSprite(minusBtn.x + BTN_SIZE + VALUE_WIDTH, 0);
		plusBtn.loadGraphic(RoundedRectCache.get(Std.int(BTN_SIZE), Std.int(BTN_SIZE), 5, FlxColor.WHITE));
		plusBtn.color = UITheme.CONTROL_BG_HOVER;
		plusBtn.y = (rowHeight - BTN_SIZE) / 2;
		plusBtn.active = false;
		add(plusBtn);

		plusLabel = new FlxText(0, 0, 0, isVertical ? "^" : ">", UITheme.FONT_SIZE);
		plusLabel.font = UITheme.FONT;
		plusLabel.color = UITheme.TEXT_COLOR;
		plusLabel.antialiasing = UITheme.FONT_ANTIALIASING;
		add(plusLabel);
		centerLabelOnButton(plusLabel, plusBtn);

		value = defaultValue;

		openfl.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		openfl.Lib.current.stage.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
	}

	function centerLabelOnButton(label:FlxText, btn:FlxSprite):Void
	{
		label.x = btn.x + (btn.width - label.width) / 2;
		label.y = btn.y + (btn.height - label.height) / 2;
	}

	function get_value():Int return _value;

	function set_value(v:Int):Int
	{
		_value = Std.int(Math.max(min, Math.min(max, v)));
		if (valueText != null && !editing) valueText.text = formatter != null ? formatter(_value) : Std.string(_value);
		return _value;
	}

	function resetToDefault():Void
	{
		if (editing) endEdit();
		if (_value == defaultValue) return;
		value = defaultValue;
		if (onChange != null) onChange(value);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		final mp = FlxG.mouse.getWorldPosition(null, _mp);

		if (FlxG.mouse.justPressedMiddle && !UIDropdown.isAnyOpen() && (!UIColorPicker.isAnyOpen() || allowDuringColorPicker))
		{
			if (
				containsPoint(mp, minusBtn)
				|| containsPoint(mp, plusBtn)
				|| containsPoint(mp, valueText)
				|| (editing && containsPoint(mp, editBox))
			) resetToDefault();
			return;
		}

		if (editing)
		{
			if (UIEditFocus.current != this)
			{
				endEdit();
				return;
			}

			if (FlxG.mouse.justPressed)
			{
				if (containsPoint(mp, editBox) || containsPoint(mp, valueText))
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

			caretTimer += elapsed;
			if (caretTimer > 0.5)
			{
				caretTimer = 0;
				caretVisible = !caretVisible;
				updateCaretAndSelection();
			}
			return;
		}

		if (UIEditFocus.current != null || UIDropdown.isAnyOpen()) return;
		if (UIColorPicker.isAnyOpen() && !allowDuringColorPicker) return;

		if (FlxG.mouse.justPressed)
		{
			if (containsPoint(mp, valueText))
			{
				beginEdit();
				cursorIndex = indexFromLocalX(mp.x - valueText.x);
				selectionAnchor = cursorIndex;
				isSelecting = true;
				resetCaretBlink();
				updateCaretAndSelection();
			}
			else if (containsPoint(mp, minusBtn))
			{
				applyDelta(-step);
				startHold(-1);
			}
			else if (containsPoint(mp, plusBtn))
			{
				applyDelta(step);
				startHold(1);
			}
		}
		else if (FlxG.mouse.justReleased) stopHold();

		if (heldDir != 0)
		{
			if (!FlxG.mouse.pressed)
			{
				stopHold();
				return;
			}

			holdTime += elapsed;
			timeSinceLastRepeat += elapsed;

			if (holdTime >= HOLD_INITIAL_DELAY)
			{
				final accelT = flixel.math.FlxMath.bound((holdTime - HOLD_INITIAL_DELAY) / HOLD_ACCEL_TIME, 0, 1);
				final interval = HOLD_MAX_INTERVAL + (HOLD_MIN_INTERVAL - HOLD_MAX_INTERVAL) * accelT;

				if (timeSinceLastRepeat >= interval)
				{
					timeSinceLastRepeat = 0;
					applyDelta(heldDir * step);
				}
			}
		}
	}

	inline function containsPoint(p:flixel.math.FlxPoint, s:FlxSprite):Bool return p.x >= s.x && p.x <= s.x + s.width && p.y >= s.y && p.y <= s.y + s.height;

	function startHold(dir:Int):Void
	{
		heldDir = dir;
		holdTime = 0;
		timeSinceLastRepeat = 0;
	}

	function stopHold():Void heldDir = 0;

	function applyDelta(d:Int):Void
	{
		value = value + d;
		if (onChange != null) onChange(value);
	}

	function beginEdit():Void
	{
		stopHold();
		UIEditFocus.request(this);
		editing = true;
		editText = Std.string(_value);
		cursorIndex = editText.length;
		selectionAnchor = -1;
		isSelecting = false;
		editBox.visible = true;
		valueText.alignment = LEFT;
		valueText.text = editText;
		valueText.color = UITheme.TEXT_COLOR;
		resetCaretBlink();
		updateCaretAndSelection();
	}

	function commitEdit():Void
	{
		final parsed = Std.parseInt(editText);
		if (parsed != null)
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
		valueText.alignment = CENTER;
		UIEditFocus.release(this);
		valueText.text = formatter != null ? formatter(_value) : Std.string(_value);
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
		final drawX = valueText.x;
		final caretH = Math.max(10, valueText.height > 0 ? valueText.height : rowHeight - 10);
		final topY = editBox.y + (editBox.height - caretH) / 2;

		editCaret.setPosition(drawX + measureWidth(editText.substring(0, cursorIndex)), topY);
		editCaret.scale.set(2, caretH);
		editCaret.visible = editing && caretVisible && !hasSelection();

		if (hasSelection())
		{
			selectionHighlight.setPosition(drawX + measureWidth(editText.substring(0, selStart())), topY);
			selectionHighlight.scale.set(Math.max(1, measureWidth(editText.substring(0, selEnd())) - measureWidth(editText.substring(0, selStart()))), caretH);
			selectionHighlight.visible = editing;
		}
		else
			selectionHighlight.visible = false;
	}

	function isCharAllowed(c:String, current:String):Bool
	{
		if (c >= "0" && c <= "9") return true;
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
