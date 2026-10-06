package moon.menus;

import flixel.group.FlxGroup;
import moon.menus.obj.clicker.*;

using StringTools;

/**
 * Sticker clicker totally not inspired on cookie clicker!
 */
class StickerClicker extends FlxState
{
	var stickers:Float = 0;
	var totalEarned:Float = 0;
	var clickPower:Float = 1;
	var autoCps:Float = 0;
	var bigSticker:MoonSprite;
	var stickerKeys:Array<String> = [];
	var scoreText:FlxText;
	var cpsText:FlxText;
	var flavorText:FlxText;
	var comboText:FlxText;
	var floatingGroup:FlxTypedGroup<FlxText>;
	var rainGroup:FlxTypedGroup<MoonSprite>;
	var shop:StickerClickerShop;
	var pendingOwned:Array<Int> = [];
	var combo:Int = 0;
	var comboTimer:Float = 0;
	var bg:MoonSprite;
	var bgHue:Float = 0;
	var bgPos:FlxPoint = FlxPoint.get();
	var goldenSticker:MoonSprite;
	var goldShader:GoldenShimmerShader;
	var goldenAlive:Bool = false;
	var goldenTimer:Float = 0;
	var goldenRewardMult:Float = 0;

	static final GOLDEN_DURATION:Float = 28;
	static final GOLDEN_BONUS:Float = 70;
	static final BG_HUE_SPEED:Float = 18;
	static final BG_SAT:Float = 0.45;
	static final BG_BRIGHT:Float = 0.35;
	static final COMBO_WINDOW:Float = 0.55;
	static final CRIT_CHANCE:Float = 0.05;
	static final CRIT_MULT:Float = 5;
	static final BG_PARALLAX:Float = 20;
	static final BG_FOLLOW:Float = 0.06;

	override public function create():Void
	{
		super.create();
		Global.allowInputs = true;
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		loadStickerKeys();
		loadSave();

		bg = new MoonSprite().loadGraphic(Paths.image('menus/menuDesat'));
		bg.color = FlxColor.fromHSB(bgHue, BG_SAT, BG_BRIGHT);
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.scale.set(1.2, 1.2);
		bg.updateHitbox();
		bg.screenCenter();
		bg.active = false;
		add(bg);

		bgPos.set(bg.x, bg.y);

		rainGroup = new FlxTypedGroup<MoonSprite>();
		add(rainGroup);

		bigSticker = new MoonSprite();
		randomizeBigSticker();
		add(bigSticker);

		scoreText = new FlxText(0, 22, FlxG.width, "0 stickers");
		scoreText.setFormat(Paths.font('DynaPuff.ttf'), 44, 0xFFFFF8FC, CENTER);
		scoreText.setBorderStyle(SHADOW, 0x66C06A9A, 2, 1);
		add(scoreText);

		cpsText = new FlxText(0, 72, FlxG.width, "0 / sec  •  1 / click");
		cpsText.setFormat(Paths.font('phantomuff/full.ttf'), 18, 0xFF9B6B88, CENTER);
		add(cpsText);

		comboText = new FlxText(0, bigSticker.y - 128, FlxG.width, "");
		comboText.setFormat(Paths.font('DynaPuff.ttf'), 26, 0xFFFF8DC0, CENTER);
		comboText.setBorderStyle(SHADOW, 0x44AA4A7A, 2);
		comboText.alpha = 0;
		add(comboText);

		flavorText = new FlxText(0, 0, FlxG.width, FlxG.random.getObject(StickerClickerData.FLAVOR_LINES));
		flavorText.setFormat(Paths.font('BRIANNE_S_HAND.TTF'), 32, 0xFFB07090, CENTER);
		flavorText.setBorderStyle(SHADOW, 0x75000000, 2);
		add(flavorText);
		flavorText.y = FlxG.height - flavorText.height - 16;

		floatingGroup = new FlxTypedGroup<FlxText>();
		add(floatingGroup);

		shop = new StickerClickerShop(FlxG.width - 360, 70);
		shop.onBuy = tryBuy;
		add(shop);

		if (pendingOwned.length > 0)
		{
			final stats = StickerClickerData.applyOwned(shop.items, pendingOwned);
			clickPower = stats.clickPower;
			autoCps = stats.autoCps;
			pendingOwned = [];
		}

		shop.refresh(stickers);
		refreshUI();

		goldShader = new GoldenShimmerShader(0.9);
		randomizeGoldTime();

		new FlxTimer().start(0.1, (_) ->
		{
			if (autoCps > 0) addStickers(autoCps * 0.1, false);
		}, 0);

		new FlxTimer().start(8, (_) ->
		{
			flavorText.text = FlxG.random.getObject(StickerClickerData.FLAVOR_LINES);
			flavorText.alpha = 0;
			FlxTween.tween(flavorText, {
				alpha: 1
			}, 0.45);
		}, 0);

		MoonUtils.playGlobalMusic('menus/theClicker', false);
	}

	function randomizeGoldTime()
	{
		goldenTimer = FlxG.random.float(10, 30);
	}

	function spawnGoldenSticker():Void
	{
		if (goldenAlive) return;

		final g = Paths.image(FlxG.random.getObject(stickerKeys));
		if (g == null) return;

		if (goldenSticker == null)
		{
			goldenSticker = new MoonSprite();
			add(goldenSticker);
		}

		goldenSticker.loadGraphic(g);
		goldenSticker.setGraphicSize(0, 120);
		goldenSticker.updateHitbox();
		goldenSticker.shader = goldShader;
		goldenSticker.alpha = 1;
		goldenSticker.visible = goldenSticker.exists = true;

		FlxTween.cancelTweensOf(goldenSticker);
		final fromLeft = FlxG.random.bool();
		goldenSticker.x = fromLeft ? -goldenSticker.width - 200 : FlxG.width + 200;
		goldenSticker.y = FlxG.random.float(80, FlxG.height - 200);

		FlxTween.tween(goldenSticker, {
			x: fromLeft ? FlxG.width + 200 : -goldenSticker.width - 220,
			y: goldenSticker.y + FlxG.random.float(-40, 40)
		}, GOLDEN_DURATION, {
			ease: FlxEase.sineInOut,
			onComplete: _ -> despawnGolden(false)
		});

		goldenSticker.angle = -5;

		goldenSticker.scale.set(0.95, 0.95);
		FlxTween.tween(goldenSticker, {
			"scale.x": 1.05,
			"scale.y": 1.05,
			angle: 5
		}, 0.4, {
			onUpdate: _ -> goldenSticker.updateHitbox(),
			type: PINGPONG,
			ease: FlxEase.sineInOut
		});

		goldenAlive = true;
		// Paths.playSFX('ui/stickers/keyClick${FlxG.random.int(1, 8)}.ogg');
	}

	function despawnGolden(clicked:Bool):Void
	{
		if (!goldenAlive) return;
		goldenAlive = false;

		FlxTween.cancelTweensOf(goldenSticker);
		FlxTween.cancelTweensOf(goldenSticker.scale);

		if (clicked)
		{
			final bonus = clickPower * GOLDEN_BONUS;
			addStickers(bonus, true);
			spawnFloatingText('GOLD! +${StickerClickerData.formatNumber(bonus)}', goldenSticker.x + goldenSticker.width * 0.5, goldenSticker.y, true);
			explodeStickers(16);
		}

		goldenSticker.visible = false;
		goldenSticker.shader = null;

		randomizeGoldTime();
	}

	function loadStickerKeys():Void
	{
		stickerKeys = getStickerKeys("images/menus/transitions/stickers");
		if (stickerKeys.length == 0)
		{
			trace("No stickers found for clicker!", "ERROR");
			stickerKeys = ["menus/menuDesat"];
		}
	}

	function getStickerKeys(baseDir:String, subPath:String = ""):Array<String>
	{
		var keys:Array<String> = [];
		final currentDir = baseDir + (subPath != "" ? "/" + subPath : "");

		for (file in Paths.readDir(currentDir, [".png"], true)) keys.push("menus/transitions/stickers" + (subPath != "" ? "/" + subPath : "") + "/" + file);

		for (item in Paths.readDir(
			currentDir,
			null,
			false
		)) if (!item.contains(".")) keys = keys.concat(getStickerKeys(baseDir, subPath + (subPath != "" ? "/" : "") + item));

		return keys;
	}

	function randomizeBigSticker():Void
	{
		final key = FlxG.random.getObject(stickerKeys);
		final graphic = Paths.image(key);
		if (graphic == null) return;

		if (!AssetManager.exclusions.contains('$key.png')) AssetManager.exclusions.push('$key.png');

		bigSticker.loadGraphic(graphic);
		bigSticker.setGraphicSize(0, 280);
		bigSticker.updateHitbox();
		bigSticker.screenCenter();
	}

	function tryBuy(index:Int):Void
	{
		final item = shop.items[index];
		final cost = StickerClickerData.costOf(item);
		if (stickers < cost) return;

		stickers -= cost;
		item.owned++;
		clickPower += item.clickBonus;
		autoCps += item.cps;

		shop.pulse(index);
		shop.refresh(stickers);

		Paths.playSFX('menus/clicker/buy.wav', 'sounds', true, FlxG.random.float(0.9, 1.1));

		// TODO: make this more chaotic haha
		// wait chaotic??? say that again.....
		if (item.id == "portal" && item.owned % 3 == 0) spawnStickerRain(14);

		saveProgress();
		refreshUI();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (comboTimer > 0)
		{
			comboTimer -= elapsed;
			if (comboTimer <= 0)
			{
				combo = 0;
				FlxG.sound.music.pitch = 1;
				FlxTween.tween(comboText, {
					alpha: 0
				}, 0.25);
			}
		}

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(bigSticker)) onBigClick();
			else
				shop.tryClick();
		}

		if (FlxG.mouse.overlaps(bigSticker)) bigSticker.scale.set(1.07, 1.07);
		else
			bigSticker.scale.set(1, 1);

		if (MoonInput.justPressed(BACK))
		{
			saveProgress();
			FlxG.mouse.visible = false;
			FlxG.switchState(() -> new MainMenu());
		}

		if (FlxG.mouse.pressed && FlxG.mouse.overlaps(bigSticker)) bigSticker.angle += elapsed * 28;

		for (s in rainGroup.members) if (s != null && s.exists && s.y > FlxG.height + 60) retireSticker(s);
		if (goldenAlive && goldShader != null) goldShader.update(elapsed);

		if (!goldenAlive)
		{
			goldenTimer -= elapsed;
			if (goldenTimer <= 0) spawnGoldenSticker();
		}

		if (FlxG.mouse.justPressed && goldenAlive && goldenSticker != null && FlxG.mouse.overlaps(goldenSticker)) despawnGolden(true);

		bgHue += BG_HUE_SPEED * elapsed;
		if (bgHue >= 360) bgHue -= 360;

		bg.color = FlxColor.fromHSB(bgHue, BG_SAT, BG_BRIGHT);

		// TODO: I think this would be an interesting thing to have as a helper function somewhere in the utils...
		bg.x = FlxMath.lerp(bg.x, bgPos.x - ((FlxG.mouse.viewX - FlxG.width * 0.5) / (FlxG.width * 0.5)) * BG_PARALLAX, BG_FOLLOW);
		bg.y = FlxMath.lerp(bg.y, bgPos.y - ((FlxG.mouse.viewY - FlxG.height * 0.5) / (FlxG.height * 0.5)) * BG_PARALLAX, BG_FOLLOW);
	}

	function onBigClick():Void
	{
		combo++;
		comboTimer = COMBO_WINDOW;

		if (combo > 0 && combo % 100 == 0)
		{
			explodeStickers(Std.int(10 * (combo / 100)));
			FlxG.sound.music.pitch += 0.02;

			Paths.playSFX('menus/clicker/combo.wav', 'sounds', true, FlxG.random.float(0.9, 1.1));
		}

		if (combo >= 10)
		{
			comboText.text = 'combo x$combo!';

			FlxTween.cancelTweensOf(comboText.alpha);
			FlxTween.cancelTweensOf(comboText.scale);

			comboText.alpha = 1;
			comboText.scale.set(1.2, 1.2);
			FlxTween.tween(comboText.scale, {
				x: 1,
				y: 1
			}, 0.2, {
				ease: FlxEase.backOut
			});
		}

		final isCrit = FlxG.random.float() < CRIT_CHANCE;
		var amount = clickPower;
		if (combo >= 5) amount *= 1 + Math.min(combo - 4, 10) * 0.05;
		if (isCrit) amount *= CRIT_MULT;

		addStickers(amount, true);

		spawnFloatingText(
			isCrit ? 'CRIT! +${StickerClickerData.formatNumber(amount)}' : '+${StickerClickerData.formatNumber(amount)}',
			bigSticker.x + bigSticker.width * 0.5,
			bigSticker.y + 30,
			isCrit
		);

		FlxTween.cancelTweensOf(bigSticker.scale);
		bigSticker.scale.set(0.82, 1.18);
		FlxTween.tween(bigSticker.scale, {
			x: 1,
			y: 1
		}, 0.2, {
			ease: FlxEase.elasticOut
		});
		bigSticker.angle += FlxG.random.float(-14, 14);

		Paths.playSFX('ui/stickers/keyClick${FlxG.random.int(1, 8)}.ogg');

		if (FlxG.random.bool(10)) randomizeBigSticker();

		if (totalEarned > 0 && Math.floor(totalEarned) % 100 == 0) spawnStickerRain(8);

		if (isCrit) spawnStickerRain(4);
	}

	function addStickers(amount:Float, fromClick:Bool):Void
	{
		stickers += amount;
		totalEarned += amount;
		shop.refresh(stickers);
		refreshUI();
	}

	function refreshUI():Void
	{
		scoreText.text = '${StickerClickerData.formatNumber(stickers)} stickers';
		cpsText.text = '${StickerClickerData.formatNumber(autoCps)} / sec   •   ${StickerClickerData.formatNumber(clickPower)} / click';
	}

	function spawnFloatingText(str:String, x:Float, y:Float, crit:Bool = false):Void
	{
		var t = new FlxText(x - 80, y, 160, str);
		t.setFormat(Paths.font('DynaPuff.ttf'), crit ? 30 : 24, crit ? 0xFFFFD700 : 0xFFFFE8F0, CENTER);
		t.setBorderStyle(SHADOW, 0xFF000000, 4);
		floatingGroup.add(t);

		FlxTween.tween(t, {
			alpha: 0,
			y: t.y - (crit ? 110 : 80)
		}, crit ? 1.1 : 0.85, {
			ease: FlxEase.quadOut,
			onComplete: (_) ->
			{
				floatingGroup.remove(t, true);
				t.destroy();
			}
		});
	}

	function recycleSticker():MoonSprite
	{
		var s:MoonSprite = rainGroup.recycle(function():MoonSprite
		{
			return new MoonSprite();
		});
		FlxTween.cancelTweensOf(s);

		s.acceleration.set(0, 0);
		s.velocity.set(0, 0);
		s.angularVelocity = 0;
		s.angle = 0;
		s.alpha = 1;
		s.scale.set(1, 1);
		s.visible = s.active = true;

		return s;
	}

	function retireSticker(s:MoonSprite):Void
	{
		FlxTween.cancelTweensOf(s);
		s.velocity.set(0, 0);
		s.acceleration.set(0, 0);
		s.angularVelocity = 0;
		s.kill();
	}

	function spawnStickerRain(count:Int):Void
	{
		for (i in 0...count)
		{
			final g = Paths.image(FlxG.random.getObject(stickerKeys));
			if (g == null) continue;

			var s = recycleSticker();
			s.loadGraphic(g);
			s.setGraphicSize(0, FlxG.random.int(36, 80));
			s.updateHitbox();
			s.setPosition(FlxG.random.float(0, FlxG.width - s.width), -s.height - FlxG.random.float(0, 180));
			s.velocity.y = FlxG.random.float(160, 400);
			s.velocity.x = FlxG.random.float(-50, 50);
			s.angularVelocity = FlxG.random.float(-200, 200);
			s.alpha = 0.9;
		}
	}

	function explodeStickers(count:Int = 20):Void
	{
		for (i in 0...count)
		{
			final g = Paths.image(FlxG.random.getObject(stickerKeys));
			if (g == null) continue;

			var s = recycleSticker();
			s.loadGraphic(g);
			s.setGraphicSize(0, FlxG.random.int(28, 64));
			s.updateHitbox();
			s.screenCenter();

			final angle = FlxG.random.float(0, Math.PI * 2);
			final speed = FlxG.random.float(280, 520);

			s.velocity.x = Math.cos(angle) * speed;
			s.velocity.y = Math.sin(angle) * speed - FlxG.random.float(200, 400);
			s.acceleration.y = FlxG.random.float(900, 1400);
			s.angularVelocity = FlxG.random.float(-360, 360);
			s.alpha = 1;

			FlxTween.tween(s, {
				alpha: 0
			}, 0.4, {
				startDelay: 2,
				onComplete: (_) ->
				{
					if (s != null && s.exists) retireSticker(s);
				}
			});
		}
	}

	function loadSave():Void
	{
		final snap = StickerClickerData.load();
		stickers = snap.stickers;
		totalEarned = snap.totalEarned;
		clickPower = snap.clickPower;
		autoCps = snap.autoCps;
		pendingOwned = snap.owned != null ? snap.owned : [];
	}

	function saveProgress():Void
	{
		StickerClickerData.save(stickers, totalEarned, clickPower, autoCps, shop != null ? shop.items : []);
	}

	override public function destroy():Void
	{
		FlxG.mouse.visible = false;
		super.destroy();
	}
}
