package moon.menus.obj.clicker;

import moon.menus.obj.clicker.StickerClickerData.ShopItem;
import flixel.group.FlxSpriteGroup;

/**
 * One cute shop card :3
 */
class StickerShopCard extends FlxSpriteGroup
{
	public var item:ShopItem;
	public var index:Int;

	var bg:FlxSprite;
	var nameTxt:FlxText;
	var descTxt:FlxText;
	var costTxt:FlxText;
	var ownedTxt:FlxText;
	var canAfford:Bool = false;
	var baseW:Int;
	var baseH:Int;

	static final COL_BG_OK:FlxColor = 0xFF2A1F2E;
	static final COL_BG_NO:FlxColor = 0xFF1E1620;
	static final COL_NAME:FlxColor = 0xFFFFD6E8;
	static final COL_DESC:FlxColor = 0xFFB89BB0;
	static final COL_COST_OK:FlxColor = 0xFFFF8DC0;
	static final COL_COST_NO:FlxColor = 0xFF6E5568;
	static final COL_OWNED:FlxColor = 0xFFC9A0B8;

	public function new(x:Float, y:Float, width:Int, height:Int, item:ShopItem, index:Int)
	{
		super(x, y);
		this.item = item;
		this.index = index;
		baseW = width;
		baseH = height;

		bg = new FlxSprite();
		bg.makeGraphic(width, height, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, width, height, 18, 18, COL_BG_OK);
		bg.antialiasing = true;
		bg.active = false;
		add(bg);

		nameTxt = new FlxText(14, 4, width - 70, item.name);
		nameTxt.setFormat(Paths.font('DynaPuff.ttf'), 18, COL_NAME, LEFT);
		nameTxt.antialiasing = true;
		add(nameTxt);

		ownedTxt = new FlxText(width - 56, 6, 48, 'x0');
		ownedTxt.setFormat(Paths.font('phantomuff/full.ttf'), 16, COL_OWNED, RIGHT);
		ownedTxt.antialiasing = true;
		add(ownedTxt);

		descTxt = new FlxText(14, 30, width - 28, item.desc);
		descTxt.setFormat(Paths.font('phantomuff/full.ttf'), 13, COL_DESC, LEFT);
		descTxt.antialiasing = true;
		add(descTxt);

		costTxt = new FlxText(14, height - 24, width - 28, '0 stickers');
		costTxt.setFormat(Paths.font('phantomuff/full.ttf'), 14, COL_COST_OK, LEFT);
		costTxt.antialiasing = true;
		add(costTxt);

		refresh(0);
	}

	public function refresh(currentStickers:Float):Void
	{
		final cost = StickerClickerData.costOf(item);
		canAfford = currentStickers >= cost;

		ownedTxt.text = 'x${item.owned}';
		costTxt.text = '${StickerClickerData.formatNumber(cost)} stickers';
		costTxt.color = canAfford ? COL_COST_OK : COL_COST_NO;

		bg.color = canAfford ? 0xFF6F5F64 : 0xFF111010;
		nameTxt.alpha = canAfford ? 1 : 0.7;
		descTxt.alpha = canAfford ? 1 : 0.65;
		ownedTxt.alpha = canAfford ? 1 : 0.65;
	}

	public function pulse():Void
	{
		FlxTween.cancelTweensOf(scale);
		scale.set(1.04, 1.04);
		FlxTween.tween(scale, {
			x: 1,
			y: 1
		}, 0.18, {
			ease: FlxEase.quadOut
		});
	}

	// lol

	public function containsMouse():Bool return FlxG.mouse.overlaps(bg, camera);
}
