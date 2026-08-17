package moon.toolkit.ui;

import moon.toolkit.ui.UIEditFocus.IEditorChromeHideable;

enum AppearDirection
{
	FromLeft;
	FromRight;
	FromTop;
	FromBottom;
	FadeOnly;
}

/**
 * A container for a set of UIComponents for a page-like layout.
 */
class UIPage extends FlxSpriteGroup
{
	public var title:String;

	var homeX:Float;
	var homeY:Float;

	public function new(x:Float, y:Float, title:String = "")
	{
		super(x, y);
		this.title = title;
		homeX = x;
		homeY = y;
		visible = active = false;
	}

	public function addComponent(component:UIComponent):UIComponent
	{
		add(component);
		return component;
	}

	/** 
	 * Lay out already-added components in a vertical stack with theme spacing.
	 */
	public function layoutVertical(startY:Float = 0):Void
	{
		var y = startY;
		for (member in members)
		{
			if (member == null) continue;
			member.y = y;
			y += (Std.isOfType(member, UIComponent) ? cast(member, UIComponent).rowHeight : member.height) + UITheme.ROW_SPACING;
		}
	}

	public function show(direction:AppearDirection = FromRight, duration:Float = 0.35, delayPerItem:Float = 0.0, ?onComplete:Void->Void):Void
	{
		visible = true;
		active = true;
		alpha = 0;

		forceHideTextBoxChrome();

		var offset = 40;
		switch (direction)
		{
			case FromLeft:
				x = homeX - offset;
			case FromRight:
				x = homeX + offset;
			case FromTop:
				y = homeY - offset;
			case FromBottom:
				y = homeY + offset;
			case FadeOnly:
		}

		FlxTween.tween(this, {
			x: homeX,
			y: homeY,
			alpha: 1
		}, duration, {
			ease: FlxEase.quintOut
		});

		if (delayPerItem > 0) staggerChildren(delayPerItem);

		if (onComplete != null) FlxTween.tween(this, {
			alpha: 1
		}, duration, {
			onComplete: (_) -> onComplete()
		});
	}

	public function hide(direction:AppearDirection = FromRight, duration:Float = 0.25, ?onComplete:Void->Void):Void
	{
		forceHideTextBoxChrome();

		var offset = 40;
		var targetX = homeX;
		var targetY = homeY;
		switch (direction)
		{
			case FromLeft:
				targetX = homeX - offset;
			case FromRight:
				targetX = homeX + offset;
			case FromTop:
				targetY = homeY - offset;
			case FromBottom:
				targetY = homeY + offset;
			case FadeOnly:
		}

		FlxTween.tween(this, {
			x: targetX,
			y: targetY,
			alpha: 0
		}, duration, {
			ease: FlxEase.quintIn,
			onComplete: (_) ->
			{
				visible = false;
				active = false;
				x = homeX;
				y = homeY;
				if (onComplete != null) onComplete();
			}
		});
	}

	function forceHideTextBoxChrome():Void for (member in members) forceHideChromeRecursive(member);

	public static function forceHideChromeRecursive(obj:FlxBasic):Void
	{
		if (obj == null) return;

		if (Std.isOfType(obj, IEditorChromeHideable))
		{
			cast(obj, IEditorChromeHideable).forceHideEditorChrome();
			return;
		}

		if (Std.isOfType(obj, FlxSpriteGroup))
		{
			final grp:FlxSpriteGroup = cast obj;
			for (m in grp.members) forceHideChromeRecursive(m);
		}
	}

	/**
	 * Cheap staggered "pop in" for each child.
	 */
	function staggerChildren(delayPerItem:Float):Void
	{
		var i = 0;
		for (member in members)
		{
			if (member == null) continue;

			final m = member;
			final originalAlpha = 1.0;

			m.alpha = 0;

			final targetX = m.x;
			m.x -= 15;
			FlxTween.tween(m, {
				x: targetX,
				alpha: originalAlpha
			}, 0.3, {
				ease: FlxEase.quadOut,
				startDelay: i * delayPerItem
			});
			i++;
		}
	}
}
