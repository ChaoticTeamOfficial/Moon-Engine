import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;

var animProgress:Int = 0;
var veryFastCar:MoonSprite;
var henchdudes:Array<MoonSprite> = [];
function onCreate()
{
	animProgress = 0;
	final p = 'ingame/stages/limo/';

	var back = new MoonSprite(-325, -200).loadGraphic(Paths.image(p + 'limoSunset'));
	back.scrollFactor.set(0.1, 0.1);
	background.add(back);

	var backDriver = new MoonSprite(1500, 250);
	backDriver.frames = Paths.getSparrowAtlas(p + 'bgLimo');
	backDriver.animation.addByPrefix('drivin', 'background limo pink', 24, true);
	backDriver.playAnim('drivin',true);
	backDriver.scrollFactor.set(0.65, 0.65);
	background.add(backDriver);
	
	for (i in 0...4)
	{
		var dancer = new MoonSprite(1500, backDriver.y - 380);
		dancer.frames = Paths.getSparrowAtlas(p + 'limoDancer');
		dancer.animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8], "", 24, false);
		dancer.animation.addByIndices('danceLeftPause', 'bg dancer sketch PINK', [9, 10, 11, 12, 13, 14], "", 24, false);
		dancer.animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23], "",24, false);
		dancer.animation.addByIndices('danceRightPause', 'bg dancer sketch PINK', [24, 25, 26, 27, 28, 29], "",24, false);
		dancer.scrollFactor.set(backDriver.scrollFactor.x, backDriver.scrollFactor.y);
		background.add(dancer);
		henchdudes.push(dancer);
	}
	
	background.add(background.spectators);
	
	FlxTween.tween(backDriver, {x: -150}, 1.2, {ease: FlxEase.quadOut, startDelay: 1.2, onComplete: function(_)
	{
		for(i in 0...henchdudes.length)
			FlxTween.tween(henchdudes[i], {x: backDriver.x + 290 + (390 *i)}, 0.25, {ease: FlxEase.circOut, startDelay: 0.25 * i});
	}});

	var frontDriver = new MoonSprite(-150, 250);
	frontDriver.frames = Paths.getSparrowAtlas(p + 'limoDrive');
	frontDriver.animation.addByPrefix('ok', 'Limo stage', 24, true);
	frontDriver.playAnim('ok', true);
	background.add(frontDriver);
	
	background.add(background.opponents);
	background.add(background.players);

	veryFastCar = new MoonSprite(1600, 100).loadGraphic(Paths.image(p + 'fastCarLol'));
	veryFastCar.scale.set(0.8, 0.8);
	background.add(veryFastCar);
}

function onPostCreate()
{
	background.cameraSettings = {
		zoom: 0.9,
        startX: 780,
        startY: 100
	};

	game.camGAME.handheldVFX = {xIntensity: 2.2, yIntensity: 3.2, distance: 11, speed: 0.3};

	background.spectators.setPosition(2000, -5);
	background.spectators.scrollFactor.set(0.65, 0.65);
	background.spectators.scale.set(0.7, 0.7);

	background.players.setPosition(950, -88);
	background.opponents.setPosition(100, -215);
	FlxTween.tween(background.spectators, {x: 400}, 1.2, {ease: FlxEase.quadOut, startDelay: 1.2});
}

var carTimer:Float = 0;
function onUpdate(elapsed)
{
	carTimer += elapsed;
	if(carTimer >= FlxG.random.float(6, 10))
	{
		carTimer = 0;
		FlxG.sound.play(Paths.sound('stages/limo/carPass' + FlxG.random.int(0, 1) + '.ogg', "sounds"));
		FlxTween.tween(veryFastCar, {x: -1200}, 0.13, {startDelay: 1, onComplete: (_) -> veryFastCar.x = 1600});
	}
}

final animsOrder:Array<String> = ['danceLeft', 'danceLeftPause', 'danceRight', 'danceRightPause'];
function onBeat()
{
	animProgress += 1;
	for (dancer in henchdudes)
	{
		if(animProgress > animsOrder.length - 1) animProgress = 0;
		dancer.playAnim(animsOrder[animProgress], true);
	}
}