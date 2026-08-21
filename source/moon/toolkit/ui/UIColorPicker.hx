package moon.toolkit.ui;

import moon.toolkit.ui.UIEditFocus.IEditorChromeHideable;

/**
 * A swatch that opens a popup with an interactive saturation/value color
 * box, a hue strip, preset colors, and R/G/B steppers for custom values.
 * TODO: make the preset colors modifiable by the user.
 */
class UIColorPicker extends UIComponent implements IEditorChromeHideable
{
	public var value(get, set):FlxColor;

	@:isVar
	var _value:FlxColor;

	public var onChange:FlxColor->Void;

	var swatch:FlxSprite;
	var popup:FlxSpriteGroup;
	var swatches:Array<FlxSprite> = [];
	var selectionRing:FlxSprite;
	var rStepper:UIStepper;
	var gStepper:UIStepper;
	var bStepper:UIStepper;
	var isOpen:Bool = false;
	var popupHeight:Float;
	var svBox:FlxSprite;
	var svCursor:FlxSprite;
	var hueBar:FlxSprite;
	var hueCursor:FlxSprite;
	var hue:Float = 0; // 0-360
	var sat:Float = 0; // 0-1
	var val:Float = 1; // 0-1
	var lastBuiltHue:Float = -1;
	var isDraggingSV:Bool = false;
	var isDraggingHue:Bool = false;
	var syncingSteppers:Bool = false;

	static inline final SWATCH_WIDTH:Float = 60;
	static inline final POPUP_WIDTH:Float = 202;
	static inline final GRID_SWATCH:Float = 24;
	static inline final GRID_SPACING:Float = 6;
	static inline final GRID_COLS:Int = 6;
	static inline final PANEL_PADDING:Float = 10;
	static inline final SV_BOX_W:Float = 150;
	static inline final SV_BOX_H:Float = 120;
	static inline final HUE_BAR_W:Float = 22;
	static inline final HUE_GAP:Float = 10;

	/**
	 * Only one color picker popup open at a time.
	 */
	static var openPicker:UIColorPicker;

	/**
	 * True while any color picker's popup is open. Other controls should
	 * ignore mouse clicks while this is true, since the picker's popup
	 * (which lives on the overlay layer) is meant to be the only thing
	 * receiving input until it's closed.
	 */
	public static function isAnyOpen():Bool return openPicker != null;

	static var clickConsumedAt:Float = -1;
	static inline final CLICK_CONSUME_WINDOW_MS:Float = 4;

	static inline function consumeClick():Void clickConsumedAt = openfl.Lib.getTimer();

	static inline function clickAlreadyConsumed():Bool return (openfl.Lib.getTimer() - clickConsumedAt) < CLICK_CONSUME_WINDOW_MS;

	static var presets:Array<FlxColor> = [
		0xFFE85D5D, 0xFFE8A15D, 0xFFE8D65D, 0xFFA0E85D, 0xFF5DE87A, 0xFF5DE8CB,
		0xFF5DB8E8, 0xFF5D7DE8, 0xFF8A5DE8, 0xFFD65DE8, 0xFFE85DA0, 0xFFFFFFFF
	];

	var _mp:flixel.math.FlxPoint = flixel.math.FlxPoint.get();
	var defaultColor:FlxColor;

	public function new(x:Float, y:Float, width:Float, labelText:String, defaultColor:FlxColor, ?iconGraphic:Dynamic)
	{
		super(x, y, width, labelText, iconGraphic);
		this.defaultColor = defaultColor;

		swatch = new FlxSprite();
		swatch.loadGraphic(
			RoundedRectCache.get(Std.int(SWATCH_WIDTH), Std.int(rowHeight - 6), UITheme.CORNER_RADIUS - 2, FlxColor.WHITE, UITheme.CONTROL_BORDER, 1)
		);
		swatch.y = (rowHeight - swatch.height) / 2;
		addValueWidget(swatch, SWATCH_WIDTH);

		popup = new FlxSpriteGroup(swatch.x, swatch.y + rowHeight + 2);
		popup.visible = false;
		buildPopup();

		value = defaultColor;
	}

	override function set_x(Value:Float):Float
	{
		var delta = Value - x;
		super.set_x(Value);
		if (popup != null) popup.x += delta;
		return Value;
	}

	override function set_y(Value:Float):Float
	{
		var delta = Value - y;
		super.set_y(Value);
		if (popup != null) popup.y += delta;
		return Value;
	}

	function buildPopup():Void
	{
		final gridHeight = Math.ceil(presets.length / GRID_COLS) * (GRID_SWATCH + GRID_SPACING) - GRID_SPACING;

		final stepperRowH = UITheme.ROW_HEIGHT + UITheme.ROW_SPACING;
		popupHeight = PANEL_PADDING + SV_BOX_H + PANEL_PADDING + gridHeight + PANEL_PADDING + stepperRowH * 3 - UITheme.ROW_SPACING + PANEL_PADDING;

		var panel = new FlxSprite();
		panel.loadGraphic(
			RoundedRectCache.get(Std.int(POPUP_WIDTH), Std.int(popupHeight), UITheme.CORNER_RADIUS - 2, UITheme.PANEL_BG, UITheme.CONTROL_BORDER, 1)
		);
		popup.add(panel);

		svBox = new FlxSprite(PANEL_PADDING, PANEL_PADDING);
		svBox.pixels = buildSVBoxBitmap(hue);
		lastBuiltHue = hue;
		popup.add(svBox);

		hueBar = new FlxSprite(PANEL_PADDING + SV_BOX_W + HUE_GAP, PANEL_PADDING);
		hueBar.pixels = buildHueBarBitmap();
		popup.add(hueBar);

		svCursor = new FlxSprite();
		svCursor.loadGraphic(RoundedRectCache.get(10, 10, 5, FlxColor.TRANSPARENT, FlxColor.WHITE, 2));
		popup.add(svCursor);

		hueCursor = new FlxSprite();
		hueCursor.loadGraphic(RoundedRectCache.get(Std.int(HUE_BAR_W + 4), 4, 2, FlxColor.TRANSPARENT, FlxColor.WHITE, 2));
		popup.add(hueCursor);

		final gridY = PANEL_PADDING + SV_BOX_H + PANEL_PADDING;

		selectionRing = new FlxSprite();
		selectionRing.loadGraphic(RoundedRectCache.get(Std.int(GRID_SWATCH + 6), Std.int(GRID_SWATCH + 6), 6, FlxColor.WHITE, UITheme.CONTROL_BORDER, 2));
		selectionRing.color = UITheme.ACCENT;
		selectionRing.visible = false;
		popup.add(selectionRing);

		for (i in 0...presets.length)
		{
			final col = i % GRID_COLS;
			final row = Std.int(i / GRID_COLS);
			var sw = new FlxSprite(PANEL_PADDING + col * (GRID_SWATCH + GRID_SPACING), gridY + row * (GRID_SWATCH + GRID_SPACING));
			sw.loadGraphic(RoundedRectCache.get(Std.int(GRID_SWATCH), Std.int(GRID_SWATCH), 5, FlxColor.WHITE, UITheme.CONTROL_BORDER, 1));
			sw.color = presets[i];
			popup.add(sw);
			swatches.push(sw);
		}

		final stepperY = gridY + gridHeight + PANEL_PADDING;
		final stepperWidth = POPUP_WIDTH - PANEL_PADDING * 2;
		final stepperStride = UITheme.ROW_HEIGHT + UITheme.ROW_SPACING;

		rStepper = new UIStepper(PANEL_PADDING, stepperY, stepperWidth, "R:", 0, 255, 255, 5);
		gStepper = new UIStepper(PANEL_PADDING, stepperY + stepperStride, stepperWidth, "G:", 0, 255, 255, 5);
		bStepper = new UIStepper(PANEL_PADDING, stepperY + stepperStride * 2, stepperWidth, "B:", 0, 255, 255, 5);
		rStepper.allowDuringColorPicker = gStepper.allowDuringColorPicker = bStepper.allowDuringColorPicker = true;

		rStepper.onChange = (_) -> applyFromSteppers();
		gStepper.onChange = (_) -> applyFromSteppers();
		bStepper.onChange = (_) -> applyFromSteppers();

		popup.add(rStepper);
		popup.add(gStepper);
		popup.add(bStepper);
	}

	function get_value():FlxColor return _value;

	function set_value(v:FlxColor):FlxColor
	{
		applyColor(v, true, true);
		positionCursors();
		return _value;
	}

	function applyColor(v:FlxColor, syncSteppers:Bool, syncHSV:Bool):Void
	{
		_value = v;
		if (swatch != null) swatch.color = v;
		if (syncSteppers) syncSteppersFromValue();
		if (syncHSV) syncHSVFromValue();
		updateSelectionRing();
	}

	function syncSteppersFromValue():Void
	{
		if (rStepper == null || gStepper == null || bStepper == null) return;
		syncingSteppers = true;
		rStepper.value = _value.red;
		gStepper.value = _value.green;
		bStepper.value = _value.blue;
		syncingSteppers = false;
	}

	function applyFromSteppers():Void
	{
		if (syncingSteppers) return;
		applyColor(FlxColor.fromRGB(rStepper.value, gStepper.value, bStepper.value), false, true);
		positionCursors();
		if (onChange != null) onChange(_value);
	}

	function syncHSVFromValue():Void
	{
		final hsv = colorToHSV(_value);
		hue = hsv.h;
		sat = hsv.s;
		val = hsv.v;
		rebuildSVBoxIfNeeded();
	}

	function updateSelectionRing():Void
	{
		if (selectionRing == null) return;
		for (i in 0...presets.length)
		{
			if (presets[i] == _value)
			{
				selectionRing.setPosition(swatches[i].x - 3, swatches[i].y - 3);
				selectionRing.visible = true;
				return;
			}
		}
		selectionRing.visible = false;
	}

	function rebuildSVBoxIfNeeded():Void
	{
		if (svBox == null) return;
		// Regenerating the full 150x120 bitmap on every fractional hue
		// change (as would happen every frame of a hue drag) is wasteful!
		// only rebuild once the hue has moved enough to matter visually...
		if (lastBuiltHue >= 0 && Math.abs(hue - lastBuiltHue) < 1.5) return;
		lastBuiltHue = hue;
		svBox.pixels = buildSVBoxBitmap(hue);
	}

	function positionCursors():Void
	{
		if (svCursor != null)
		{
			svCursor.x = svBox.x + sat * (SV_BOX_W - 1) - svCursor.width / 2;
			svCursor.y = svBox.y + (1 - val) * (SV_BOX_H - 1) - svCursor.height / 2;
		}
		if (hueCursor != null)
		{
			hueCursor.x = hueBar.x - 2;
			hueCursor.y = hueBar.y + (hue / 360) * (SV_BOX_H - 1) - hueCursor.height / 2;
		}
	}

	function updateSVFromMouse():Void
	{
		final mp = FlxG.mouse.getWorldPosition(null, _mp);
		sat = flixel.math.FlxMath.bound((mp.x - svBox.x) / (SV_BOX_W - 1), 0, 1);
		val = flixel.math.FlxMath.bound(1 - (mp.y - svBox.y) / (SV_BOX_H - 1), 0, 1);
		applyHSVDrag();
	}

	function updateHueFromMouse():Void
	{
		final mp = FlxG.mouse.getWorldPosition(null, _mp);
		hue = flixel.math.FlxMath.bound((mp.y - hueBar.y) / (SV_BOX_H - 1), 0, 1) * 360;
		rebuildSVBoxIfNeeded();
		applyHSVDrag();
	}

	function applyHSVDrag():Void
	{
		applyColor(hsvToColor(hue, sat, val), true, false);
		positionCursors();
		if (onChange != null) onChange(_value);
	}

	static function buildSVBoxBitmap(hue:Float):openfl.display.BitmapData
	{
		var bmp = new openfl.display.BitmapData(Std.int(SV_BOX_W), Std.int(SV_BOX_H), false);
		for (yy in 0...Std.int(SV_BOX_H))
		{
			final v = 1 - yy / (SV_BOX_H - 1);
			for (xx in 0...Std.int(SV_BOX_W))
			{
				final s = xx / (SV_BOX_W - 1);
				bmp.setPixel32(xx, yy, hsvToColor(hue, s, v));
			}
		}
		return bmp;
	}

	static function buildHueBarBitmap():openfl.display.BitmapData
	{
		var bmp = new openfl.display.BitmapData(Std.int(HUE_BAR_W), Std.int(SV_BOX_H), false);
		for (yy in 0...Std.int(SV_BOX_H))
		{
			final h = yy / (SV_BOX_H - 1) * 360;
			final c:Int = hsvToColor(h, 1, 1);
			for (xx in 0...Std.int(HUE_BAR_W)) bmp.setPixel32(xx, yy, c);
		}
		return bmp;
	}

	static function hsvToColor(h:Float, s:Float, v:Float):FlxColor
	{
		final c = v * s;
		final hh = (h % 360) / 60;
		final x = c * (1 - Math.abs(hh % 2 - 1));
		var r = 0.0, g = 0.0, b = 0.0;
		if (hh < 1)
		{
			r = c;
			g = x;
			b = 0;
		}
		else if (hh < 2)
		{
			r = x;
			g = c;
			b = 0;
		}
		else if (hh < 3)
		{
			r = 0;
			g = c;
			b = x;
		}
		else if (hh < 4)
		{
			r = 0;
			g = x;
			b = c;
		}
		else if (hh < 5)
		{
			r = x;
			g = 0;
			b = c;
		}
		else
		{
			r = c;
			g = 0;
			b = x;
		}
		final m = v - c;
		return FlxColor.fromRGBFloat(r + m, g + m, b + m);
	}

	static function colorToHSV(color:FlxColor):
		{h:Float, s:Float, v:Float}
	{
		// yummies
		final r = color.redFloat, g = color.greenFloat, b = color.blueFloat;
		final max = Math.max(r, Math.max(g, b));
		final min = Math.min(r, Math.min(g, b));
		final delta = max - min;
		var h = 0.0;
		if (delta > 0.00001)
		{
			if (max == r) h = 60 * (((g - b) / delta) % 6);
			else if (max == g) h = 60 * (((b - r) / delta) + 2);
			else
				h = 60 * (((r - g) / delta) + 4);
		}
		if (h < 0) h += 360;
		final s = max <= 0 ? 0.0 : delta / max;
		return {
			h: h,
			s: s,
			v: max
		};
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (isDraggingSV || isDraggingHue)
		{
			if (FlxG.mouse.pressed)
			{
				if (isDraggingSV) updateSVFromMouse();
				else
					updateHueFromMouse();
			}
			else
			{
				isDraggingSV = false;
				isDraggingHue = false;
			}
		}

		if (FlxG.mouse.justPressedMiddle)
		{
			final mp = FlxG.mouse.getWorldPosition(null, _mp);
			if (containsPoint(mp, swatch.x, swatch.y, swatch.width, swatch.height))
			{
				if (isOpen) toggleOpen(false);
				if (_value != defaultColor)
				{
					applyColor(defaultColor, true, true);
					positionCursors();
					if (onChange != null) onChange(_value);
				}
			}
			return;
		}

		if (!FlxG.mouse.justPressed) return;
		if (clickAlreadyConsumed()) return;
		if (
			openPicker != null
			&& openPicker != this
			&& !containsPoint(FlxG.mouse.getWorldPosition(null, _mp), swatch.x, swatch.y, swatch.width, swatch.height)
		) return;

		final mp = FlxG.mouse.getWorldPosition(null, _mp);

		// This picker's own swatch always toggles it, even while another
		// picker's popup is currently open.
		if (containsPoint(mp, swatch.x, swatch.y, swatch.width, swatch.height))
		{
			if (openPicker != null && openPicker != this) openPicker.toggleOpen(false);
			toggleOpen();
			consumeClick();
			return;
		}

		if (!isOpen) return;

		for (i in 0...swatches.length)
		{
			if (containsPoint(mp, swatches[i].x, swatches[i].y, swatches[i].width, swatches[i].height))
			{
				applyColor(presets[i], true, true);
				positionCursors();
				if (onChange != null) onChange(_value);
				consumeClick();
				return;
			}
		}

		if (containsPoint(mp, svBox.x, svBox.y, SV_BOX_W, SV_BOX_H))
		{
			isDraggingSV = true;
			updateSVFromMouse();
			consumeClick();
			return;
		}

		if (containsPoint(mp, hueBar.x, hueBar.y, HUE_BAR_W, SV_BOX_H))
		{
			isDraggingHue = true;
			updateHueFromMouse();
			consumeClick();
			return;
		}

		if (containsPoint(mp, popup.x, popup.y, POPUP_WIDTH, popupHeight)) return;

		toggleOpen(false);
	}

	inline function containsPoint(p:flixel.math.FlxPoint, rx:Float, ry:Float, rw:Float, rh:Float):Bool return
		p.x >= rx
		&& p.x <= rx + rw
		&& p.y >= ry
		&& p.y <= ry + rh;

	/**
	 * Places `popup` so it fits on screen.
	 */
	function positionPopup():Void
	{
		final belowY = swatch.y + rowHeight + 2;
		popup.y = (belowY + popupHeight <= FlxG.height) ? belowY : Math.max(0, swatch.y - popupHeight - 2);

		var desiredX = swatch.x;
		if (desiredX + POPUP_WIDTH > FlxG.width) desiredX = FlxG.width - POPUP_WIDTH - 4;
		if (desiredX < 0) desiredX = 4;
		popup.x = desiredX;
	}

	function toggleOpen(?force:Bool):Void
	{
		var newOpen = force != null ? force : !isOpen;
		if (newOpen == isOpen) return;

		isOpen = newOpen;

		if (isOpen)
		{
			openPicker = this;
			positionPopup();
			popup.visible = true;
			if (UIOverlay.layer != null && UIOverlay.layer.members.indexOf(popup) == -1) UIOverlay.layer.add(popup);

			updateSelectionRing();
			syncHSVFromValue();
			positionCursors();
		}
		else
		{
			popup.visible = false;
			isDraggingSV = false;
			isDraggingHue = false;
			if (openPicker == this) openPicker = null;
			if (UIOverlay.layer != null) UIOverlay.layer.remove(popup, true);
		}
	}

	public function forceHideEditorChrome():Void
	{
		if (isOpen) toggleOpen(false);
	}

	override public function destroy():Void
	{
		if (openPicker == this) openPicker = null;
		if (UIOverlay.layer != null) UIOverlay.layer.remove(popup, true);
		if (popup != null) popup.destroy();
		if (_mp != null) _mp.put();
		super.destroy();
	}
}
