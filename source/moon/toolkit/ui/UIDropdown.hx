package moon.toolkit.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;

/**
 * A simple UI dropdown.
 */
class UIDropdown extends UIComponent
{
	public var options:Array<String>;
	public var selectedIndex(default, null):Int = 0;
	public var onChange:String->Void;

	var valueBox:FlxSprite;
	var valueText:FlxText;
	var arrow:FlxText;
	var optionList:FlxSpriteGroup;
	var rowsContainer:FlxSpriteGroup;
	var listScrollTrack:FlxSprite;
	var listScrollThumb:FlxSprite;
	var isOpen:Bool = false;
	var optH:Float;
	var optionTexts:Array<FlxText> = [];
	var visibleCount:Int;
	var listHeight:Float;
	var scrollValue:Float = 0;
	var draggingListThumb:Bool = false;
	var listDragGrabOffset:Float = 0;

	static inline final VALUE_BOX_WIDTH:Float = 130;
	static inline final LIST_SCROLLBAR_WIDTH:Float = 6;

	/**
	 * How many rows show at once before the list scrolls instead of
	 * growing further. Can be overridden per-dropdown via the constructor.
	 */
	public var maxVisibleItems:Int;

	static inline final DEFAULT_MAX_VISIBLE_ITEMS:Int = 8;

	/**
	 * The single dropdown currently open, if any. Used to lock out all others.
	 */
	static var openDropdown:UIDropdown;

	/**
	 * True while any dropdown's option list is open.
	 */
	public static function isAnyOpen():Bool return openDropdown != null;

	static var clickConsumedAt:Float = -1;

	static inline function consumeClick():Void clickConsumedAt = openfl.Lib.getTimer();

	static inline function clickAlreadyConsumed():Bool return clickConsumedAt == openfl.Lib.getTimer();

	public function new(x:Float, y:Float, width:Float, labelText:String, options:Array<String>, ?iconGraphic:Dynamic, defaultIndex:Int = 0, maxVisibleItems:Int = DEFAULT_MAX_VISIBLE_ITEMS)
	{
		super(x, y, width, labelText, iconGraphic);
		this.options = options;
		this.maxVisibleItems = maxVisibleItems;
		selectedIndex = defaultIndex;
		optH = rowHeight - 6;

		valueBox = new FlxSprite();
		valueBox.loadGraphic(
			RoundedRectCache.get(
				Std.int(VALUE_BOX_WIDTH),
				Std.int(rowHeight - 6),
				UITheme.CORNER_RADIUS - 2,
				UITheme.CONTROL_BG_HOVER,
				UITheme.CONTROL_BORDER,
				1
			)
		);
		valueBox.y = (rowHeight - valueBox.height) / 2;
		addValueWidget(valueBox, VALUE_BOX_WIDTH);

		valueText = new FlxText(valueBox.x + 8, 0, VALUE_BOX_WIDTH - 24, options[defaultIndex], UITheme.FONT_SIZE);
		valueText.font = UITheme.FONT;
		valueText.color = UITheme.TEXT_COLOR;
		valueText.y = (rowHeight - valueText.height) / 2;
		add(valueText);

		arrow = new FlxText(valueBox.x + VALUE_BOX_WIDTH - 20, 0, 16, "v", UITheme.FONT_SIZE);
		arrow.font = UITheme.FONT;
		arrow.color = UITheme.TEXT_DIM;
		arrow.y = (rowHeight - arrow.height) / 2;
		add(arrow);

		optionList = new FlxSpriteGroup(valueBox.x, valueBox.y + rowHeight + 2);
		optionList.visible = false;
		buildOptionList();
	}

	override function set_x(Value:Float):Float
	{
		var delta = Value - x;
		super.set_x(Value);
		if (optionList != null) optionList.x += delta;
		return Value;
	}

	override function set_y(Value:Float):Float
	{
		var delta = Value - y;
		super.set_y(Value);
		if (optionList != null) optionList.y += delta;
		return Value;
	}

	function buildOptionList():Void
	{
		optionList.clear();
		optionTexts = [];

		visibleCount = Std.int(Math.max(1, Math.min(options.length, maxVisibleItems)));
		listHeight = optH * visibleCount;
		final needsScroll = options.length > visibleCount;
		final textWidth = VALUE_BOX_WIDTH - 16 - (needsScroll ? LIST_SCROLLBAR_WIDTH + 4 : 0);

		var panel = new FlxSprite();
		panel.loadGraphic(
			RoundedRectCache.get(Std.int(VALUE_BOX_WIDTH), Std.int(listHeight), UITheme.CORNER_RADIUS - 2, UITheme.PANEL_BG, UITheme.CONTROL_BORDER, 1)
		);
		optionList.add(panel);

		rowsContainer = new FlxSpriteGroup();
		optionList.add(rowsContainer);

		for (i in 0...options.length)
		{
			var t = new FlxText(8, i * optH + (optH - 16) / 2, textWidth, options[i], UITheme.FONT_SIZE);
			t.font = UITheme.FONT;
			t.color = (i == selectedIndex) ? UITheme.ACCENT : UITheme.TEXT_COLOR;
			rowsContainer.add(t);
			optionTexts.push(t);
		}

		if (needsScroll)
		{
			listScrollTrack = new FlxSprite(VALUE_BOX_WIDTH - LIST_SCROLLBAR_WIDTH, 0);
			listScrollTrack.loadGraphic(
				RoundedRectCache.get(Std.int(LIST_SCROLLBAR_WIDTH), Std.int(listHeight), LIST_SCROLLBAR_WIDTH / 2, UITheme.CONTROL_BG)
			);
			optionList.add(listScrollTrack);

			final thumbH = Math.max(16, listHeight * (visibleCount / options.length));
			listScrollThumb = new FlxSprite(VALUE_BOX_WIDTH - LIST_SCROLLBAR_WIDTH, 0);
			listScrollThumb.loadGraphic(RoundedRectCache.get(Std.int(LIST_SCROLLBAR_WIDTH), Std.int(thumbH), LIST_SCROLLBAR_WIDTH / 2, UITheme.ACCENT));
			optionList.add(listScrollThumb);
		}
		else
		{
			listScrollTrack = null;
			listScrollThumb = null;
		}

		scrollValue = 0;
		applyListScroll();
	}

	function refreshSelectedColor(previous:Int):Void
	{
		if (previous >= 0 && previous < optionTexts.length) optionTexts[previous].color = UITheme.TEXT_COLOR;
		if (selectedIndex >= 0 && selectedIndex < optionTexts.length) optionTexts[selectedIndex].color = UITheme.ACCENT;
	}

	inline function maxListScroll():Float return Math.max(0, (options.length - visibleCount) * optH);

	/**
	 * Re-clamps `scrollValue`, moves the rows to match, updates which rows
	 * are visible, and updates the thumb.
	 */
	function applyListScroll():Void
	{
		scrollValue = FlxMath.bound(scrollValue, 0, maxListScroll());
		rowsContainer.y = optionList.y - scrollValue;
		updateListRowClipping();
		updateListThumbPosition();
	}

	function updateListRowClipping():Void
	{
		final top = optionList.y;
		final bottom = optionList.y + listHeight;
		for (t in optionTexts)
		{
			final centerY = t.y + t.height / 2;
			t.visible = centerY >= top && centerY <= bottom;
		}
	}

	function updateListThumbPosition():Void
	{
		if (listScrollThumb == null) return;
		final travel = listHeight - listScrollThumb.height;
		final maxS = maxListScroll();
		final ratio = maxS > 0 ? scrollValue / maxS : 0;
		listScrollThumb.y = optionList.y + travel * ratio;
	}

	function dragListThumbTo(mouseY:Float):Void
	{
		final travel = listHeight - listScrollThumb.height;
		scrollValue = (travel > 0 ? FlxMath.bound((mouseY - listDragGrabOffset - optionList.y) / travel, 0, 1) : 0) * maxListScroll();
		applyListScroll();
	}

	/**
	 * Places `optionList` so it fits on screen.
	 */
	function positionOptionList():Void
	{
		final belowY = valueBox.y + rowHeight + 2;
		optionList.y = (belowY + listHeight <= FlxG.height) ? belowY : Math.max(0, valueBox.y - listHeight - 2);

		var desiredX = valueBox.x;
		if (desiredX + VALUE_BOX_WIDTH > FlxG.width) desiredX = FlxG.width - VALUE_BOX_WIDTH - 4;
		if (desiredX < 0) desiredX = 4;
		optionList.x = desiredX;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (isOpen)
		{
			final mouse = FlxG.mouse.getWorldPosition();
			final overList = containsPoint(mouse.x, mouse.y, optionList.x, optionList.y, VALUE_BOX_WIDTH, listHeight);

			if (draggingListThumb)
			{
				if (FlxG.mouse.pressed) dragListThumbTo(mouse.y);
				else
					draggingListThumb = false;
			}
			else if (
				FlxG.mouse.justPressed
				&& listScrollThumb != null
				&& containsPoint(mouse.x, mouse.y, listScrollThumb.x, listScrollThumb.y, LIST_SCROLLBAR_WIDTH, listScrollThumb.height)
			)
			{
				draggingListThumb = true;
				listDragGrabOffset = mouse.y - listScrollThumb.y;
			}

			if (overList && FlxG.mouse.wheel != 0)
			{
				scrollValue -= FlxG.mouse.wheel * optH;
				applyListScroll();
			}
		}

		if (!FlxG.mouse.justPressed) return;
		if (clickAlreadyConsumed()) return; // some other dropdown already handled this exact click...
		if (draggingListThumb) return; // this click just started a thumb drag, don't also select/close

		if (openDropdown != null && openDropdown != this) return;

		var mouse = FlxG.mouse.getWorldPosition();

		if (containsPoint(mouse.x, mouse.y, valueBox.x, valueBox.y, valueBox.width, valueBox.height))
		{
			toggleOpen();
			consumeClick();
			return;
		}

		if (isOpen)
		{
			final onScrollbar =
				listScrollTrack != null
				&& containsPoint(mouse.x, mouse.y, listScrollTrack.x, listScrollTrack.y, LIST_SCROLLBAR_WIDTH, listHeight);

			if (!onScrollbar && containsPoint(mouse.x, mouse.y, optionList.x, optionList.y, VALUE_BOX_WIDTH, listHeight))
			{
				var idx = Std.int((mouse.y - optionList.y + scrollValue) / optH);
				if (idx >= 0 && idx < options.length) select(idx);
			}

			if (!onScrollbar) toggleOpen(false);
			consumeClick();
		}
	}

	inline function containsPoint(px:Float, py:Float, rx:Float, ry:Float, rw:Float, rh:Float):Bool return
		px >= rx
		&& px <= rx + rw
		&& py >= ry
		&& py <= ry + rh;

	function toggleOpen(?force:Bool):Void
	{
		var newOpen = force != null ? force : !isOpen;
		if (newOpen == isOpen) return;

		isOpen = newOpen;

		if (isOpen)
		{
			openDropdown = this;
			positionOptionList();

			// Scroll so the current selection starts in view instead of always opening back at the top of a long list.
			scrollValue = FlxMath.bound((selectedIndex - Std.int((visibleCount - 1) / 2)) * optH, 0, maxListScroll());
			applyListScroll();

			optionList.visible = true;
			if (UIOverlay.layer != null && UIOverlay.layer.members.indexOf(optionList) == -1) UIOverlay.layer.add(optionList);
		}
		else
		{
			optionList.visible = false;
			draggingListThumb = false;
			if (openDropdown == this) openDropdown = null;
			if (UIOverlay.layer != null) UIOverlay.layer.remove(optionList, true);
		}
	}

	function select(index:Int):Void
	{
		final previous = selectedIndex;
		selectedIndex = index;
		valueText.text = options[index];
		refreshSelectedColor(previous);
		if (onChange != null) onChange(options[index]);
	}

	override public function destroy():Void
	{
		if (openDropdown == this) openDropdown = null;
		if (UIOverlay.layer != null) UIOverlay.layer.remove(optionList, true);
		if (optionList != null) optionList.destroy();
		super.destroy();
	}
}
