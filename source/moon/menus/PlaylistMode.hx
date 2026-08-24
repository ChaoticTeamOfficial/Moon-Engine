package moon.menus;

import moon.menus.obj.playlist.PlaylistItem;
import moon.menus.obj.playlist.PlaylistTrackDetails;
import moon.backend.data.SongData.SongScoreData;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import moon.menus.obj.freeplay.FreeplayDifficultySelector;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextFormat;
import openfl.text.TextFormat;
import moon.game.PlayState;
import moon.backend.data.SongLibrary.Difficulty;
import moon.menus.obj.freeplay.SongPreview;

using StringTools;

class PlaylistMode extends FlxSubState
{
	/**
	 * A variable that contains an alphabetically ordered list of all the songs.
	 */
	public var songList:Array<SongBase>;

	/**
	 * A group that contains all the song items.
	 */
	public var songGroup:FlxTypedSpriteGroup<PlaylistItem>;

	/**
	 * The current list of songs to be played.
	 */
	public var songsQueue:Array<
		{song:PlaylistItem, difficulty:String, number:FlxText}> = [];

	/**
	 * A group that contains the details of the current track selected, it's shown at the right
	 */
	public var infoGroup:PlaylistTrackDetails;

	/**
	 * The difficulty selector below the info group
	 */
	public var difficultySelector:FreeplayDifficultySelector;

	/**
	 * The text that indicates the keybinds :]
	 */
	public var hint:FlxText;

	var curSelected:Int = -1;
	var canSelect:Bool = false;
	final ACCEPT_THRESHOLD:Float = 0.5; // Amount of time holding space to confirm the song.
	final SELECTION_LIMIT:Int = 20; // Max amount of times a song can be re-added to the queue.

	public function new()
	{
		super();

		songList = SongLibrary.get().allSongs.copy();
		songList.sort(function(a, b)
		{
			final aL = a.song.toLowerCase();
			final bL = b.song.toLowerCase();
			return (aL < bL) ? -1 : (aL > bL) ? 1 : 0;
		});

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/menuDesat'));
		add(bg);
		bg.color = 0xFFd5ddc4;
		bg.x -= bg.width;
		FlxTween.tween(bg, {
			x: -332
		}, 0.8, {
			ease: FlxEase.expoOut
		});
		bg.shader = new InvertColor();

		songGroup = new FlxTypedSpriteGroup();
		songGroup.y = -200;
		songGroup.alpha = 0.00001;
		add(songGroup);
		FlxTween.tween(songGroup, {
			y: 0,
			alpha: 1
		}, 0.7, {
			ease: FlxEase.expoOut
		});

		var upperBG = new MoonSprite().makeGraphic(FlxG.width, 78, 0xFF131313);
		add(upperBG);
		upperBG.alpha = 0.00001;
		upperBG.y -= upperBG.height;
		FlxTween.tween(upperBG, {
			y: 0,
			alpha: 1
		}, 0.7, {
			ease: FlxEase.expoOut,
			startDelay: 0.4
		});

		var icon = new MoonSprite(32, -90);
		icon.frames = Tilemap.getAtlasFrames("mainUI");
		icon.frame = Tilemap.getFrame('playlistMode', 'mainUI');
		icon.alpha = 0.0001;
		add(icon);
		icon.antialiasing = false;
		FlxTween.tween(icon, {
			y: 16,
			alpha: 1
		}, 0.7, {
			ease: FlxEase.expoOut,
			startDelay: 0.8
		});

		var mode = new FlxText(96);
		mode.setFormat(Paths.font('phantomuff/difficulty.ttf'), 40, FlxTextAlign.CENTER);
		mode.text = 'PLAYLIST MODE';
		add(mode);
		mode.alpha = 0.0001;
		mode.y -= mode.height;
		mode.antialiasing = true;
		FlxTween.tween(mode, {
			y: 16,
			alpha: 1
		}, 0.7, {
			ease: FlxEase.expoOut,
			startDelay: 0.65
		});

		var sideImg = new MoonSprite().makeGraphic(541, FlxG.height, 0xFF040404);
		add(sideImg);
		sideImg.x = FlxG.width + sideImg.width + 32;
		sideImg.skew.x = -5;
		FlxTween.tween(sideImg, {
			x: FlxG.width - sideImg.width + 32
		}, 1, {
			ease: FlxEase.expoOut
		});

		infoGroup = new PlaylistTrackDetails();
		infoGroup.x = 1500;
		add(infoGroup);
		FlxTween.tween(infoGroup, {
			x: 850
		}, 1.25, {
			ease: FlxEase.expoOut,
			onComplete: _ -> canSelect = true
		});

		difficultySelector = new FreeplayDifficultySelector();
		difficultySelector.setPos(1000, infoGroup.y + infoGroup.height + 80);
		add(difficultySelector);

		hint = new FlxText(
			0,
			0,
			0,
			'Press [ENTER] to Play your set\nPress [SPACE] on a song to add/remove it from the set.\nHold [SPACE] and [SHIFT] to re-add a song in the set.'
		);
		hint.setFormat(Paths.font('phantomuff/full.ttf'), 14, 0xFFAAAAAA, FlxTextAlign.CENTER);
		hint.y = infoGroup.y + infoGroup.height + 140;
		hint.x = 800;
		add(hint);

		loadSongs();
		changeSelection(1);

		trace(songList);
	}

	var holdSpace:Float = 0;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		SongPreview.update(elapsed);

		if (!canSelect) return;

		holdSpace = FlxG.keys.pressed.SPACE ? holdSpace + elapsed : 0;
		if (FlxG.keys.justPressed.ENTER && songsQueue.length != 0) confirm();
		if (holdSpace >= ACCEPT_THRESHOLD)
		{
			confirmSong(FlxG.keys.pressed.SHIFT);
			holdSpace = 0;
		}
		if (MoonInput.justPressed(BACK)) close();

		if (MoonInput.justPressed(UI_UP)) changeSelection(-1);
		else if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);

		if (MoonInput.justPressed(UI_LEFT)) changeDifficulty(-1);
		else if (MoonInput.justPressed(UI_RIGHT)) changeDifficulty(1);
	}

	function loadSongs():Void
	{
		for (i => song in songList)
		{
			var skip:Bool = false;
			for (item in songGroup.members) if (item.song == song.song && item.mix == song.mix) skip = true;
			if (skip) continue;

			var song:PlaylistItem = new PlaylistItem(song.song, song.difficulty, song.mix);
			songGroup.add(song);

			var idx:Int = songGroup.members.indexOf(song);
			FlxTween.tween(song, {
				x: 70 + (idx * PlaylistItem.itemSkew),
				y: 85 + idx * 45
			}, 0.4, {
				ease: FlxEase.cubeInOut
			});
		}
	}

	function changeDifficulty(buh:Int):Void
	{
		difficultySelector.change(buh);
		infoGroup.updateTrackInfo(songGroup.members[curSelected].songDatas[difficultySelector.getSelected()]);
	}

	function changeSelection(guh:Int):Void
	{
		Paths.playSFX('ui/scrollMenu.ogg');
		if (songGroup.members[curSelected] != null) songGroup.members[curSelected].selected = false;
		curSelected = FlxMath.wrap(curSelected + guh, 0, songGroup.members.length - 1);
		if (songGroup.members[curSelected] != null) songGroup.members[curSelected].selected = true;
		infoGroup.updateTrackDetails(songGroup.members[curSelected].songDatas.get(difficultySelector.getSelected()), guh);

		if (curSelected >= 3)
		{
			FlxTween.tween(songGroup, {
				x: (curSelected - 3) * -PlaylistItem.itemSkew,
				y: (curSelected - 3) * -45
			}, 0.2, {
				ease: FlxEase.cubeOut
			});
		}
		else
		{
			FlxTween.tween(songGroup, {
				x: 0,
				y: 0
			}, 0.2, {
				ease: FlxEase.cubeOut
			});
		}
	}

	function confirm():Void
	{
		Paths.playSFX('ui/confirmMenu.ogg');

		PlayState.queuePlaylist([for (item in songsQueue) {
			song: item.song.song,
			difficulty: item.difficulty,
			mix: item.song.mix
		}]);
		FlxG.switchState(() -> new LoadingScreen());
	}

	function confirmSong(force:Bool = false):Void
	{
		var curSong:PlaylistItem = songGroup.members[curSelected];
		var selectorDifficulty:Difficulty = SongLibrary.getDifficulty(difficultySelector.getSelected());

		if (!force && tryRemoveSong(curSong)) return;

		if (!curSong.difficulties.contains(selectorDifficulty))
		{
			Paths.playSFX('toolkit/level-editor/delete.wav');
			FlxTween.shake(difficultySelector.text, 0.03, 0.2);
			return;
		}

		addSong(curSong);
	}

	public function refreshNumbers():Void
	{
		for (i => song in songsQueue) song.number.text = '${i + 1}';
	}

	function tryRemoveSong(song:PlaylistItem):Bool
	{
		for (i in 0...songsQueue.length)
		{
			var item = songsQueue[songsQueue.length - i - 1]; // In inverse order, so it works kinda like a pop()
			if (item.song == song)
			{
				Paths.playSFX('toolkit/general/grabHold.wav');

				songsQueue.remove(item);
				item.song.removed();

				refreshNumbers();
				return true;
			}
		}

		return false;
	}

	function addSong(song:PlaylistItem):Void
	{
		Paths.playSFX('toolkit/general/grabRelease.wav');

		if (song.numbers.length >= SELECTION_LIMIT) return me();

		var num:FlxText = song.added(songsQueue.length + 1);
		songsQueue.push({
			song: song,
			difficulty: difficultySelector.getSelected(),
			number: num
		});
	}

	private function me():Void
	{
		canSelect = false;

		var curSong:PlaylistItem = songGroup.members[curSelected];
		var mee:MoonSprite = new MoonSprite(700, -100).loadGraphic(Paths.image('rema'));
		add(mee);

		Paths.playSFX('menus/playlist/snd_fall2.wav');
		FlxTween.tween(mee, {
			y: curSong.y - mee.height
		}, 0.8, {
			ease: FlxEase.cubeIn,
			onComplete: _ ->
			{
				Paths.playSFX('menus/playlist/bump.wav');
				for (number in curSong.numbers)
				{
					for (song in songsQueue) if (song.song == curSong) songsQueue.remove(song);
					refreshNumbers();
					FlxTween.tween(number, {
						x: number.x + FlxG.random.int(-100, 100),
						y: number.y + FlxG.height
					}, FlxG.random.float(0.8, 1.5), {
						ease: FlxEase.cubeIn,
						onComplete: _ ->
						{
							curSong.numbers.remove(number);
							curSong.remove(number);
							number.destroy();
						}
					});
				}
			}
		});
		FlxTween.tween(mee, {
			y: curSong.y - mee.height - 30
		}, 0.25, {
			ease: FlxEase.sineOut,
			startDelay: 0.8
		});
		FlxTween.tween(mee, {
			y: FlxG.height
		}, 1, {
			ease: FlxEase.sineIn,
			startDelay: 1.05,
			onComplete: _ ->
			{
				canSelect = true;
				remove(mee);
				mee.destroy();
			}
		});
	}
}
