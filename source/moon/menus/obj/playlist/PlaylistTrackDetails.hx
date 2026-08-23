package moon.menus.obj.playlist;

import flixel.group.FlxSpriteGroup;
import moon.global_obj.PixelIcon;
import moon.backend.gameplay.Timings;
import moon.menus.obj.freeplay.FreeplayRank;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextFormat;
import openfl.text.TextFormat;
import openfl.media.Sound;
import flixel.sound.FlxSound;
import flixel.util.FlxStringUtil;
import lime.app.Future;
import moon.menus.obj.freeplay.SongPreview;
import moon.menus.obj.freeplay.FreeplayRank;
import moon.backend.gameplay.Timings;
import moon.backend.data.SongData;
import moon.backend.data.SongData.SongScoreData;

using StringTools;

class PlaylistTrackDetails extends FlxSpriteGroup
{
	public var trackTitle:FlxText;
	public var album:MoonSprite;
	public var albumTitle:MoonSprite;
	public var trackIcon:PixelIcon;
	public var trackName:FlxText;
	public var songArtist:FlxText;
	public var bestRank:FreeplayRank;
	public var separator:MoonSprite;
	public var infoText:FlxText;
	public var infoValues:FlxText;
	public var bpm:Float = 0;
	public var duration:Float = 0;
	public var difficulty:Int = 0;
	public var scrollSpeed:Float = 0;

	var nullChart:Bool = false;
	var _prevMusic:FlxSound;
	var curAlb:Null<String>;
	var diffLerp:Float = 0;
	var durLerp:Float = 0;
	var bpmLerp:Float = 0;
	var scrollLerp:Float = 0;

	public function new()
	{
		super();

		trackTitle = new FlxText(0, 30, 0, 'TRACK DETAILS');
		trackTitle.setFormat(Paths.font('phantomuff/difficulty.ttf'), 40, FlxColor.WHITE);
		add(trackTitle);

		album = new MoonSprite();
		album.loadGraphic(Paths.image('menus/freeplay/albums/expansion1'));
		album.scale.set(0.85, 0.85);
		album.updateHitbox();
		album.x = trackTitle.x + (trackTitle.width - album.width) / 2;
		album.y = trackTitle.y + trackTitle.height + 10;
		add(album);

		albumTitle = new MoonSprite();
		albumTitle.setPosition(trackTitle.x + (trackTitle.width - albumTitle.width) / 2, album.y + album.height + 5);
		add(albumTitle);

		trackIcon = new PixelIcon();
		trackIcon.x = -45;
		trackIcon.y = albumTitle.y + 60;
		add(trackIcon);

		trackName = new FlxText(0, 250, 0, 'TRACK NAME');
		trackName.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.WHITE);
		trackName.y = albumTitle.y + 60;
		add(trackName);

		songArtist = new FlxText(0, 250, 0, 'TRACK ARTIST');
		songArtist.setFormat(Paths.font('phantomuff/full.ttf'), 12, FlxColor.WHITE);
		songArtist.y = trackName.y + trackName.height + 2;
		add(songArtist);

		bestRank = new FreeplayRank(0);
		bestRank.updateHitbox();
		bestRank.y = trackName.y + trackName.height - 20;
		bestRank.x = this.width - bestRank.width;
		add(bestRank);

		separator = new MoonSprite(-45, songArtist.y + songArtist.height + 10).makeGraphic(415, 1, FlxColor.WHITE);
		add(separator);

		var textFormat:TextFormat = new TextFormat();
		textFormat.leading = 10; // Do i really need to do this just to make line spacing bigger? :sob:

		infoText = new FlxText(-45, separator.y + 20, 0, 'Difficulty:\nDuration:\nBPM:\nScroll Speed:');
		infoText.textField.defaultTextFormat = textFormat;
		infoText.textField.setTextFormat(textFormat);
		infoText.setFormat(Paths.font('phantomuff/full.ttf'), 18, FlxColor.WHITE);
		add(infoText);

		infoValues = new FlxText(0, separator.y + 20, 100, '67\n99:99\n999\n3.14');
		infoValues.textField.defaultTextFormat = textFormat;
		infoValues.textField.setTextFormat(textFormat);
		infoValues.setFormat(Paths.font('phantomuff/full.ttf'), 18, FlxColor.WHITE, FlxTextAlign.RIGHT);
		infoValues.x = separator.x + separator.width - infoValues.width;
		add(infoValues);
	}

	public function updateTrackDetails(songData:Chart, delta:Int):Void
	{
		updateAlbumDisplay(songData, delta);
		updateTrackInfo(songData);
	}

	public function updateTrackInfo(chart:Chart):Void
	{
		nullChart = chart?.content == null;
		if (nullChart) return;

		var songBpm:Float = chart.content.meta.bpm;
		var scroll:Float = chart.content.meta.scrollSpd;
		var difficultyAmount:Int = chart.getDifficultyRating();

		SongPreview.loadAndPlay(chart);

		var savedData:SongScoreData = SongData.retrieveData({
			song: chart.song,
			difficulty: chart.difficulty,
			mix: chart.mix
		});
		savedData ??= {
			score: 0,
			misses: 0,
			accuracy: 0
		};
		bestRank.setRank(Timings.getRank(savedData.accuracy).rank);
		bestRank.visible = savedData.accuracy > 0;

		duration = 0;
		trackIcon.character = chart.content.meta.opponents[0];
		trackIcon.scale.set(1.25, 1.25);
		trackName.text = chart.content.meta.displayName;
		songArtist.text = 'By: ${chart.content.meta.artist}';

		difficulty = difficultyAmount;
		bpm = songBpm;
		scrollSpeed = scroll;
	}

	function updateAlbumDisplay(chart:Chart, delta:Int):Void
	{
		if (chart?.content == null) return;

		final albumName = Paths.exists('images/menus/freeplay/albums/${chart.content.meta.album}.png') ? chart.content.meta.album : 'placeholder';

		if (curAlb != albumName)
		{
			album.loadGraphic(Paths.image('menus/freeplay/albums/$albumName'));
			album.alpha = album.angle = 0;
			album.offset.y = delta == 1 ? 50 : -50;
			FlxTween.cancelTweensOf(album);
			FlxTween.tween(album, {
				"offset.y": 0,
				angle: FlxG.random.int(-8, 8),
				alpha: 1
			}, 0.35, {
				ease: FlxEase.circOut
			});

			if (!albumName.contains('placeholder'))
			{
				albumTitle.frames = Paths.getSparrowAtlas('menus/freeplay/albums/$albumName-text');
				albumTitle.centerAnimations = true;
				albumTitle.animation.addByPrefix('switch', 'switch', 24, false);
				albumTitle.animation.addByPrefix('idle', 'idle', 24, false);
				albumTitle.animation.onFinish.addOnce(_ -> albumTitle.playAnim('idle'));
				albumTitle.playAnim('switch', true);

				albumTitle.scale.set(0.6, 0.6);
				albumTitle.updateHitbox();
				albumTitle.setPosition(trackTitle.x + (trackTitle.width - albumTitle.width) / 2, album.y + album.height - 50);

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

		curAlb = albumName;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (nullChart)
		{
			trackName.text = '------------';
			songArtist.text = 'By: ---------';
			infoValues.text = '---\n--:--\n---\n---';
			bestRank.visible = false;
			return;
		}

		if (_prevMusic != FlxG.sound.music && FlxG.sound.music?.length != 0)
		{
			_prevMusic = FlxG.sound.music;
			duration = FlxG.sound.music?.length / 1000;
		}

		durLerp = FlxMath.lerp(durLerp, duration, 0.15);
		diffLerp = FlxMath.lerp(diffLerp, difficulty, 0.15);
		bpmLerp = FlxMath.lerp(bpmLerp, bpm, 0.15);
		scrollLerp = FlxMath.lerp(scrollLerp, scrollSpeed, 0.15);

		var durationFormat:String = duration > 0 ? FlxStringUtil.formatTime(durLerp) : '--:--';
		infoValues.text = '${Std.int(diffLerp)}\n$durationFormat\n${Std.int(bpmLerp)}\n${FlxMath.roundDecimal(scrollLerp, 2)}';
	}
}
