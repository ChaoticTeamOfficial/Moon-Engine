import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;

function onCreate()
{
	var bg = new MoonSprite();
	bg.frames = Paths.getSparrowAtlas('ingame/stages/cg/CGBG');
	bg.animation.addByPrefix('new', 'new', 24, true);
	bg.playAnim('new');
	background.add(bg);
	bg.updateHitbox();
	bg.screenCenter();
	bg.antialiasing = true;
	
	background.add(background.spectators);
	background.add(background.opponents);
	background.add(background.players);
}

function onPostCreate()
{
	background.cameraSettings = {
		zoom: 0.68,
        startX: 550,
        startY: 400
	};
	
	var weh = new MoonSprite().loadGraphic(Paths.image('ingame/stages/cg/52'));
	background.add(weh);
	weh.camera = game.camHUD;
	weh.updateHitbox();
	weh.screenCenter();
	weh.antialiasing = true;
	weh.blend = 0;
	weh.alpha = 0.4;
	
	background.opponents.setPosition(-50, 240);
	background.spectators.setPosition(310, 140);
	background.players.setPosition(700, 550);
	
	final ye = {hue: -38, saturation: 10, brightness: 1+5, contrast: -5};
	background.adjustGroupColor(background.players, ye);
	background.adjustGroupColor(background.spectators, ye);
	background.adjustGroupColor(background.opponents, ye);
}