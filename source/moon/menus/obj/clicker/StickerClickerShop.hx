package moon.menus.obj.clicker;

import moon.menus.obj.clicker.StickerClickerData.ShopItem;
import flixel.group.FlxSpriteGroup;

class StickerClickerShop extends FlxSpriteGroup
{
	public var items:Array<ShopItem> = [];
	public var cards:Array<StickerShopCard> = [];
	public var onBuy:Int->Void;

	var title:FlxText;
	var panelBg:FlxSprite;

	static final PANEL_W:Int = 340;
	static final CARD_H:Int = 72;
	static final CARD_GAP:Int = 10;
	static final PAD:Int = 16;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		items = StickerClickerData.makeDefaultShop();

		final totalH = PAD + 36 + items.length * (CARD_H + CARD_GAP) + PAD;

		panelBg = new FlxSprite();
		panelBg.makeGraphic(PANEL_W, totalH, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(panelBg, 0, 0, PANEL_W, totalH, 24, 24, 0xAA281C22);
		panelBg.antialiasing = true;
		panelBg.active = false;
		add(panelBg);

		title = new FlxText(0, 12, PANEL_W, "< SHOP >");
		title.setFormat(Paths.font('DynaPuff.ttf'), 22, 0xFFC06A9A, CENTER);
		title.antialiasing = true;
		add(title);

		for (i in 0...items.length)
		{
			var card = new StickerShopCard(PAD, PAD + 36 + i * (CARD_H + CARD_GAP), PANEL_W - PAD * 2, CARD_H, items[i], i);
			add(card);
			cards.push(card);
		}
	}

	public function refresh(stickers:Float):Void for (card in cards) card.refresh(stickers);

	public function tryClick():Bool
	{
		for (card in cards)
		{
			if (card.containsMouse())
			{
				if (onBuy != null) onBuy(card.index);
				return true;
			}
		}
		return false;
	}

	public function pulse(index:Int):Void if (index >= 0 && index < cards.length) cards[index].pulse();
}
