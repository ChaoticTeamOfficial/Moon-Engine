package moon.toolkit.ui;

/**
 * Base class for every control (dropdown, textbox, checkbox, stepper,
 * slider, button list...).
 */
class UIComponent extends FlxSpriteGroup
{
	public var background:FlxSprite;
	public var icon:FlxSprite;
	public var label:FlxText;
	public var rowWidth:Float;
	public var rowHeight:Float;

	var valueStartX:Float;
	var bgState:BGState = Normal;

	public function new(x:Float, y:Float, width:Float, labelText:String, ?iconGraphic:Dynamic, height:Float = -1)
	{
		super(x, y);

		rowWidth = width;
		rowHeight = height > 0 ? height : UITheme.ROW_HEIGHT;

		background = RoundedRectCache.create(Std.int(rowWidth), Std.int(rowHeight), FlxColor.WHITE);
		background.color = UITheme.CONTROL_BG;
		background.active = false;
		add(background);

		var textX = UITheme.PADDING;

		if (iconGraphic != null)
		{
			icon = new FlxSprite(UITheme.PADDING, 0);
			icon.loadGraphic(iconGraphic);
			icon.setGraphicSize(Std.int(UITheme.ICON_SIZE), Std.int(UITheme.ICON_SIZE));
			icon.updateHitbox();
			icon.y = (rowHeight - icon.height) / 2;
			add(icon);
			icon.active = false;
			textX = icon.x + icon.width + 6;
		}

		label = new FlxText(textX, 0, rowWidth * 0.5, labelText, UITheme.FONT_SIZE);
		label.font = UITheme.FONT;
		label.color = UITheme.TEXT_COLOR;
		label.y = (rowHeight - label.height) / 2;
		add(label);
		label.active = false;
		label.antialiasing = UITheme.FONT_ANTIALIASING;

		valueStartX = rowWidth * 0.55;
	}

	function addValueWidget(widget:FlxSprite, ?rightAlignWidth:Float):Void
	{
		if (rightAlignWidth != null) widget.x = rowWidth - UITheme.PADDING - rightAlignWidth;
		else
			widget.x = valueStartX;

		add(widget);
	}

	function setBackgroundState(state:BGState):Void
	{
		if (state == bgState) return;
		bgState = state;

		background.color = switch (state)
		{
			case Normal:
				UITheme.CONTROL_BG;
			case Hover:
				UITheme.CONTROL_BG_HOVER;
			case Active:
				UITheme.CONTROL_BG_ACTIVE;
		}
	}
}

enum BGState
{
	Normal;
	Hover;
	Active;
}
