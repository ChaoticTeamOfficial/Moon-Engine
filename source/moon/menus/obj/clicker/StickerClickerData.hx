package moon.menus.obj.clicker;

/**
 * All the data and infos for the clicker.
 */
class StickerClickerData
{
	public static final SAVE_BIND:String = "MoonEngine-StickerClicker";
	public static final FLAVOR_LINES:Array<String> = [
		"not FDA approved!!",
		"one of us is having fun",
		"you absolute sticker maniac",
		"the glue is eternal",
		"stick it to the man",
		"this is peak comedy",
		"the stickers are watching...",
		"one with the adhesive",
		"please don't eat the stickers",
		"go touch grass bro..."
	];

	public static function makeDefaultShop():Array<ShopItem>
	{
		return [
			{
				id: "finger",
				name: "Sticky Finger",
				desc: "+1 per click",
				baseCost: 10,
				owned: 0,
				cps: 0,
				clickBonus: 1
			},
			{
				id: "peeler",
				name: "Auto-Peeler",
				desc: "0.2 / sec",
				baseCost: 50,
				owned: 0,
				cps: 0.2,
				clickBonus: 0
			},
			{
				id: "grandma",
				name: "Sticker Nana",
				desc: "1 / sec (she's old!)",
				baseCost: 200,
				owned: 0,
				cps: 1,
				clickBonus: 0
			},
			{
				id: "factory",
				name: "Glue Factory",
				desc: "100 / sec",
				baseCost: 1100,
				owned: 0,
				cps: 100,
				clickBonus: 0
			},
			{
				id: "farm",
				name: "Sticker Farm",
				desc: "240 / sec",
				baseCost: 12000,
				owned: 0,
				cps: 240,
				clickBonus: 0
			},
			{
				id: "portal",
				name: "Adhesive Portal",
				desc: "1.500 / sec + some chaos, chaos!",
				baseCost: 130000,
				owned: 0,
				cps: 1500,
				clickBonus: 0
			}
		];
	}

	public static function costOf(item:ShopItem):Float return Math.floor(item.baseCost * Math.pow(1.15, item.owned));

	static final SUFFIXES = [
		"",
		"K",
		"M",
		"B",
		"T",
		"Q"
	];

	public static function formatNumber(n:Float):String
	{
		var sign = n < 0 ? "-" : "";
		n = Math.abs(n);

		var i = 0;
		while (n >= 1000 && i < SUFFIXES.length - 1)
		{
			n /= 1000;
			i++;
		}

		return sign + (Math.floor(n * 10) / 10) + SUFFIXES[i];
	}

	public static function load():StickerSaveSnapshot
	{
		var snap:StickerSaveSnapshot = {
			stickers: 0,
			totalEarned: 0,
			clickPower: 1,
			autoCps: 0,
			owned: []
		};

		var save = new FlxSave();
		save.bind(SAVE_BIND);
		if (save.data.stickers != null)
		{
			snap.stickers = save.data.stickers;
			snap.totalEarned = save.data.totalEarned != null ? save.data.totalEarned : snap.stickers;
			snap.clickPower = save.data.clickPower != null ? save.data.clickPower : 1;
			snap.autoCps = save.data.autoCps != null ? save.data.autoCps : 0;
			if (save.data.owned != null) snap.owned = save.data.owned;
		}
		save.close();
		return snap;
	}

	public static function save(stickers:Float, totalEarned:Float, clickPower:Float, autoCps:Float, items:Array<ShopItem>):Void
	{
		var save = new FlxSave();
		save.bind(SAVE_BIND);
		save.data.stickers = stickers;
		save.data.totalEarned = totalEarned;
		save.data.clickPower = clickPower;
		save.data.autoCps = autoCps;
		save.data.owned = [for (item in items) item.owned];
		save.flush();
		save.close();
	}

	public static function applyOwned(items:Array<ShopItem>, owned:Array<Int>):
		{clickPower:Float, autoCps:Float}
	{
		for (i in 0...Std.int(Math.min(owned.length, items.length))) items[i].owned = owned[i];

		var clickPower:Float = 1;
		var autoCps:Float = 0;
		for (item in items)
		{
			clickPower += item.clickBonus * item.owned;
			autoCps += item.cps * item.owned;
		}
		return {
			clickPower: clickPower,
			autoCps: autoCps
		};
	}
}

typedef ShopItem =
{
	var id:String;
	var name:String;
	var desc:String;
	var baseCost:Float;
	var owned:Int;
	var cps:Float;
	var clickBonus:Float;
}

typedef StickerSaveSnapshot =
{
	var stickers:Float;
	var totalEarned:Float;
	var clickPower:Float;
	var autoCps:Float;
	var owned:Array<Int>;
}
