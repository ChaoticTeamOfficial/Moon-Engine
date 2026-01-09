import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;

function onCreate()
{
	var bg = new MoonSprite().loadGraphic(Paths.image('ingame/stages/rain/CH-RN-00'));
	background.add(bg);
	
	bg.setGraphicSize(bg.width * 0.7 * 4);
	bg.updateHitbox();
	bg.screenCenter();
	bg.scrollFactor.set(0.2, 0.2);
	
	var trees = new MoonSprite().loadGraphic(Paths.image('ingame/stages/rain/CH-RN-01'));
	trees.setGraphicSize(trees.width * 0.7 * 4);
	trees.updateHitbox();
	trees.screenCenter();
	trees.x -= 75;
	
	trees.scrollFactor.set(0.45, 0.45);
	background.add(trees);

	var fg = new MoonSprite().loadGraphic(Paths.image('ingame/stages/rain/CH-RN-02'));
	fg.setGraphicSize(fg.width * 0.9 * 4);
	fg.updateHitbox();
	fg.screenCenter();
	fg.x -= 100;
	fg.y -= 200;
	fg.active = trees.active = bg.active = false;
	fg.antialiasing = trees.antialiasing = bg.antialiasing = true;
	background.add(fg);
	
	background.add(background.players);
	background.add(background.opponents);
	
	var rain = new MoonSprite();
	rain.frames = Paths.getSparrowAtlas('ingame/stages/rain/NewRAINLayer01');
	rain.animation.addByPrefix('rainin1', 'RainFirstlayer instance 1', 24, true);
	rain.playAnim('rainin1');
	background.add(rain);
	rain.updateHitbox();
	rain.scale.set(1.3, 1.3);
	rain.screenCenter();
	rain.scrollFactor.set(0, 0);
	rain.blend = 0;
	rain.alpha = 0.4;
	
	var rainAlt = new MoonSprite();
	rainAlt.frames = Paths.getSparrowAtlas('ingame/stages/rain/NewRainLayer02');
	rainAlt.animation.addByPrefix('rainin2', 'RainFirstlayer instance 1', 24, true);
	rainAlt.playAnim('rainin2');
	background.add(rainAlt);
	rainAlt.updateHitbox();
	rainAlt.scale.set(1.3, 1.3);
	rainAlt.screenCenter();
	rainAlt.scrollFactor.set(0, 0);
	rainAlt.blend = 0;
	rainAlt.alpha = 0.7;
	
	rain.antialiasing = rainAlt.antialiasing = true;
}

function onPostCreate()
{
	background.cameraSettings = {
		zoom: 0.60,
        startX: 300,
        startY: 500
	};
	
	background.opponents.setPosition(-500, -100);
}