package moon.toolkit.ui;

/**
 * A Simple and nice-looking stepper.
 */
class UIStepper extends UIComponent
{
	public var value(get, set):Int;

	@:isVar
	var _value:Int;

	public var min:Int;
	public var max:Int;
	public var step:Int;
	public var onChange:Int->Void;
	public var formatter:Int->String;

	var minusBtn:FlxSprite;
	var plusBtn:FlxSprite;
	var minusLabel:FlxText;
	var plusLabel:FlxText;
	var valueText:FlxText;
	var heldDir:Int = 0; // -1, 0, or 1
	var holdTime:Float = 0;
	var timeSinceLastRepeat:Float = 0;

	static inline final BTN_SIZE:Float = 22;
	static inline final VALUE_WIDTH:Float = 50;
	static inline final HOLD_INITIAL_DELAY:Float = 0.4;
	static inline final HOLD_ACCEL_TIME:Float = 2.0;
	static inline final HOLD_MAX_INTERVAL:Float = 0.35;
	static inline final HOLD_MIN_INTERVAL:Float = 0.03;

	public function new(x:Float, y:Float, width:Float, labelText:String, min:Int, max:Int, defaultValue:Int, step:Int = 1, ?iconGraphic:Dynamic, isVertical:Bool = false)
	{
		super(x, y, width, labelText, iconGraphic);
		this.min = min;
		this.max = max;
		this.step = step;

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

		valueText = new FlxText(minusBtn.x + BTN_SIZE, 0, VALUE_WIDTH, "", UITheme.FONT_SIZE);
		valueText.font = UITheme.FONT;
		valueText.color = UITheme.TEXT_COLOR;
		valueText.alignment = CENTER;
		valueText.y = (rowHeight - valueText.height) / 2;
		valueText.antialiasing = UITheme.FONT_ANTIALIASING;
		valueText.active = false;
		add(valueText);

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
		if (valueText != null) valueText.text = formatter != null ? formatter(_value) : Std.string(_value);
		return _value;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			final mp = FlxG.mouse.getViewPosition();
			if (minusBtn.getScreenBounds().containsPoint(mp))
			{
				applyDelta(-step);
				startHold(-1);
			}
			else if (plusBtn.getScreenBounds().containsPoint(mp))
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
}
