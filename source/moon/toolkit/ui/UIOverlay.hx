package moon.toolkit.ui;

/**
 * A single shared layer that popups (dropdown option lists, tooltips,
 * context menus...) get reparented into while open, so they always draw
 * above every page/component regardless of add-order.
 */
class UIOverlay
{
	public static var layer(default, null):FlxSpriteGroup;

	public static function init():FlxSpriteGroup
	{
		layer = new FlxSpriteGroup();
		return layer;
	}
}
