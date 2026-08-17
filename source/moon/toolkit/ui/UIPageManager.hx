package moon.toolkit.ui;

import moon.toolkit.ui.UIPage.AppearDirection;

/**
 * Holds every UIPage.
 */
class UIPageManager extends FlxSpriteGroup
{
	var pages:Map<String, UIPage> = new Map();

	public var currentPage(default, null):UIPage;

	public function registerPage(id:String, page:UIPage):UIPage
	{
		pages.set(id, page);
		add(page);
		return page;
	}

	public function switchTo(id:String, direction:AppearDirection = FromRight):Void
	{
		final next = pages.get(id);
		if (next == null || next == currentPage) return;

		UITextBox.clearFocus();

		if (currentPage != null) currentPage.hide(oppositeDirection(direction));

		next.show(direction);
		currentPage = next;
	}

	function oppositeDirection(dir:AppearDirection):AppearDirection
	{
		return switch (dir)
		{
			case FromLeft:
				FromRight;
			case FromRight:
				FromLeft;
			case FromTop:
				FromBottom;
			case FromBottom:
				FromTop;
			case FadeOnly:
				FadeOnly;
		}
	}
}
