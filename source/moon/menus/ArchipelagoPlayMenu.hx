package moon.menus;

import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxGradient;
import moon.backend.archipelago.*;
import moon.backend.data.SongLibrary;
import moon.backend.data.SongBase;
import moon.backend.data.Week;
import moon.backend.data.Chart;
import moon.game.PlayState;
import moon.global_obj.PixelIcon;

using StringTools;

class ArchipelagoPlayMenu extends FlxTransitionableState
{
	static final VIEW_SONGS:Int = 0;
	static final VIEW_WEEKS:Int = 1;
	static final VISIBLE_RADIUS:Int = 3;
	static final Y_SPACING:Float = 106;
	public static final CARD_W:Int = 480;
	public static final CARD_H:Int = 78;
	static final LIST_RIGHT_PAD:Float = 116;
	static final LIST_CENTER_Y:Float = 340;

	var viewMode:Int = VIEW_SONGS;
	var listNames:Array<String> = [];
	var listLocked:Array<Bool> = [];
	var listIcons:Array<String> = [];
	var curSelected:Int = 0;
	var difficulties:Array<String> = [];
	var mixes:Array<String> = [];
	var curDiff:Int = 0;
	var curMix:Int = 0;
	var confirming:Bool = false;
	var scrollOffset:Float = 0;
	var targetScroll:Float = 0;
	var topBar:MoonSprite;
	var titleText:FlxText;
	var unlockText:FlxText;
	var viewHint:FlxText;
	var cards:Array<ApSongCard> = [];
	var cardGroup:FlxSpriteGroup;
	var leftDiffArrow:MoonSprite;
	var rightDiffArrow:MoonSprite;
	var diffText:FlxText;
	var leftMixArrow:MoonSprite;
	var rightMixArrow:MoonSprite;
	var mixText:FlxText;
	var statusText:FlxText;
	var listX(get, never):Float;

	inline function get_listX():Float return FlxG.width - CARD_W - LIST_RIGHT_PAD;

	override public function create()
	{
		super.create();
		Global.allowInputs = true;

		ArchipelagoProgress.init();
		ArchipelagoProgress.rebuildPools();
		ArchipelagoProgress.drainPending();

		final sd = ArchipelagoManager.slotData;
		if (sd != null && sd.unlock_mode == 1) viewMode = VIEW_WEEKS;

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/menuDesat'));
		bg.color = 0xFF2a1a4a;
		bg.screenCenter();
		add(bg);

		var panel = new MoonSprite().makeGraphic(Std.int(FlxG.width * 0.55), FlxG.height, 0xCC0a0614);
		panel.x = FlxG.width * 0.45;
		add(panel);

		var accent = new MoonSprite().makeGraphic(6, FlxG.height, 0xff000000);
		accent.x = panel.x;
		add(accent);

		cardGroup = new FlxSpriteGroup();
		add(cardGroup);

		final poolSize = VISIBLE_RADIUS * 2 + 1;
		for (i in 0...poolSize)
		{
			final card = new ApSongCard();
			cards.push(card);
			cardGroup.add(card);
		}

		final topFade = FlxGradient.createGradientFlxSprite(FlxG.width, 160, [0xFF000000, 0x00000000]);
		topFade.y = 0;
		topFade.scrollFactor.set();
		add(topFade);

		final botFade = FlxGradient.createGradientFlxSprite(FlxG.width, 180, [0x00000000, 0xFF000000]);
		botFade.y = FlxG.height - botFade.height;
		botFade.scrollFactor.set();
		add(botFade);

		topBar = new MoonSprite().makeGraphic(FlxG.width + 16, 72, FlxColor.BLACK);
		topBar.screenCenter(X);
		topBar.y = -topBar.height;
		add(topBar);

		titleText = new FlxText(32, 0, 400, "ARCHIPELAGO");
		titleText.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 36, 0xFFffd863, LEFT);
		titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		titleText.letterSpacing = -2;
		titleText.y = 14;
		titleText.alpha = 0;
		add(titleText);

		unlockText = new FlxText(0, 0, 500, "");
		unlockText.setFormat(Paths.font('phantomuff/full.ttf'), 18, 0xFFcccccc, RIGHT);
		unlockText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		unlockText.x = FlxG.width - unlockText.width - 32;
		unlockText.y = 22;
		unlockText.alpha = 0;
		add(unlockText);

		viewHint = new FlxText(32, titleText.y + titleText.height + 2, 600, "");
		viewHint.setFormat(Paths.font('phantomuff/full.ttf'), 16, 0xFFaaaaaa, LEFT);
		viewHint.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		add(viewHint);

		leftDiffArrow = makeArrow(true);
		rightDiffArrow = makeArrow(false);
		add(leftDiffArrow);
		add(rightDiffArrow);

		diffText = new FlxText(0, 0, 280, "HARD");
		diffText.setFormat(Paths.font('phantomuff/difficulty.ttf'), 42, FlxColor.WHITE, CENTER);
		diffText.bold = true;
		diffText.antialiasing = true;
		diffText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(diffText);

		leftMixArrow = makeArrow(true);
		leftMixArrow.scale.set(0.4, 0.4);
		leftMixArrow.updateHitbox();
		rightMixArrow = makeArrow(false);
		rightMixArrow.scale.set(0.4, 0.4);
		rightMixArrow.updateHitbox();
		add(leftMixArrow);
		add(rightMixArrow);

		mixText = new FlxText(0, 0, 160, "BF");
		mixText.setFormat(Paths.font('phantomuff/full.ttf'), 22, FlxColor.WHITE, CENTER);
		mixText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(mixText);

		statusText = new FlxText(40, FlxG.height - 70, 500, "");
		statusText.setFormat(Paths.font('phantomuff/full.ttf'), 16, 0xFFff6666, LEFT);
		statusText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		add(statusText);

		FlxTween.tween(topBar, {
			y: 0
		}, 0.45, {
			ease: FlxEase.circOut
		});
		FlxTween.tween(titleText, {
			alpha: 1
		}, 0.5, {
			ease: FlxEase.quadOut,
			startDelay: 0.15
		});
		FlxTween.tween(unlockText, {
			alpha: 1
		}, 0.5, {
			ease: FlxEase.quadOut,
			startDelay: 0.2
		});

		rebuildList();
		refreshAll(true);
		layoutControls();
	}

	function makeArrow(flip:Bool):MoonSprite
	{
		final a = new MoonSprite().loadGraphic(Paths.image('menus/freeplay/arrow'));
		a.flipX = flip;
		a.antialiasing = true;
		a.scale.set(0.55, 0.55);
		a.updateHitbox();
		return a;
	}

	function rebuildList()
	{
		listNames = [];
		listLocked = [];
		listIcons = [];

		if (viewMode == VIEW_SONGS)
		{
			final count = ArchipelagoProgress.effectiveSongCount();
			for (i in 0...count)
			{
				final name = ArchipelagoProgress.songPool[i];
				listNames.push(name);
				listLocked.push(!ArchipelagoProgress.isSongUnlocked(i + 1));
				listIcons.push(resolveOpponentIcon(name));
			}
		}
		else
		{
			final count = ArchipelagoProgress.effectiveWeekCount();
			for (i in 0...count)
			{
				final id = ArchipelagoProgress.weekPool[i];
				final week = Week.get(id);
				listNames.push((week != null && week.displayName != null) ? week.displayName : id);
				listLocked.push(!ArchipelagoProgress.isWeekUnlocked(i + 1));

				// TODO
				// listIcons.push("");
			}
		}

		curSelected = Std.int(FlxMath.bound(curSelected, 0, Math.max(0, listNames.length - 1)));
		targetScroll = curSelected;
		scrollOffset = targetScroll;
		updateSelectionStuffs();
	}

	// TODO I should probably port this to freeplay!

	function resolveOpponentIcon(songName:String):String
	{
		final lib = SongLibrary.get();
		for (entry in lib.allSongs)
		{
			if (entry.song.toLowerCase() != songName.toLowerCase()) continue;
			try
			{
				final chart = new Chart(entry.song, entry.difficulty, entry.mix);
				if (
					chart.content != null
					&& chart.content.meta != null
					&& chart.content.meta.opponents != null
					&& chart.content.meta.opponents.length > 0
				) return chart.content.meta.opponents[0];
			}
			catch (e:Dynamic)
			{
			}
			break;
		}
		return "bf";
	}

	function markCurrentSeen()
	{
		if (listNames.length == 0 || listLocked[curSelected]) return;
		if (viewMode == VIEW_SONGS) ArchipelagoSave.markSongSeen(curSelected + 1);
		else
			ArchipelagoSave.markWeekSeen(curSelected + 1);
	}

	function updateSelectionStuffs()
	{
		difficulties = [];
		mixes = [];
		curDiff = 0;
		curMix = 0;

		if (listNames.length == 0 || listLocked[curSelected]) return;

		final lib = SongLibrary.get();
		final mixSet = new Map<String, Bool>();
		final unlockedDiffs = new Map<String, Bool>();
		final allDiffs = new Map<String, Bool>();

		if (viewMode == VIEW_SONGS)
		{
			final songName = listNames[curSelected];
			for (entry in lib.allSongs)
			{
				if (entry.song.toLowerCase() != songName.toLowerCase()) continue;
				mixSet.set(entry.mix, true);
				allDiffs.set(entry.difficulty, true);
				if (ArchipelagoProgress.isDifficultyUnlocked(entry.difficulty)) unlockedDiffs.set(entry.difficulty, true);
			}
		}
		else
		{
			for (entry in lib.weekSonglist(ArchipelagoProgress.weekPool[curSelected]))
			{
				mixSet.set(entry.mix, true);
				allDiffs.set(entry.difficulty, true);
				if (ArchipelagoProgress.isDifficultyUnlocked(entry.difficulty)) unlockedDiffs.set(entry.difficulty, true);
			}
		}

		for (m in mixSet.keys()) mixes.push(m);
		mixes.sort((a, b) -> Reflect.compare(a, b));

		final useDiffs = (unlockedDiffs.keys().hasNext()) ? unlockedDiffs : allDiffs;
		for (d in lib.allDifficulties) if (useDiffs.exists(d.name)) difficulties.push(d.name);
		for (d in useDiffs.keys()) if (difficulties.indexOf(d) == -1) difficulties.push(d);

		// uhhh yea defaults!!
		if (difficulties.length == 0) difficulties = ["hard"];
		if (mixes.length == 0) mixes = ["bf"];

		final hardIdx = difficulties.indexOf("hard");
		if (hardIdx >= 0) curDiff = hardIdx;
	}

	function changeSelection(delta:Int)
	{
		if (listNames.length == 0 || confirming) return;

		curSelected = FlxMath.wrap(curSelected + delta, 0, listNames.length - 1);
		targetScroll = curSelected;

		updateSelectionStuffs();
		Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true, FlxG.random.float(0.9, 1.2));
		refreshAll(false);
	}

	function changeDiff(delta:Int)
	{
		if (difficulties.length == 0 || confirming) return;

		curDiff = FlxMath.wrap(curDiff + delta, 0, difficulties.length - 1);

		Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true, FlxG.random.float(0.9, 1.2));
		refreshAll(false);

		FlxTween.cancelTweensOf(diffText.scale);
		diffText.scale.set(1.2, 1.2);
		FlxTween.tween(diffText.scale, {
			x: 1,
			y: 1
		}, 0.20, {
			ease: FlxEase.backOut
		});
	}

	function changeMix(delta:Int)
	{
		if (mixes.length == 0 || confirming) return;
		curMix = FlxMath.wrap(curMix + delta, 0, mixes.length - 1);
		Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true, FlxG.random.float(0.9, 1.2));
		refreshAll(false);
	}

	function toggleView()
	{
		if (confirming) return;
		viewMode = (viewMode == VIEW_SONGS) ? VIEW_WEEKS : VIEW_SONGS;
		curSelected = 0;
		rebuildList();
		Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true, FlxG.random.float(0.9, 1.2));
		refreshAll(true);
	}

	function refreshAll(instant:Bool)
	{
		unlockText.text = (viewMode == VIEW_SONGS) ? '${ArchipelagoProgress.songUnlockCount()}/${ArchipelagoProgress.effectiveSongCount()} songs' : '${ArchipelagoProgress.weekUnlockCount()}/${ArchipelagoProgress.effectiveWeekCount()} weeks'.toUpperCase();
		unlockText.x = FlxG.width - unlockText.width - 32;

		viewHint.text = (viewMode == VIEW_SONGS) ? "VIEW: SONGS - Q / E to switch to Weeks" : "VIEW: WEEKS - Q / E to switch to Songs";

		for (i in 0...cards.length)
		{
			final rel = i - VISIBLE_RADIUS;
			final idx = curSelected + rel;
			final card = cards[i];

			if (idx < 0 || idx >= listNames.length)
			{
				card.visible = false;
				continue;
			}

			card.visible = true;
			final selected = idx == curSelected;

			card.setData(
				listNames[idx],
				listIcons[idx],
				listLocked[idx], !listLocked[idx] && (viewMode == VIEW_SONGS ? ArchipelagoProgress.isSongNew(
					idx + 1
				) : ArchipelagoProgress.isWeekNew(idx + 1)),
				selected
			);
			card.targetAlpha = selected ? 1.0 : (Math.abs(rel) == 1 ? 0.75 : 0.45);
			card.targetScale = selected ? 1.05 : 0.92;
			if (instant) card.snapToTarget();
		}

		if (listNames.length == 0 || listLocked[curSelected])
		{
			diffText.text = mixText.text = "-";
			diffText.color = mixText.color = 0xFF666666;
		}
		else
		{
			final dName = difficulties.length > 0 ? difficulties[curDiff] : "-";
			diffText.text = dName.toUpperCase();
			final libDiff = SongLibrary.getDifficulty(dName);
			diffText.color = (libDiff != null && libDiff.color != null) ? FlxColor.fromString(libDiff.color) : FlxColor.WHITE;

			mixText.text = (mixes.length > 0 ? mixes[curMix] : "-").toUpperCase();
			mixText.color = FlxColor.WHITE;
		}

		statusText.text = "";
		layoutControls();
	}

	function layoutControls()
	{
		final cx = listX + CARD_W * 0.5;
		final cy = FlxG.height - 110;

		diffText.setPosition(cx - diffText.width * 0.5, cy - diffText.height * 0.5);
		leftDiffArrow.setPosition(diffText.x - leftDiffArrow.width - 12, cy - leftDiffArrow.height * 0.5);
		rightDiffArrow.setPosition(diffText.x + diffText.width + 12, cy - rightDiffArrow.height * 0.5);

		final mixY = cy + 48;
		mixText.setPosition(cx - mixText.width * 0.5, mixY);
		leftMixArrow.setPosition(mixText.x - leftMixArrow.width - 8, mixY + mixText.height * 0.5 - leftMixArrow.height * 0.5);
		rightMixArrow.setPosition(mixText.x + mixText.width + 8, leftMixArrow.y);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!confirming)
		{
			if (MoonInput.justPressed(BACK)) FlxG.switchState(() -> new ArchipelagoMenu());

			if (MoonInput.justPressed(UI_UP)) changeSelection(-1);
			else if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);

			if (MoonInput.justPressed(UI_LEFT)) changeDiff(-1);
			else if (MoonInput.justPressed(UI_RIGHT)) changeDiff(1);

			// if (FlxG.keys.justPressed.LBRACKET || FlxG.keys.justPressed.COMMA) changeMix(-1);
			// else if (FlxG.keys.justPressed.RBRACKET || FlxG.keys.justPressed.PERIOD) changeMix(1);
			if (FlxG.keys.justPressed.TAB) changeMix(1);

			if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E) toggleView();

			if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

			if (MoonInput.justPressed(ACCEPT)) tryPlay();
		}

		scrollOffset = FlxMath.lerp(scrollOffset, targetScroll, Math.min(1, elapsed * 12));

		for (i in 0...cards.length)
		{
			final rel = i - VISIBLE_RADIUS;
			final card = cards[i];
			if (!card.visible) continue;

			card.lerpVisuals(elapsed);
			card.applyPosition(listX + (Math.abs(rel + (curSelected - scrollOffset)) * 8), LIST_CENTER_Y + (rel + (curSelected - scrollOffset)) * Y_SPACING);
		}
	}

	function tryPlay()
	{
		if (confirming) return;

		if (listNames.length == 0 || listLocked[curSelected])
		{
			statusText.color = 0xFFff6666;
			return;
		}
		if (difficulties.length == 0 || mixes.length == 0)
		{
			// this shouldn't happen btw. if it ever does, it's a problem!
			statusText.text = "No difficulty/mix available!";
			statusText.color = 0xFFff6666;
			return;
		}

		confirming = true;
		Global.allowInputs = false;
		Paths.playSFX('ui/confirmMenu.ogg');

		for (i in 0...cards.length) if (i == VISIBLE_RADIUS) cards[i].doConfirm();

		final diff = difficulties[curDiff];
		final mix = mixes[curMix];
		var songName:String = listNames[curSelected];

		if (viewMode == VIEW_SONGS)
		{
			PlayState.songData = {
				song: songName,
				difficulty: diff,
				mix: mix
			};
		}
		else
		{
			final tracks = SongLibrary.get().weekSonglist(ArchipelagoProgress.weekPool[curSelected]);
			final playlist:Array<SongBase> = [];
			for (entry in tracks) if (entry.mix == mix && entry.difficulty == diff) playlist.push(entry);

			if (playlist.length == 0)
			{
				statusText.text = "Week has no playable tracks.";
				statusText.color = 0xFFff6666;
				confirming = false;
				Global.allowInputs = true;
				return;
			}

			PlayState.queuePlaylist(playlist);
			songName = playlist[0].song;
		}

		final clearIndex = (viewMode == VIEW_SONGS) ? ArchipelagoProgress.indexForSong(songName) : (curSelected + 1);
		ArchipelagoManager.pendingClearIndex = clearIndex;
		ArchipelagoManager.pendingClearIsWeek = viewMode == VIEW_WEEKS;

		if (viewMode == VIEW_SONGS) ArchipelagoSave.markSongSeen(clearIndex);
		else
			ArchipelagoSave.markWeekSeen(clearIndex);

		new FlxTimer().start(0.85, _ ->
		{
			FlxG.switchState(() -> new LoadingScreen());
		});
	}
}

class ApSongCard extends FlxSpriteGroup
{
	static final LERP:Float = 14;
	static final ICON_PAD_X:Float = 8;
	static final TEXT_X:Float = 88;

	public var targetAlpha:Float = 1;
	public var targetScale:Float = 1;
	public var lerpAlpha:Float = 1;
	public var lerpScale:Float = 1;

	var bg:MoonSprite;
	var icon:PixelIcon;
	var nameText:FlxText;
	var badgeText:FlxText;
	var locked:Bool = false;
	var baseBgColor:Int = 0xFF1a1a22;
	var lastIconChar:String = "";

	public function new()
	{
		super();
		x = 0;
		y = 0;
		alpha = 1;

		bg = new MoonSprite().makeGraphic(ArchipelagoPlayMenu.CARD_W, ArchipelagoPlayMenu.CARD_H, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, bg.width, bg.height, 14, 14, 0xFF1a1a22);
		bg.antialiasing = true;
		bg.active = false;
		add(bg);

		icon = new PixelIcon(0, 0, "bf");
		lastIconChar = icon.character;
		add(icon);

		nameText = new FlxText(0, 0, 360, "");
		nameText.setFormat(Paths.font('phantomuff/full.ttf'), 24, FlxColor.WHITE, LEFT);
		nameText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		nameText.antialiasing = true;
		add(nameText);

		badgeText = new FlxText(0, 0, 200, "");
		badgeText.setFormat(Paths.font('phantomuff/full.ttf'), 14, 0xFF66ff99, LEFT);
		badgeText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		add(badgeText);
	}

	public function setData(name:String, iconChar:String, isLocked:Bool, isNew:Bool, selected:Bool)
	{
		locked = isLocked;
		nameText.text = name.toUpperCase();

		if (isLocked)
		{
			badgeText.text = "LOCKED";
			badgeText.color = 0xFF666666;
			nameText.color = 0xFF666666;
			baseBgColor = 0xFF111118;
			bg.color = baseBgColor;
		}
		else if (isNew)
		{
			badgeText.text = "NEW";
			badgeText.color = 0xFF66ff99;
			nameText.color = selected ? 0xFFffd863 : FlxColor.WHITE;
			baseBgColor = selected ? 0xFF2a2438 : 0xFF1a1a22;
			bg.color = baseBgColor;
		}
		else
		{
			badgeText.text = selected ? "Already Played." : "";
			badgeText.color = 0xffa89f84;
			nameText.color = selected ? 0xFFffd863 : FlxColor.WHITE;
			baseBgColor = selected ? 0xff3b334d : 0xFF1a1a22;
			bg.color = baseBgColor;
		}

		icon.visible = true;
		icon.color = isLocked ? 0xFF555555 : FlxColor.WHITE;

		final want = (iconChar != null && iconChar != "") ? iconChar : "bf";
		if (want != lastIconChar)
		{
			try
				icon.character = want
			catch (e:Dynamic)
			{
			}
			lastIconChar = icon.character;
		}
	}

	public function lerpVisuals(elapsed:Float)
	{
		final t = elapsed * LERP;
		lerpAlpha = FlxMath.lerp(lerpAlpha, targetAlpha, t);
		lerpScale = FlxMath.lerp(lerpScale, targetScale, t);
	}

	public function snapToTarget()
	{
		lerpAlpha = targetAlpha;
		lerpScale = targetScale;
	}

	public function applyPosition(px:Float, py:Float)
	{
		final s = lerpScale;
		final a = lerpAlpha;
		final top = py - (ArchipelagoPlayMenu.CARD_H * s) * 0.5;

		x = 0;
		y = 0;
		alpha = 1;

		bg.scale.set(s, s);
		bg.updateHitbox();
		bg.setPosition(px, top);
		bg.alpha = a;

		icon.scale.set(2 * s, 2 * s);
		icon.origin.set(0, 0);
		if (icon.frame != null) icon.offset.set(0, 0);
		icon.updateHitbox();
		icon.setPosition(px + ICON_PAD_X * s, top + (ArchipelagoPlayMenu.CARD_H * s - icon.height) * 0.5);
		icon.alpha = a;

		nameText.scale.set(s, s);
		nameText.setPosition(px + TEXT_X * s, top + 16 * s);
		nameText.alpha = a;

		badgeText.scale.set(s, s);
		badgeText.setPosition(px + TEXT_X * s, top + 46 * s);
		badgeText.alpha = a;
	}

	public function doConfirm()
	{
		FlxTween.cancelTweensOf(bg);
		bg.color = FlxColor.WHITE;
		FlxTween.color(bg, 0.7, FlxColor.WHITE, baseBgColor, {
			ease: FlxEase.quadOut
		});
		FlxFlicker.flicker(nameText, 0.8, 0.06, true);
		icon.playAnim('select', true);
	}
}
