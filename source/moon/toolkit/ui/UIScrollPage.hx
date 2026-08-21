package moon.toolkit.ui;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

/**
 * A `UIPage` that clips its content. Simple!
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
	 * Lay out content components in a vertical stack.
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
		if (scrollY != 0) content.y -= scrollY;
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
		scrollThumb.x = x + scrollbarX;
		updateThumbPosition();
	}

	function updateThumbPosition():Void
	{
		if (!scrollThumb.visible) return;
		final travel = viewHeight - scrollThumb.height;
		final ratio = maxScroll() > 0 ? scrollY / maxScroll() : 0;
		scrollThumb.y = y + travel * ratio;
	}

	function updateRowClipping():Void
	{
		final viewTop = y;
		final viewBottom = y + viewHeight;
		final viewLeft = x;
		final viewW = viewWidth;

		for (member in content.members)
		{
			if (member == null) continue;

			final rowH = Std.isOfType(member, UIComponent) ? cast(member, UIComponent).rowHeight : member.height;
			final rowTop = member.y;
			final rowBottom = member.y + rowH;

			final fullyOutside = rowBottom <= viewTop || rowTop >= viewBottom;

			if (fullyOutside)
			{
				UIPage.forceHideChromeRecursive(member);
				applyClipRecursive(member, viewLeft, viewTop, viewW, 0);
				member.active = false;
				continue;
			}

			member.active = true;

			final clipTop = Math.max(rowTop, viewTop);
			final clipH = Math.min(rowBottom, viewBottom) - clipTop;
			applyClipRecursive(member, viewLeft, clipTop, viewW, clipH);
		}
	}

	static function applyClipRecursive(obj:FlxBasic, worldX:Float, worldY:Float, worldW:Float, worldH:Float):Void
	{
		if (obj == null) return;

		if (Std.isOfType(obj, FlxSpriteGroup))
		{
			final grp:FlxSpriteGroup = cast obj;
			for (m in grp.members) applyClipRecursive(m, worldX, worldY, worldW, worldH);
			return;
		}

		if (!Std.isOfType(obj, FlxSprite)) return;

		final spr:FlxSprite = cast obj;
		if (worldW <= 0 || worldH <= 0)
		{
			setClip(spr, 0, 0, 0, 0);
			return;
		}

		final localX = worldX - spr.x;
		final localY = worldY - spr.y;

		final ix = Math.max(0, localX);
		final iy = Math.max(0, localY);
		final iw = Math.min(spr.width, localX + worldW) - ix;
		final ih = Math.min(spr.height, localY + worldH) - iy;

		if (iw <= 0 || ih <= 0)
		{
			setClip(spr, 0, 0, 0, 0);
			return;
		}

		setClip(spr, ix, iy, iw, ih);
	}

	static function setClip(spr:FlxSprite, cx:Float, cy:Float, cw:Float, ch:Float):Void
	{
		if (spr.clipRect == null) spr.clipRect = FlxRect.get();
		spr.clipRect.set(cx, cy, cw, ch);
		spr.clipRect = spr.clipRect;
	}

	override public function update(elapsed:Float):Void
	{
		if (!visible || !active)
		{
			super.update(elapsed);
			return;
		}

		updateRowClipping();

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

		if (overBackground && FlxG.mouse.wheel != 0 && !UIEditFocus.isBusy()) scrollY -= FlxG.mouse.wheel * scrollSpeed;

		super.update(elapsed);
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
