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
import moon.backend.data.SongData.SongScoreData;
import moon.game.obj.HealthIcon;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxAxes;

//this been sitting around for way too long lol...
class Story extends FlxState
{
	var currentDifficultyId:String = 'hard';
	var currentLevelId:String = 'tutorial';
	var curSelected:Int;
	//var currentLevel:Level;
	//var isLevelUnlocked:Bool;
	var highScore:Int = 42069420;
	var highScoreLerp:Int = 12345678;
	var highScoreTween:FlxTween;
	var selectedLevel:Bool = false;

	public var bg:FlxSprite;
	public var backdrop1:FlxBackdrop;
	public var backdrop2:FlxBackdrop;
	public var bgGradient:FlxSprite;
	public var lp:MoonSprite;
	public var lpGradientUp:FlxSprite;
	public var lpGradientDown:FlxSprite;
	public var rp:MoonSprite;
	public var pickWeek:MoonSprite;
	public var selector:MoonSprite;
	public var scoreTitle:FlxText;
	public var descriptionTxt:FlxText;
	public var tracksTitle:FlxText;
	public var tracksTxt:FlxText;
	public var scoreTxt:FlxText;
	public var levelCharacter:MoonSprite;
	public var levelCharacters:FlxSpriteGroup;
	public var levelList:FlxTypedSpriteGroup<StoryWeek>;
	var icon1 = new HealthIcon();
	var icon2 = new HealthIcon();
	var backBf:FlxBackdrop;
	var backBf2:FlxBackdrop;
	var backDad:FlxBackdrop;
	var backDad2:FlxBackdrop;

	override public function create():Void
	{
		super.create();

		FlxG.signals.postUpdate.add(function() {
			if(FlxG.keys.justPressed.F4) FlxG.switchState(() -> new moon.menus.MainMenu());
		});

		FlxG.camera.bgColor = 0x0;
		
		icon1.icon = 'bf';
		icon2.icon = 'gf';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xfffff465);
		FlxGradient.overlayGradientOnFlxSprite(bg, Std.int(bg.width + 500), Std.int(bg.height), [0xffddd354, 0x00ddd354], 0, 0, 1, 0);
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

		levelCharacter = new MoonSprite(700, 160);
		levelCharacter.frames = Paths.getSparrowAtlas('menus/story/characters/gf');
		levelCharacter.animation.addByPrefix('idle', 'idle', 24, true);
		levelCharacter.animation.play('idle');
		add(levelCharacter);

		levelCharacters = new FlxSpriteGroup();
		levelList = new FlxTypedSpriteGroup<StoryWeek>();
		add(levelList);

		var index:Int = 0;
		for(week in SongLibrary.get().songsByWeek.keys()) {
			if(week == 'all') continue;
			trace('week: $week');
			
			var object = new StoryWeek(0, 200 + (index * 80), week);
			levelList.add(object);

			index++;
		}

		lpGradientUp = FlxGradient.createGradientFlxSprite(520, 180, [0xFF0f0916, 0x000f0916]);
		lpGradientUp.setPosition(10, lp.y + 199);
		add(lpGradientUp);

		lpGradientDown = FlxGradient.createGradientFlxSprite(520, 180, [0xFF0f0916, 0x000f0916], 1, -90);
		lpGradientDown.setPosition(10, lp.y + 450);
		add(lpGradientDown);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

        if (MoonInput.justPressed(UI_UP)) changeSelection(-1);
        else if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);

		for(idx => text in levelList.members) {
			text.alpha = FlxMath.lerp(text.alpha, curSelected == idx ? 1 : 0.4, 0.1);
			text.x = FlxMath.lerp(text.x, curSelected == idx ? 130 : 80, 0.1);
			selector.y = FlxMath.lerp(selector.y, levelList.members[curSelected].y + selector.height / 3, 0.075);
		}

		selector.x = FlxMath.lerp(selector.x, levelList.members[curSelected].x - selector.width - 15, 0.075);
		levelList.clipRect = new FlxRect(0, Math.abs(levelList.y) + 200, FlxG.width, 430);

		if(levelList.y < -10) {
			FlxTween.cancelTweensOf(lpGradientUp);
			FlxTween.tween(lpGradientUp, {alpha: 1}, 0.2);
		}
		else 
			FlxTween.tween(lpGradientUp, {alpha: 0}, 0.4);

		scoreTxt.text = FlxStringUtil.formatMoney(highScore, false, true);
	}

	function changeSelection(change:Int = 0):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, levelList.length - 1);
        Paths.playSFX('ui/scrollMenu.ogg');

		if(curSelected > 2) {
			FlxTween.cancelTweensOf(levelList);
			FlxTween.tween(levelList, {y: (curSelected - 2) * -80}, 0.5, {ease: FlxEase.circOut});
		} else {
			FlxTween.cancelTweensOf(levelList);
			FlxTween.tween(levelList, {y: 0}, 0.5, {ease: FlxEase.circOut});
		}

		currentLevelId = levelList.members[curSelected].weekId;

		var curWeek:Week = Week.get(currentLevelId);
		descriptionTxt.text = '"${curWeek.description}"';

		var totalScore:Int = 0;
		var totalTracks:String = '';
		for(idx => track in curWeek.tracks) {
			var trackData:SongScoreData = SongData.retrieveData(track, currentDifficultyId, curWeek.mainMix);
			var chartData:Chart = new Chart(track, currentDifficultyId, curWeek.mainMix);
			totalScore += trackData?.score ?? 0;

			totalTracks += '${chartData.content.meta.displayName}\n';
			//trace('Track: $track, retrieved: ${SongData.retrieveData(track, currentDifficultyId, curWeek.mainMix)}');
		}
		tracksTxt.text = totalTracks;
		
		highScoreTween?.cancel();
		highScoreTween = FlxTween.num(highScore, totalScore, 0.7, {ease: FlxEase.cubeOut}, (value) -> highScore = Math.floor(value));
    }

	inline function getDegreesFromPoint(xx:Float, yy:Float) {
		// now to get polar degrees (theta) we do tan^-1(yy/xx)
		var theta:Float = Math.atan(yy/xx);

		// flixel returns radians bruh, so lets make this
		var degrees:Float = theta * (180/Math.PI);

		return degrees;
	}
}