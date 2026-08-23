package moon.menus;

import moon.backend.archipelago.ArchipelagoManager;
import moon.backend.archipelago.ArchipelagoProgress;
import moon.backend.data.SongLibrary;
import moon.backend.data.SongBase;
import moon.backend.data.Week;
import moon.global_obj.UIButton;
import moon.game.PlayState;

using StringTools;

/**
 * Browse unlocked songs / weeks and launch a chart.
 * mostly a placeholder menu for now also.
 */
class ArchipelagoPlayMenu extends FlxTransitionableState
{
	static final VIEW_SONGS:Int = 0;
	static final VIEW_WEEKS:Int = 1;

	var viewMode:Int = VIEW_SONGS;
	var listNames:Array<String> = [];
	var listLocked:Array<Bool> = [];
	var curSelected:Int = 0;
	// Focus: 0 = list, 1 = difficulty, 2 = mix, 3 = play, 4 = view toggle, 5 = back
	var focus:Int = 0;
	var difficulties:Array<String> = [];
	var mixes:Array<String> = [];
	var curDiff:Int = 0;
	var curMix:Int = 0;
	var titleText:FlxText;
	var viewText:FlxText;
	var listTexts:Array<FlxText> = [];
	var diffText:FlxText;
	var mixText:FlxText;
	var playBtn:UIButton;
	var viewBtn:UIButton;
	var backBtn:UIButton;
	var infoText:FlxText;
	var listContainer:FlxSpriteGroup;
	var listOffset:Int = 0;

	static final VISIBLE_ROWS:Int = 10;

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
		bg.color = 0xFF3d2b6b;
		bg.x += 132;
		add(bg);

		var blackBar = new MoonSprite().makeGraphic(700, FlxG.height, FlxColor.BLACK);
		blackBar.skew.x = 10;
		blackBar.x -= 120;
		add(blackBar);

		titleText = new FlxText(40, 36, 600, "- AP PLAY -");
		titleText.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 40, 0xFFffd863, LEFT);
		titleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
		titleText.letterSpacing = -2;
		add(titleText);

		viewText = new FlxText(40, 90, 600, "");
		viewText.setFormat(Paths.font('phantomuff/full.ttf'), 18, 0xFFaaaaaa, LEFT);
		viewText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(viewText);

		listContainer = new FlxSpriteGroup();
		add(listContainer);

		for (i in 0...VISIBLE_ROWS)
		{
			final t = new FlxText(50, 130 + i * 32, 520, "");
			t.setFormat(Paths.font('phantomuff/full.ttf'), 22, FlxColor.WHITE, LEFT);
			t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			listContainer.add(t);
			listTexts.push(t);
		}

		diffText = new FlxText(40, FlxG.height - 160, 400, "DIFF: -");
		diffText.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.WHITE, LEFT);
		diffText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(diffText);

		mixText = new FlxText(40, FlxG.height - 130, 400, "MIX: -");
		mixText.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.WHITE, LEFT);
		mixText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(mixText);

		playBtn = new UIButton(40, FlxG.height - 90, "PLAY");
		add(playBtn);

		viewBtn = new UIButton(playBtn.x + playBtn.width + 16, FlxG.height - 90, "VIEW");
		add(viewBtn);

		backBtn = new UIButton(viewBtn.x + viewBtn.width + 16, FlxG.height - 90, "BACK");
		add(backBtn);

		infoText = new FlxText(40, FlxG.height - 36, 700, "");
		infoText.setFormat(Paths.font('phantomuff/full.ttf'), 16, 0xFFaaaaaa, LEFT);
		infoText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		add(infoText);

		rebuildList();
		refreshAll();
	}

	function rebuildList()
	{
		listNames = [];
		listLocked = [];

		if (viewMode == VIEW_SONGS)
		{
			// Show all songs in pool; locked ones greyed out
			for (i in 0...ArchipelagoProgress.songPool.length)
			{
				listNames.push(ArchipelagoProgress.songPool[i]);
				listLocked.push(!ArchipelagoProgress.isSongUnlocked(i + 1));
			}
		}
		else
		{
			for (i in 0...ArchipelagoProgress.weekPool.length)
			{
				final id = ArchipelagoProgress.weekPool[i];
				final week = Week.get(id);
				listNames.push((week != null && week.displayName != null) ? week.displayName : id);
				listLocked.push(!ArchipelagoProgress.isWeekUnlocked(i + 1));
			}
		}

		curSelected = Std.int(FlxMath.bound(curSelected, 0, Math.max(0, listNames.length - 1)));
		listOffset = 0;
		updateDiffMixForSelection();
	}

	function updateDiffMixForSelection()
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
			final tracks = lib.weekSonglist(ArchipelagoProgress.weekPool[curSelected]);
			for (entry in tracks)
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

		if (difficulties.length == 0) difficulties = ["hard"];
		if (mixes.length == 0) mixes = ["bf"];
	}

	function refreshAll()
	{
		viewText.text = (viewMode == VIEW_SONGS) ? 'View: SONGS | Unlocks: ${ArchipelagoProgress.songUnlockCount()}/${ArchipelagoProgress.songPool.length}' : 'View: WEEKS | Unlocks: ${ArchipelagoProgress.weekUnlockCount()}/${ArchipelagoProgress.weekPool.length}';

		// Scroll window
		if (curSelected < listOffset) listOffset = curSelected;
		if (curSelected >= listOffset + VISIBLE_ROWS) listOffset = curSelected - VISIBLE_ROWS + 1;

		for (i in 0...VISIBLE_ROWS)
		{
			final idx = listOffset + i;
			final t = listTexts[i];
			if (idx >= listNames.length)
			{
				t.text = "";
				continue;
			}

			final locked = listLocked[idx];
			final selected = (idx == curSelected && focus == 0);
			t.text = (selected ? "> " : "  ") + (locked ? "[LOCKED] " : "") + listNames[idx];
			t.color = locked ? 0xFF666666 : (selected ? 0xFFffd863 : FlxColor.WHITE);
		}

		diffText.text = "DIFF: " + (difficulties.length > 0 ? difficulties[curDiff] : "-");
		diffText.color = (focus == 1) ? 0xFFffd863 : FlxColor.WHITE;

		mixText.text = "MIX: " + (mixes.length > 0 ? mixes[curMix] : "-");
		mixText.color = (focus == 2) ? 0xFFffd863 : FlxColor.WHITE;

		playBtn.selected = focus == 3;
		viewBtn.selected = focus == 4;
		backBtn.selected = focus == 5;

		if (listNames.length == 0) infoText.text = "No entries. Check song_clear_count / installed content.";
		else if (listLocked[curSelected]) infoText.text = "Locked! Need the matching unlock item.";
		else
			infoText.text = "Left/Right: change focus  Up/Down: list  Accept: confirm";
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (MoonInput.justPressed(BACK))
		{
			FlxG.switchState(() -> new ArchipelagoMenu());
			return;
		}

		if (focus == 0)
		{
			if (MoonInput.justPressed(UI_UP))
			{
				curSelected = FlxMath.wrap(curSelected - 1, 0, Std.int(Math.max(0, listNames.length - 1)));
				updateDiffMixForSelection();
				Paths.playSFX('ui/scrollMenu.ogg');
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_DOWN))
			{
				curSelected = FlxMath.wrap(curSelected + 1, 0, Std.int(Math.max(0, listNames.length - 1)));
				updateDiffMixForSelection();
				Paths.playSFX('ui/scrollMenu.ogg');
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_LEFT) || MoonInput.justPressed(UI_RIGHT))
			{
				focus = MoonInput.justPressed(UI_RIGHT) ? 1 : 5;
				Paths.playSFX('ui/scrollMenu.ogg');
				refreshAll();
			}
			else if (MoonInput.justPressed(ACCEPT) && !listLocked[curSelected])
			{
				// jump to play
				focus = 3;
				refreshAll();
			}
			return;
		}

		if (focus == 1) // difficulty
		{
			if (MoonInput.justPressed(UI_LEFT))
			{
				curDiff = FlxMath.wrap(curDiff - 1, 0, Std.int(Math.max(0, difficulties.length - 1)));
				Paths.playSFX('ui/scrollMenu.ogg');
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_RIGHT))
			{
				curDiff = FlxMath.wrap(curDiff + 1, 0, Std.int(Math.max(0, difficulties.length - 1)));
				Paths.playSFX('ui/scrollMenu.ogg');
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_UP))
			{
				focus = 0;
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_DOWN))
			{
				focus = 2;
				refreshAll();
			}
			return;
		}

		if (focus == 2) // mix
		{
			if (MoonInput.justPressed(UI_LEFT))
			{
				curMix = FlxMath.wrap(curMix - 1, 0, Std.int(Math.max(0, mixes.length - 1)));
				Paths.playSFX('ui/scrollMenu.ogg');
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_RIGHT))
			{
				curMix = FlxMath.wrap(curMix + 1, 0, Std.int(Math.max(0, mixes.length - 1)));
				Paths.playSFX('ui/scrollMenu.ogg');
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_UP))
			{
				focus = 1;
				refreshAll();
			}
			else if (MoonInput.justPressed(UI_DOWN))
			{
				focus = 3;
				refreshAll();
			}
			return;
		}

		if (MoonInput.justPressed(UI_LEFT))
		{
			focus = focus == 3 ? 5 : focus - 1;
			if (focus < 3) focus = 2;
			Paths.playSFX('ui/scrollMenu.ogg');
			refreshAll();
		}
		else if (MoonInput.justPressed(UI_RIGHT))
		{
			focus = focus == 5 ? 3 : focus + 1;
			Paths.playSFX('ui/scrollMenu.ogg');
			refreshAll();
		}
		else if (MoonInput.justPressed(UI_UP))
		{
			focus = 2;
			refreshAll();
		}
		else if (MoonInput.justPressed(ACCEPT))
		{
			if (focus == 3) tryPlay();
			else if (focus == 4) toggleView();
			else if (focus == 5) FlxG.switchState(() -> new ArchipelagoMenu());
		}
	}

	function toggleView()
	{
		viewMode = (viewMode == VIEW_SONGS) ? VIEW_WEEKS : VIEW_SONGS;
		curSelected = 0;
		rebuildList();
		Paths.playSFX('ui/scrollMenu.ogg');
		refreshAll();
	}

	function tryPlay()
	{
		if (listNames.length == 0 || listLocked[curSelected])
		{
			infoText.text = "Can't play! locked or empty.";
			infoText.color = 0xFFff6666;
			return;
		}
		if (difficulties.length == 0 || mixes.length == 0)
		{
			infoText.text = "No difficulty/mix available.";
			infoText.color = 0xFFff6666;
			return;
		}

		final diff = difficulties[curDiff];
		final mix = mixes[curMix];
		var songName:String;

		if (viewMode == VIEW_SONGS) songName = listNames[curSelected];
		else
		{
			// Play first track of the week that matches mix/diff if possible
			final weekId = ArchipelagoProgress.weekPool[curSelected];
			final tracks = SongLibrary.get().weekSonglist(weekId);
			songName = null;
			for (entry in tracks)
			{
				if (entry.mix == mix && entry.difficulty == diff)
				{
					songName = entry.song;
					break;
				}
			}
			if (songName == null && tracks.length > 0) songName = tracks[0].song;
			if (songName == null)
			{
				infoText.text = "Week has no playable tracks.";
				infoText.color = 0xFFff6666;
				return;
			}
		}

		PlayState.songData = {
			song: songName,
			difficulty: diff,
			mix: mix
		};

		final clearIndex = (viewMode == VIEW_SONGS) ? ArchipelagoProgress.indexForSong(songName) : (curSelected + 1);
		ArchipelagoManager.pendingClearIndex = clearIndex;
		ArchipelagoManager.pendingClearIsWeek = viewMode == VIEW_WEEKS;

		FlxG.switchState(() -> new LoadingScreen());
	}
}
