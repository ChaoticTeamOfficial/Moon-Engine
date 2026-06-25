package moon.menus.obj.freeplay;

import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import moon.backend.data.SongData;
import moon.backend.gameplay.*;

using StringTools;

class FreeplaySongSelector extends FlxGroup
{
	public static final VISIBLE_RADIUS:Int = 2;
	static final Y_SPACING:Float = 95.0;
	static final WIGGLE_SPEED:Float = 1.2;
	static final SCROLL_LERP:Float = 10;
	static final DEG_PER_SONG:Float = -25;
	static final DOT_RADIUS:Int = 5;
	static final LINE_W:Int = 512;
	static final LINE_H:Int = 3;
	static final ENTER_DURATION:Float = 0.6;
	static final EXIT_DURATION:Float = 0.5;
	static final STAGGER_DELAY:Float = 0.08;
	static final DIFF_SWITCH_LOCK:Float = 0.25;

	var scrollDelta:Float = 0;
	var diskTargetAngle:Float = 0;
	var selectPulse:Float = 0;
	var isAnimating:Bool = false;
	var previousDifficulty:String = '';
	var disk:MoonSprite;
	var albumTitle:MoonSprite;
	var noSongsText:FlxText;
	var noSongsSubtext:FlxText;
	var lineSprites:Array<MoonSprite> = [];
	var dots:Array<MoonSprite> = [];

	public var items:Array<FreeplaySongItem> = [];

	var slotBaseY:Array<Float> = [];
	var diskCX(get, never):Float;

	inline function get_diskCX() return disk.x + disk.width * 0.5 + 28;

	var diskCY(get, never):Float;

	inline function get_diskCY() return disk.y + disk.height * 0.5;

	var diskRingR(get, never):Float;

	inline function get_diskRingR() return disk.width * 0.46 * 0.5 + 35;

	var itemX(get, never):Float;

	inline function get_itemX() return disk.x + disk.width + 20;

	public var songList:Array<SongBase> = [];

	var curSelected:Int = 0;
	private var preloadedCharts:Array<Chart> = [];
	private var curAlb:String = '';

	public var PRanks:Int = 0;
	public var goldPRanks:Int = 0;

	public function new()
	{
		super();
		setupDisk();
		setupAlbumTitle();
		setupNoSongsMessage();
		setupItemPool();
		playEnterAnimation();
	}

	function setupDisk():Void
	{
		disk = new MoonSprite().loadGraphic(Paths.image('menus/freeplay/albums/volume1'));
		disk.shader = new VinylDiskShader(0.46, 0.12, 0.03, 0.03);
		disk.active = false;
		disk.screenCenter();
		disk.origin.set(disk.width / 2, disk.height / 2);
		add(disk);
	}

	function setupAlbumTitle():Void
	{
		albumTitle = new MoonSprite();
		albumTitle.visible = false;
		add(albumTitle);
	}

	function setupNoSongsMessage():Void
	{
		noSongsText = new FlxText(0, 0, FlxG.width, 'NO SONGS FOUND');
		noSongsText.setFormat(Paths.font('phantomuff/full.ttf'), 36, FlxColor.WHITE, CENTER);
		noSongsText.screenCenter();
		noSongsText.y -= 25;
		noSongsText.alpha = 0;
		noSongsText.visible = false;
		noSongsText.active = false;
		add(noSongsText);

		noSongsSubtext = new FlxText(0, 0, FlxG.width, 'Try selecting a different difficulty');
		noSongsSubtext.setFormat(Paths.font('phantomuff/full.ttf'), 18, 0xFFAAAAAA, CENTER);
		noSongsSubtext.screenCenter();
		noSongsSubtext.y += 25;
		noSongsSubtext.alpha = 0;
		noSongsSubtext.visible = false;
		noSongsSubtext.active = false;
		add(noSongsSubtext);

		noSongsSubtext.x += 316;
		noSongsText.x += 316;
	}

	function setupItemPool():Void
	{
		final poolSize = VISIBLE_RADIUS * 2 + 1;

		for (i in 0...poolSize)
		{
			final relIdx = i - VISIBLE_RADIUS;
			slotBaseY.push(diskCY + relIdx * Y_SPACING);

			add(createLine());
			add(createDot());

			final item = new FreeplaySongItem();
			items.push(item);
			add(item);
		}
	}

	function createLine():MoonSprite
	{
		final line = new MoonSprite(0, 0);
		line.makeGraphic(LINE_W, LINE_H, FlxColor.WHITE);
		line.origin.set(0, LINE_H * 0.5);
		line.visible = false;
		lineSprites.push(line);
		return line;
	}

	function createDot():MoonSprite
	{
		final dot = new MoonSprite(0, 0);
		dot.makeGraphic(DOT_RADIUS * 2, DOT_RADIUS * 2, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawCircle(dot, DOT_RADIUS, DOT_RADIUS, DOT_RADIUS, FlxColor.WHITE);
		dot.visible = false;
		dot.active = false;
		dots.push(dot);
		return dot;
	}

	function playEnterAnimation():Void
	{
		isAnimating = true;

		disk.scale.set(0, 0);
		disk.updateHitbox();
		disk.angle = -360;

		FlxTween.tween(disk, {
			"scale.x": 1,
			"scale.y": 1
		}, ENTER_DURATION, {
			ease: FlxEase.backOut,
			onUpdate: _ -> disk.updateHitbox(),
			onComplete: _ ->
			{
				isAnimating = false;
				Global.allowInputs = true;
			}
		});

		for (i in 0...items.length)
		{
			final item = items[i];
			item.setEnterValues();

			final isCenter = (i == VISIBLE_RADIUS);
			final delay = isCenter ? ENTER_DURATION * 0.25 : ENTER_DURATION * 0.4 + Math.abs(i - VISIBLE_RADIUS) * STAGGER_DELAY;
			final duration = isCenter ? ENTER_DURATION * 0.75 : ENTER_DURATION * 0.5;
			final ease = isCenter ? FlxEase.backOut : FlxEase.circOut;

			FlxTween.tween(item, {
				lerpAlpha: isCenter ? 1 : item.targetAlpha,
				lerpScale: isCenter ? 1 : item.targetScale
			}, duration, {
				ease: ease,
				startDelay: delay
			});
		}
	}

	public function playExitAnimation(?onComplete:Void->Void):Void
	{
		if (isAnimating) return;
		isAnimating = true;
		Global.allowInputs = false;

		FlxTween.tween(disk, {
			"scale.x": 0,
			"scale.y": 0
		}, EXIT_DURATION, {
			ease: FlxEase.backIn,
			onUpdate: _ -> disk.updateHitbox()
		});

		for (i in 0...items.length)
		{
			final delay = Math.abs(i - VISIBLE_RADIUS) * STAGGER_DELAY * 0.6;
			FlxTween.tween(items[i], {
				lerpAlpha: 0,
				lerpScale: 0
			}, EXIT_DURATION * 0.6, {
				ease: FlxEase.backIn,
				startDelay: delay
			});
		}

		// Fade out auxiliary elements
		if (albumTitle.visible) FlxTween.tween(albumTitle, {
			alpha: 0
		}, EXIT_DURATION * 0.4);

		if (noSongsText.visible)
		{
			FlxTween.globalManager.cancelTweensOf(noSongsText);
			FlxTween.globalManager.cancelTweensOf(noSongsSubtext);
			FlxTween.tween(noSongsText, {
				alpha: 0
			}, EXIT_DURATION * 0.3);
			FlxTween.tween(noSongsSubtext, {
				alpha: 0
			}, EXIT_DURATION * 0.3);
		}

		new FlxTimer().start(EXIT_DURATION + 0.15, _ ->
		{
			isAnimating = false;
			if (onComplete != null) onComplete();
		});
	}

	function diffSwitchAnim():Void
	{
		if (isAnimating) return;
		isAnimating = true;

		for (i in 0...items.length) if (items[i].lerpAlpha > 0.1) items[i].playDifficultySwitchEffect();

		new FlxTimer().start(DIFF_SWITCH_LOCK, _ -> isAnimating = false);
	}

	public function loadSongs(songs:Array<SongBase>, selected:Int = 0, ?difficulty:String):Void
	{
		final isDifficultyChange = difficulty != null && difficulty != previousDifficulty && previousDifficulty != '';
		previousDifficulty = difficulty ?? '';

		songList = songs;
		curSelected = (songs.length > 0) ? FlxMath.wrap(selected, 0, songs.length - 1) : 0;

		refreshEntries();
		scrollDelta = 0;
		updateRankCounts();

		if (isDifficultyChange) diffSwitchAnim();

		refreshItems(!isDifficultyChange);
		updateNoSongsVisibility();
	}

	function updateRankCounts():Void
	{
		PRanks = 0;
		goldPRanks = 0;

		for (song in songList)
		{
			final songData = SongData.retrieveData(song.song, song.difficulty, song.mix);
			if (songData != null)
			{
				final rank = Timings.getRank(songData.accuracy).rank;
				if (rank == 'PERFECT') PRanks++;
				if (rank == 'PERFECT-GOLD') goldPRanks++;
			}
		}
	}

	function updateNoSongsVisibility():Void
	{
		if (songList.length == 0)
		{
			noSongsText.visible = true;
			noSongsSubtext.visible = true;

			FlxTween.globalManager.cancelTweensOf(noSongsText);
			FlxTween.globalManager.cancelTweensOf(noSongsSubtext);

			FlxTween.tween(noSongsText, {
				alpha: 1
			}, 0.5, {
				ease: FlxEase.circOut
			});
			FlxTween.tween(noSongsSubtext, {
				alpha: 1
			}, 0.5, {
				ease: FlxEase.circOut,
				startDelay: 0.15
			});
		}
		else
		{
			FlxTween.tween(noSongsText, {
				alpha: 0
			}, 0.3, {
				ease: FlxEase.circIn,
				onComplete: _ -> noSongsText.visible = false
			});
			FlxTween.tween(noSongsSubtext, {
				alpha: 0
			}, 0.3, {
				ease: FlxEase.circIn,
				onComplete: _ -> noSongsSubtext.visible = false
			});
		}
	}

	public function refreshEntries():Void
	{
		preloadedCharts.resize(0);
		for (entry in songList) preloadedCharts.push(new Chart(entry.song, entry.difficulty, entry.mix));
	}

	public function changeSelection(delta:Int):Void
	{
		if (songList.length <= 0 || isAnimating) return;

		curSelected = FlxMath.wrap(curSelected + delta, 0, songList.length - 1);
		scrollDelta += delta * Y_SPACING;
		diskTargetAngle += delta * DEG_PER_SONG;

		refreshItems(false);
	}

	public function getSelected():SongBase return songList[curSelected];

	public function getSelectedItem():FreeplaySongItem return items.length > 0 ? items[VISIBLE_RADIUS] : null;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (isAnimating && disk.scale.x < 0.95) return;

		SongPreview.update(elapsed);

		disk.angle = FlxMath.lerp(disk.angle, diskTargetAngle, elapsed * SCROLL_LERP);
		scrollDelta = FlxMath.lerp(scrollDelta, 0, elapsed * SCROLL_LERP);
		selectPulse += elapsed * 6.0;

		updateItems(elapsed);
		updateDots();
		updateLines();
	}

	function updateItems(elapsed:Float):Void
	{
		for (i in 0...items.length)
		{
			final relIdx = i - VISIBLE_RADIUS;
			final songIdx = curSelected + relIdx;
			final item = items[i];

			if (!isValidIndex(songIdx))
			{
				hideItemAt(i, item);
				continue;
			}

			item.lerpVisuals(elapsed);

			final baseY = slotBaseY[i] - item.icon.height * item.lerpScale * 0.5 + scrollDelta;
			var itemY = baseY;

			if (relIdx == 0) itemY += Math.sin(selectPulse * WIGGLE_SPEED) * 3.5;

			item.applyPositions(itemX, itemY);
		}
	}

	inline function isValidIndex(idx:Int):Bool return idx >= 0 && idx < songList.length;

	function hideItemAt(index:Int, item:FreeplaySongItem):Void
	{
		item.targetAlpha = 0;
		item.lerpAlpha = 0;
		item.hide();
		dots[index].visible = false;
		item.icon.filters = null;
		item.bg.alpha = 0;
	}

	function updateDots():Void
	{
		for (i in 0...dots.length)
		{
			final dot = dots[i];
			if (!dot.visible) continue;

			final item = items[i];
			var iconCY = item.icon.y + item.icon.height * 0.5;
			final iconCX = item.icon.x + item.icon.width * 0.5;

			if (i == VISIBLE_RADIUS) iconCY -= Math.sin(selectPulse * WIGGLE_SPEED) * 3.5;

			final ang = Math.atan2(iconCY - diskCY, iconCX - diskCX);
			dot.x = diskCX + Math.cos(ang) * diskRingR - DOT_RADIUS;
			dot.y = diskCY + Math.sin(ang) * diskRingR - DOT_RADIUS;
		}
	}

	function updateLines():Void
	{
		for (i in 0...items.length)
		{
			final item = items[i];
			final line = lineSprites[i];
			final dot = dots[i];

			if (!dot.visible || item.lerpAlpha < 0.05)
			{
				line.visible = false;
				continue;
			}

			final cx0 = dot.x + DOT_RADIUS;
			final cy0 = dot.y + DOT_RADIUS;
			final dx = (item.icon.x + item.icon.width * 0.5) - cx0;
			final dy = (item.icon.y + item.icon.height * 0.5) - cy0;
			final len = Math.sqrt(dx * dx + dy * dy);

			if (len < 1)
			{
				line.visible = false;
				continue;
			}

			line.setPosition(cx0, cy0);
			line.scale.x = len / LINE_W;
			line.angle = Math.atan2(dy, dx) * (180.0 / Math.PI);
			line.alpha = item.lerpAlpha * 0.9;
			line.visible = true;
		}
	}

	function refreshItems(instant:Bool = false):Void
	{
		if (songList.length == 0)
		{
			hideAllItems();
			return;
		}

		for (i in 0...items.length)
		{
			final relIdx = i - VISIBLE_RADIUS;
			final songIdx = curSelected + relIdx;
			final item = items[i];
			final dist = Math.abs(relIdx);

			if (!isValidIndex(songIdx))
			{
				item.targetAlpha = 0;
				if (instant)
				{
					item.lerpAlpha = 0;
					item.hide();
				}
				dots[i].visible = false;
				item.icon.filters = null;
				item.bg.alpha = 0;
				continue;
			}

			updateItemContent(i, songIdx, item, Std.int(dist), instant);
			updateItemSelection(i, songIdx, item, relIdx);
		}
	}

	function hideAllItems():Void
	{
		for (item in items)
		{
			item.targetAlpha = 0;
			item.icon.filters = null;
			item.bg.alpha = 0;
			item.hide();
		}
		for (dot in dots) dot.visible = false;
		for (line in lineSprites) line.visible = false;
	}

	function updateItemContent(index:Int, songIdx:Int, item:FreeplaySongItem, dist:Int, instant:Bool):Void
	{
		final chart = preloadedCharts[songIdx];

		if (item.data != chart)
		{
			item.data = chart;
			item.forceResetRank();

			if (item.icon.character != chart.content.meta.opponents[0]) item.icon.character = chart.content.meta.opponents[0];

			final displayName = chart.content.meta.displayName ?? songList[songIdx].song;
			item.nameText.setText(displayName.toUpperCase());
		}

		item.targetScale = Math.max(0.55, 1.0 - dist * 0.22);
		item.targetAlpha = Math.max(0.20, 1.0 - dist * 0.30);

		dots[index].visible = true;
		dots[index].alpha = item.targetAlpha;

		if (instant)
		{
			item.snapToTarget();
			item.applyPositions(itemX, slotBaseY[index] - item.icon.height * item.lerpScale * 0.5);
		}
	}

	function updateItemSelection(index:Int, songIdx:Int, item:FreeplaySongItem, relIdx:Int):Void
	{
		final song = songList[songIdx];
		final scoreData = SongData.retrieveData(song.song, song.difficulty, song.mix);

		item.setSelected(relIdx == 0, scoreData?.score ?? -1, scoreData?.accuracy ?? -1);
		item.bg.alpha = (relIdx == 0) ? 0.9 : 0;

		if (relIdx == 0) updateSelVisuals(songIdx);
	}

	function updateSelVisuals(songIdx:Int):Void
	{
		final chart = preloadedCharts[songIdx];

		Freeplay.instance.stars.difficulty = Chart.calculateDifficultyRating(chart.content.notes, chart.content.meta.bpm);

		try
		{
			SongPreview.loadAndPlay(chart);
		}
		catch (e)
		{
		}

		updateAlbumDisplay(chart);
	}

	function updateAlbumDisplay(chart:Chart):Void
	{
		final album = Paths.exists('images/menus/freeplay/albums/${chart.content.meta.album}.png') ? chart.content.meta.album : 'placeholder';

		if (curAlb != album)
		{
			disk.loadGraphic(Paths.image('menus/freeplay/albums/$album'));

			if (!album.contains('placeholder'))
			{
				albumTitle.frames = Paths.getSparrowAtlas('menus/freeplay/albums/$album-text');
				albumTitle.centerAnimations = true;
				albumTitle.animation.addByPrefix('switch', 'switch', 24, false);
				albumTitle.animation.addByPrefix('idle', 'idle', 24, false);
				albumTitle.animation.onFinish.addOnce(_ -> albumTitle.playAnim('idle'));
				albumTitle.playAnim('switch', true);

				albumTitle.scale.set(0.6, 0.6);
				albumTitle.updateHitbox();
				albumTitle.setPosition(disk.x, disk.y + disk.height - 48);

				albumTitle.alpha = 0;
				albumTitle.visible = true;
				FlxTween.tween(albumTitle, {
					alpha: 1
				}, 0.35, {
					ease: FlxEase.circOut
				});
			}
			else
				albumTitle.visible = false;
		}

		curAlb = album;
	}

	override public function destroy():Void
	{
		preloadedCharts.resize(0);
		super.destroy();
	}
}
