package moon.toolkit.ui;

import moon.toolkit.ui.UIComponent.BGState;

/**
 * Simple click-action button.
 */
class UIActionButton extends FlxSpriteGroup
{
	public var onClick:Void->Void;
	public var labelText(default, set):String;
	public var bg:FlxSprite;
	public var icon:FlxSprite;
	public var label:FlxText;

	var _w:Float;
	var _h:Float;
	var _state:BGState = Normal;
	var _mp:FlxPoint = FlxPoint.get();
	var _enabled:Bool = true;

	public function new(x:Float, y:Float, width:Float, text:String, ?onClick:Void->Void, ?iconGraphic:Dynamic, height:Float = -1)
	{
		super(x, y);

		_w = width;
		_h = height > 0 ? height : UITheme.ROW_HEIGHT;
		this.onClick = onClick;
		labelText = text;

		bg = RoundedRectCache.create(Std.int(_w), Std.int(_h), FlxColor.WHITE);
		bg.color = UITheme.CONTROL_BG;
		bg.active = false;
		add(bg);

		var textX = UITheme.PADDING;

		if (iconGraphic != null)
		{
			icon = new FlxSprite(UITheme.PADDING, 0);
			icon.loadGraphic(iconGraphic);
			icon.setGraphicSize(Std.int(UITheme.ICON_SIZE), Std.int(UITheme.ICON_SIZE));
			icon.updateHitbox();
			icon.y = (_h - icon.height) / 2;
			icon.active = false;
			add(icon);
			textX = icon.x + icon.width + 6;
		}

		label = new FlxText(textX, 0, _w - textX - UITheme.PADDING, text, UITheme.FONT_SIZE);
		label.font = UITheme.FONT;
		label.color = UITheme.TEXT_COLOR;
		label.antialiasing = UITheme.FONT_ANTIALIASING;
		label.y = (_h - label.height) / 2;
		label.active = false;
		add(label);
	}

	public var enabled(get, set):Bool;

	function get_enabled():Bool return _enabled;

	function set_enabled(v:Bool):Bool
	{
		_enabled = v;
		alpha = v ? 1 : 0.45;
		return v;
	}

	function set_labelText(v:String):String
	{
		labelText = v;
		if (label != null) label.text = v;
		return v;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!_enabled) return;

		FlxG.mouse.getWorldPosition(camera, _mp);
		final over = _mp.x >= x && _mp.x <= x + _w && _mp.y >= y && _mp.y <= y + _h;

		if (over && FlxG.mouse.pressed) _setState(Active);
		else if (over) _setState(Hover);
		else
			_setState(Normal);

		if (over && FlxG.mouse.justPressed && onClick != null) onClick();
	}

	function _setState(state:BGState):Void
	{
		if (state == _state) return;
		_state = state;
		bg.color = switch (state)
		{
			case Normal:
				UITheme.CONTROL_BG;
			case Hover:
				UITheme.CONTROL_BG_HOVER;
			case Active:
				UITheme.CONTROL_BG_ACTIVE;
		};
	}

	override public function destroy():Void
	{
		_mp.put();
		super.destroy();
	}
}
