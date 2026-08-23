package moon.menus;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.FlxBasic;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxStringUtil;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxSpriteUtil;
import moon.global_obj.Alphabet;
import moon.menus.obj.story.StoryWeek;
import moon.menus.obj.story.DifficultySelector;
import moon.backend.data.SongData.SongScoreData;
import moon.game.obj.HealthIcon;
import moon.game.PlayState;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxAxes;

// this been sitting around for way too long lol...
class Story extends FlxState
{
	var currentLevelId:String = 'tutorial';
	var curSelected:Int = -1;
	// var isLevelUnlocked:Bool;
	var highScore:Int = 42069420;
	var highScoreTween:FlxTween;
	var selectedLevel:Bool = false;

	public var bg:FlxSprite;
	public var backdrop1:FlxBackdrop;
	public var backdrop2:FlxBackdrop;
	public var bgGradient:FlxSprite;
	public var lpGradientUp:FlxSprite;
	public var lpGradientDown:FlxSprite;
	public var rp:MoonSprite;
	public var lp:MoonSprite;
	public var pickWeek:MoonSprite;
	public var selector:MoonSprite;
	public var selectorDim:MoonSprite;
	public var scoreTitle:FlxText;
	public var descriptionTxt:FlxText;
	public var tracksTitle:FlxText;
	public var tracksTxt:FlxText;
	public var scoreTxt:FlxText;
	public var weekCharacter:MoonSprite;
	public var weekCharacters:FlxSpriteGroup;
	public var weekList:FlxTypedSpriteGroup<StoryWeek>;
	public var curDifficultySelector:Null<DifficultySelector>;

	var isSelecting:Bool = false;

	public var backBf:FlxBackdrop;
	public var backBf2:FlxBackdrop;
	public var backDad:FlxBackdrop;
	public var backDad2:FlxBackdrop;

	override public function create():Void
	{
		super.create();

		FlxG.camera.bgColor = 0x0;

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xfffff465);
		FlxGradient.overlayGradientOnFlxSprite(bg, Std.int(bg.width + 500), Std.int(bg.height), [0xffcdc344, 0x00ddd354], 0, 0, 1, 0);
		add(bg);

		backBf = new FlxBackdrop();
		backBf2 = new FlxBackdrop(0, 150);
		backDad = new FlxBackdrop();
		backDad2 = new FlxBackdrop(150, 200);

		final graphic:FlxGraphic = Paths.image('bf/icon', 'characters');
		final graphic2:FlxGraphic = Paths.image('gf/icon', 'characters');
		backBf.loadGraphic(graphic, true, Std.int(graphic.width / 2), Std.int(graphic.height));
		backBf.animation.add('icon', [0, 1], 0, false);
		backBf.animation.play('icon');
		backBf.spacing.set(150, 150);
		add(backBf);

		backDad.loadGraphic(graphic2);
		backDad.spacing.set(150, 150);
		backDad.x = 150;
		backDad.flipX = true;
		add(backDad);

		backBf2.loadGraphic(graphic, true, Std.int(graphic.width / 2), Std.int(graphic.height));
		backBf2.animation.add('icon', [0, 1], 0, false);
		backBf2.animation.play('icon');
		backBf2.spacing.set(150, 150);
		backBf2.setPosition(150, 150);
		backBf2.flipX = true;
		add(backBf2);

		backDad2.loadGraphic(graphic2);
		backDad2.spacing.set(150, 150);
		backDad2.y = 150;
		add(backDad2);

		FlxSpriteUtil.setTint(backDad, 0xffddd354);
		FlxSpriteUtil.setTint(backDad2, 0xffddd354);
		FlxSpriteUtil.setTint(backBf, 0xffddd354);
		FlxSpriteUtil.setTint(backBf2, 0xffddd354);

		lp = new MoonSprite(-10, 0, Paths.image('menus/story/LP'));
		add(lp);

		rp = new MoonSprite(-10, 0, Paths.image('menus/story/RP'));
		rp.setPosition(FlxG.width - rp.width + 10, 500);
		add(rp);

		pickWeek = new MoonSprite(40, 30, Paths.image('menus/story/pickweek'));
		add(pickWeek);

		selector = new MoonSprite(60, 30, Paths.image('menus/story/arrow-selector'));
		add(selector);

		scoreTitle = new FlxText(30, 670, 0, 'BEST SCORE:');
		scoreTitle.setFormat(Paths.font('phantomuff/difficulty.ttf'), 40);
		add(scoreTitle);

		scoreTxt = new FlxText(scoreTitle.x + scoreTitle.width + 4, scoreTitle.y, 0, '49850934');
		scoreTxt.setFormat(Paths.font('phantomuff/difficulty.ttf'), 40);
		add(scoreTxt);

		descriptionTxt = new FlxText(30, scoreTitle.y - 20, 0, '');
		descriptionTxt.setFormat(Paths.font('phantomuff/full.ttf'), 20);
		add(descriptionTxt);

		tracksTitle = new FlxText(rp.x + 330, rp.y + 30, 0, 'TRACKS');
		tracksTitle.setFormat(Paths.font('phantomuff/full.ttf'), 26);
		tracksTitle.color = 0xfffc724a;
		add(tracksTitle);

		tracksTxt = new FlxText(rp.x + 310, rp.y + 70, 150, 'TRACKS');
		tracksTxt.setFormat(Paths.font('phantomuff/full.ttf'), 16);
		tracksTxt.alignment = 'center';
		add(tracksTxt);

		weekCharacter = new MoonSprite(700, 160);
		weekCharacter.frames = Paths.getSparrowAtlas('menus/story/characters/gf');
		weekCharacter.animation.addByPrefix('idle', 'idle', 24, true);
		weekCharacter.animation.play('idle');
		add(weekCharacter);

		weekCharacters = new FlxSpriteGroup();
		weekList = new FlxTypedSpriteGroup<StoryWeek>();
		add(weekList);

		initializeWeeks();

		lpGradientUp = FlxGradient.createGradientFlxSprite(520, 180, [0xFF0f0916, 0x000f0916]);
		lpGradientUp.setPosition(10, lp.y + 199);
		add(lpGradientUp);

		lpGradientDown = FlxGradient.createGradientFlxSprite(520, 180, [0xFF0f0916, 0x000f0916], 1, -90);
		lpGradientDown.setPosition(10, lp.y + 450);
		add(lpGradientDown);

		selectorDim = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0D0316);
		selectorDim.alpha = 0;
		add(selectorDim);

		changeSelection(1);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		for (idx => text in weekList.members)
		{
			text.alpha = FlxMath.lerp(text.alpha, curSelected == idx ? 1 : 0.4, 0.1);
			text.x = FlxMath.lerp(text.x, curSelected == idx ? 130 : 80, 0.1);
			selector.y = FlxMath.lerp(selector.y, weekList.members[curSelected].y + selector.height / 3, 0.075);
		}

		selector.x = FlxMath.lerp(selector.x, weekList.members[curSelected].x - selector.width - 15, 0.075);
		weekList.clipRect = new FlxRect(0, Math.abs(weekList.y) + 200, FlxG.width, 430);

		if (weekList.y < -10)
		{
			FlxTween.cancelTweensOf(lpGradientUp);
			FlxTween.tween(lpGradientUp, {
				alpha: 1
			}, 0.2);
		}
		else
			FlxTween.tween(lpGradientUp, {
				alpha: 0
			}, 0.4);

		scoreTxt.text = FlxStringUtil.formatMoney(highScore, false, true);

		if (MoonInput.justPressed(BACK))
		{
			if (isSelecting)
			{
				if (!curDifficultySelector.ready) return;

				curDifficultySelector.close(() ->
				{
					isSelecting = false;
					curDifficultySelector = null;
					FlxTween.tween(selectorDim, {
						alpha: 0
					}, 0.5);
				});

				return;
			}

			FlxG.switchState(() -> new moon.menus.MainMenu());
		};

		if (MoonInput.justPressed(ACCEPT)) confirmWeek();

		if (isSelecting) return;
		if (MoonInput.justPressed(UI_UP)) changeSelection(-1);
		else if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
	}

	function initializeWeeks():Void
	{
		var index:Int = 0;
		for (week in SongLibrary.get().categoryOrder)
		{
			if (week == 'all') continue;
			trace('week: $week');

			var object = new StoryWeek(0, 200 + (index * 80), week);
			weekList.add(object);

			index++;
		}
	}

	function confirmWeek()
	{
		if (isSelecting)
		{
			if (!curDifficultySelector.ready) return;

			var weekSonglist = SongLibrary.instance.weekSonglist(currentLevelId);
			var difficultyId:String = curDifficultySelector.currentDifficulty ?? 'hard';

			for (song in weekSonglist)
			{
				song.difficulty = difficultyId;
				// song.mix = currentMixId;
			}
			trace('Week selrcsted!: $currentLevelId, Playlist: ${weekSonglist}');

			PlayState.queuePlaylist(SongLibrary.instance.weekSonglist(currentLevelId));
			FlxG.switchState(() -> new LoadingScreen());

			return;
		}

		curDifficultySelector = new DifficultySelector(currentLevelId);
		curDifficultySelector.screenCenter();
		curDifficultySelector.open();
		add(curDifficultySelector);

		isSelecting = true;

		FlxTween.tween(selectorDim, {
			alpha: 0.5
		}, 0.75);
	}

	function changeSelection(change:Int = 0):Void
	{
		if (curDifficultySelector != null) return;

		Paths.playSFX('ui/scrollMenu.ogg');
		curSelected = FlxMath.wrap(curSelected + change, 0, weekList.length - 1);
		if (curSelected > 2)
		{
			FlxTween.cancelTweensOf(weekList);
			FlxTween.tween(weekList, {
				y: (curSelected - 2) * -80
			}, 0.5, {
				ease: FlxEase.circOut
			});
		}
		else
		{
			FlxTween.cancelTweensOf(weekList);
			FlxTween.tween(weekList, {
				y: 0
			}, 0.5, {
				ease: FlxEase.circOut
			});
		}

		currentLevelId = weekList.members[curSelected].weekId;

		var curWeek:Week = Week.get(currentLevelId);
		descriptionTxt.text = '"${curWeek.description}"';

		var totalScore:Int = 0;
		var totalTracks:String = '';
		for (idx => track in curWeek.tracks)
		{
			var trackData:SongScoreData = SongData.retrieveData({
				song: track,
				difficulty: 'hard',
				mix: curWeek.mainMix
			});

			var chartData:Chart = new Chart(track, 'hard', curWeek.mainMix);
			totalScore += trackData?.score ?? 0;

			totalTracks += '${chartData.content.meta.displayName}\n';
			// trace('Track: $track, retrieved: ${SongData.retrieveData(track, currentDifficultyId, curWeek.mainMix)}');
		}
		tracksTxt.text = totalTracks;

		highScoreTween?.cancel();
		highScoreTween = FlxTween.num(highScore, totalScore, 0.5, {
			ease: FlxEase.cubeOut
		}, (value) -> highScore = Math.floor(value));
	}
}
