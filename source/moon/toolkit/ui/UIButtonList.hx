package moon.toolkit.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

enum ButtonListLayout
{
	Horizontal;
	Vertical;
}

/**
 * Pill-style button row/column.
 */
class UIButtonList extends FlxSpriteGroup
{
	public var labels:Array<String>;
	public var selectedIndex(default, null):Int = 0;
	public var onSelect:Int->String->Void;
	public var onExtra:Void->Void;

	var pills:Array<FlxSprite> = [];
	var pillLabels:Array<FlxText> = [];
	var extraBtn:FlxSprite;

	public function new(x:Float, y:Float, labels:Array<String>, layout:ButtonListLayout = Horizontal, defaultIndex:Int = 0, showExtraButton:Bool = false, pillHeight:Float = 28, spacing:Float = 8)
	{
		super(x, y);
		this.labels = labels;
		selectedIndex = defaultIndex;

		var cursor = 0.0;
		for (i in 0...labels.length)
		{
			final w = estimateTextWidth(labels[i]);
			var pill = RoundedRectCache.create(Std.int(w), Std.int(pillHeight), FlxColor.WHITE);
			final isSel = i == defaultIndex;

			pill.color = isSel ? UITheme.ACCENT : UITheme.CONTROL_BG;
			pill.active = false;

			var lbl = new FlxText(0, 0, w, labels[i], UITheme.FONT_SIZE);
			lbl.font = UITheme.FONT;
			lbl.color = isSel ? FlxColor.WHITE : UITheme.TEXT_COLOR;
			lbl.alignment = CENTER;
			lbl.antialiasing = UITheme.FONT_ANTIALIASING;
			lbl.active = false;

			if (layout == Horizontal)
			{
				pill.x = cursor;
				lbl.x = cursor;
				cursor += w + spacing;
			}
			else
			{
				pill.y = cursor;
				lbl.y = cursor;
				cursor += pillHeight + spacing;
			}
			lbl.y += (pillHeight - lbl.height) / 2;

			add(pill);
			add(lbl);
			pills.push(pill);
			pillLabels.push(lbl);
		}

		if (showExtraButton)
		{
			extraBtn = RoundedRectCache.create(Std.int(pillHeight), Std.int(pillHeight), FlxColor.WHITE);
			extraBtn.color = UITheme.CONTROL_BG_HOVER;
			extraBtn.active = false;

			var plus = new FlxText(0, 0, pillHeight, "+", UITheme.FONT_SIZE);
			plus.font = UITheme.FONT;
			plus.color = UITheme.TEXT_COLOR;
			plus.alignment = CENTER;
			plus.antialiasing = UITheme.FONT_ANTIALIASING;
			plus.active = false;

			if (layout == Horizontal)
			{
				extraBtn.x = cursor;
				plus.x = cursor;
			}
			else
			{
				extraBtn.y = cursor;
				plus.y = cursor;
			}
			plus.y += (pillHeight - plus.height) / 2;
			add(extraBtn);
			add(plus);
		}
	}

	function estimateTextWidth(s:String):Float
	{
		return Math.max(50, s.length * (UITheme.FONT_SIZE * 0.62) + 24);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!FlxG.mouse.justPressed) return;

		var mp = FlxG.mouse.getWorldPosition();
		for (i in 0...pills.length)
		{
			if (containsPoint(mp.x, mp.y, pills[i].x, pills[i].y, pills[i].width, pills[i].height))
			{
				select(i);
				return;
			}
		}
		if (extraBtn != null && containsPoint(mp.x, mp.y, extraBtn.x, extraBtn.y, extraBtn.width, extraBtn.height) && onExtra != null) onExtra();
	}

	inline function containsPoint(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool return
		px >= rx
		&& px <= rx + rw
		&& py >= ry
		&& py <= ry + rh;

	function select(index:Int):Void
	{
		if (index == selectedIndex) return;

		pills[selectedIndex].color = UITheme.CONTROL_BG;
		pillLabels[selectedIndex].color = UITheme.TEXT_COLOR;

		selectedIndex = index;
		pills[index].color = UITheme.ACCENT;
		pillLabels[index].color = FlxColor.WHITE;

		if (onSelect != null) onSelect(index, labels[index]);
	}
}
