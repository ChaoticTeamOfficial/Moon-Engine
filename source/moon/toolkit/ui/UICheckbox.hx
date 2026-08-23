package moon.toolkit.ui;

class UICheckbox extends UIComponent
{
	public var checked(default, set):Bool = false;
	public var onChange:Bool->Void;

	var box:FlxSprite;
	var checkMark:FlxSprite;
	var defaultChecked:Bool;

	static inline var BOX_SIZE:Float = 20;

	public function new(x:Float, y:Float, width:Float, labelText:String, defaultChecked:Bool = false, ?iconGraphic:Dynamic)
	{
		super(x, y, width, labelText, iconGraphic);
		this.defaultChecked = defaultChecked;

		box = RoundedRectCache.create(Std.int(BOX_SIZE), Std.int(BOX_SIZE), UITheme.CONTROL_BG_HOVER);
		addValueWidget(box, BOX_SIZE);
		box.y = (rowHeight - box.height) / 2;

		checkMark = RoundedRectCache.create(Std.int(BOX_SIZE - 8), Std.int(BOX_SIZE - 8), UITheme.ACCENT);
		checkMark.x = box.x + 4;
		checkMark.y = box.y + 4;
		add(checkMark);
		checkMark.active = box.active = false;

		checked = defaultChecked;
	}

	function set_checked(v:Bool):Bool
	{
		checked = v;
		if (checkMark != null) checkMark.visible = v;
		return v;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (UIEditFocus.isBusy()) return;

		final mp = FlxG.mouse.getWorldPosition();
		if (FlxG.mouse.justPressedMiddle && containsPoint(mp.x, mp.y, box.x, box.y, box.width, box.height))
		{
			if (checked != defaultChecked)
			{
				checked = defaultChecked;
				if (onChange != null) onChange(checked);
			}
			return;
		}

		if (FlxG.mouse.justPressed && containsPoint(mp.x, mp.y, box.x, box.y, box.width, box.height))
		{
			checked = !checked;
			if (onChange != null) onChange(checked);
		}
	}

	inline function containsPoint(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool return
		px >= rx
		&& px <= rx + rw
		&& py >= ry
		&& py <= ry + rh;
}
