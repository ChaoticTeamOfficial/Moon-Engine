package moon.toolkit.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

/**
 * A `UIPage` that clips its content to a fixed `viewWidth` x `viewHeight`
 * window and lets you scroll tharough content taller than that window!
 */
class UIScrollPage extends UIPage
{
	public var viewWidth(default, null):Float;
	public var viewHeight(default, null):Float;

	/**
	 * Total scrollable content height, in pixels. Kept up to date by `layoutVertical`.
	 */
	public var contentHeight(default, null):Float = 0;

	/**
	 * Current scroll offset (0 = top).
	 */
	public var scrollY(default, set):Float = 0;

	public var scrollSpeed:Float = 40;

	/**
	 * The group everything added via `addComponent` actually lives in.
	 */
	public var content(default, null):FlxSpriteGroup;

	var panelBg:FlxSprite;
	var scrollTrack:FlxSprite;
	var scrollThumb:FlxSprite;

	static inline var SCROLLBAR_WIDTH:Float = 8;
	static inline var SCROLLBAR_GAP:Float = 4;
	static inline var SCROLLBAR_MIN_THUMB:Float = 24;

	var scrollbarX:Float;
	var draggingThumb:Bool = false;
	var dragGrabOffset:Float = 0;
	var _mp:FlxPoint = FlxPoint.get();

	public function new(x:Float, y:Float, viewWidth:Float, viewHeight:Float, title:String = "")
	{
		super(x, y, title);

		this.viewWidth = viewWidth;
		this.viewHeight = viewHeight;
		scrollbarX = viewWidth + SCROLLBAR_GAP;

		panelBg = new FlxSprite();
		panelBg.loadGraphic(RoundedRectCache.get(Std.int(viewWidth), Std.int(viewHeight), UITheme.CORNER_RADIUS, UITheme.PANEL_BG));
		add(panelBg);

		content = new FlxSpriteGroup();
		add(content);

		scrollTrack = new FlxSprite(scrollbarX, 0);
		scrollTrack.loadGraphic(RoundedRectCache.get(Std.int(SCROLLBAR_WIDTH), Std.int(viewHeight), SCROLLBAR_WIDTH / 2, UITheme.CONTROL_BG));
		scrollTrack.visible = false;
		add(scrollTrack);

		scrollThumb = new FlxSprite(scrollbarX, 0);
		scrollThumb.loadGraphic(RoundedRectCache.get(Std.int(SCROLLBAR_WIDTH), Std.int(viewHeight), SCROLLBAR_WIDTH / 2, UITheme.ACCENT));
		scrollThumb.visible = false;
		add(scrollThumb);
	}

	/**
	 * Adds a component to the scrollable content area (not directly to the page).
	 */
	override public function addComponent(component:UIComponent):UIComponent
	{
		content.add(component);
		return component;
	}

	/**
	 * Lay out content components in a vertical stack, then recompute the
	 * scrollable range and scrollbar thumb size/visibility.
	 */
	override public function layoutVertical(startY:Float = 0):Void
	{
		content.y = y;

		var localY = startY;
		for (member in content.members)
		{
			if (member == null) continue;
			member.y = content.y + localY;
			localY += (Std.isOfType(member, UIComponent) ? cast(member, UIComponent).rowHeight : member.height) + UITheme.ROW_SPACING;
		}

		contentHeight = Math.max(0, localY - UITheme.ROW_SPACING);
		refreshScrollbar();
		content.y -= scrollY;
		updateRowClipping();
	}

	/**
	 * Change the visible viewport size at runtime.
	 */
	public function setViewSize(newWidth:Float, newHeight:Float):Void
	{
		viewWidth = newWidth;
		viewHeight = newHeight;
		scrollbarX = viewWidth + SCROLLBAR_GAP;

		panelBg.loadGraphic(RoundedRectCache.get(Std.int(viewWidth), Std.int(viewHeight), UITheme.CORNER_RADIUS, UITheme.PANEL_BG));
		scrollTrack.loadGraphic(RoundedRectCache.get(Std.int(SCROLLBAR_WIDTH), Std.int(viewHeight), SCROLLBAR_WIDTH / 2, UITheme.CONTROL_BG));
		scrollTrack.x = x + scrollbarX;

		refreshScrollbar();
		scrollY = scrollY;
		updateRowClipping();
	}

	inline function maxScroll():Float return Math.max(0, contentHeight - viewHeight);

	function set_scrollY(v:Float):Float
	{
		final clamped = Math.max(0, Math.min(maxScroll(), v));
		final delta = clamped - scrollY;
		if (delta != 0) content.y -= delta;

		scrollY = clamped;
		updateThumbPosition();
		updateRowClipping();
		return scrollY;
	}

	function refreshScrollbar():Void
	{
		final needsScroll = contentHeight > viewHeight;
		scrollTrack.visible = needsScroll;
		scrollThumb.visible = needsScroll;

		if (!needsScroll)
		{
			scrollThumb.loadGraphic(RoundedRectCache.get(Std.int(SCROLLBAR_WIDTH), Std.int(viewHeight), SCROLLBAR_WIDTH / 2, UITheme.ACCENT));
			return;
		}

		final thumbHeight = Math.max(SCROLLBAR_MIN_THUMB, viewHeight * (viewHeight / contentHeight));
		scrollThumb.loadGraphic(RoundedRectCache.get(Std.int(SCROLLBAR_WIDTH), Std.int(thumbHeight), SCROLLBAR_WIDTH / 2, UITheme.ACCENT));
		scrollThumb.x = x + scrollbarX; // world x = page's x + local scrollbar offset
		updateThumbPosition();
	}

	function updateThumbPosition():Void
	{
		if (!scrollThumb.visible) return;
		final travel = viewHeight - scrollThumb.height;
		final ratio = maxScroll() > 0 ? scrollY / maxScroll() : 0;
		scrollThumb.y = y + travel * ratio;
	}

	/**
	 * Hides (and deactivates, so they stop taking input) any content
	 * components.
	 */
	function updateRowClipping():Void
	{
		final top = y;
		final bottom = y + viewHeight;

		for (member in content.members)
		{
			if (member == null) continue;
			final centerY = member.y + (Std.isOfType(member, UIComponent) ? cast(member, UIComponent).rowHeight : member.height) / 2;
			final onScreen = centerY >= top && centerY <= bottom;

			if (member.visible && !onScreen) UIPage.forceHideChromeRecursive(member);

			member.visible = onScreen;
			member.active = onScreen;
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!visible || !active) return;

		final mp = FlxG.mouse.getWorldPosition(FlxG.camera, _mp);
		final localX = mp.x - x;
		final localY = mp.y - y;
		final overBackground = localX >= 0 && localX <= viewWidth && localY >= 0 && localY <= viewHeight;

		if (FlxG.mouse.justPressed && scrollThumb.visible)
		{
			if (localX >= scrollbarX && localX <= scrollbarX + SCROLLBAR_WIDTH)
			{
				final thumbLocalY = scrollThumb.y - y;
				if (localY >= thumbLocalY && localY <= thumbLocalY + scrollThumb.height)
				{
					draggingThumb = true;
					dragGrabOffset = localY - thumbLocalY;
				}
				else
					jumpThumbTo(localY - scrollThumb.height / 2);
			}
		}

		if (FlxG.mouse.justReleased) draggingThumb = false;

		if (draggingThumb) jumpThumbTo(localY - dragGrabOffset);

		if (overBackground && FlxG.mouse.wheel != 0 && !UIDropdown.isAnyOpen()) scrollY -= FlxG.mouse.wheel * scrollSpeed;
	}

	function jumpThumbTo(thumbY:Float):Void
	{
		final travel = viewHeight - scrollThumb.height;
		scrollY = (travel > 0 ? Math.max(0, Math.min(1, thumbY / travel)) : 0) * maxScroll();
	}

	override public function destroy():Void
	{
		_mp.put();
		super.destroy();
	}
}
