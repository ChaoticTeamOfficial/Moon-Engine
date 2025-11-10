import flixel.FlxG;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;

var trafficLights:MoonSprite;
function onCreate()
{
	final p = 'ingame/stages/phillyStreets-erect/';
	
	var skybox = new FlxBackdrop(Paths.image(p + 'phillySkybox'), 0x01);
	skybox.setPosition(-450, -335);
	skybox.scale.set(0.65, 0.65);
	skybox.scrollFactor.set(0.1, 0.1);
	background.add(skybox);
	skybox.velocity.x = -30;
	
	var skyline = new MoonSprite(-350, -230).loadGraphic(Paths.image(p + 'phillySkyline'));
	skyline.scrollFactor.set(0.2, 0.2);
	background.add(skyline);
	
	var cityback = new MoonSprite(412, 59).loadGraphic(Paths.image(p + 'phillyForegroundCity'));
	cityback.scrollFactor.set(0.3, 0.3);
	background.add(cityback);
	
	var building = new MoonSprite(1525, 0).loadGraphic(Paths.image(p + 'phillyConstruction'));
	building.scrollFactor.set(0.7, 1);
	background.add(building);

	var highwayLights = new MoonSprite(182, -70).loadGraphic(Paths.image(p + 'phillyHighwayLights'));
	background.add(highwayLights);
	//meh

	var highway = new MoonSprite(100, -140).loadGraphic(Paths.image(p + 'phillyHighway'));
	background.add(highway);
	
	for(i in 0...2)
	{
		var grad = new MoonSprite(40, -290).loadGraphic(Paths.image(p + 'greyGradient'));
		grad.alpha = (i == 0) ? 0.3 : 0.8;
		background.add(grad);
	}
	
	trafficLights = new MoonSprite(1900, 300);
	trafficLights.frames = Paths.getSparrowAtlas(p + 'phillyTraffic');
	trafficLights.animation.addByPrefix('tored', 'greentored', 24, false);
	trafficLights.animation.addByPrefix('togreen', 'redtogreen', 24, false);
	trafficLights.playAnim('rtg', true);
	background.add(trafficLights);
	
	var fg = new MoonSprite().loadGraphic(Paths.image(p + 'phillyForeground'));
	background.add(fg);

	background.add(background.spectators);
	background.add(background.opponents);
	background.add(background.players);
}

function onPostCreate()
{
	background.cameraSettings = {
		zoom: 0.85,
        startX: 1100,
        startY: 520
	};

	background.spectators.setPosition(1080, 90);
	background.opponents.setPosition(700, 340);
	background.players.setPosition(1820, 500);
	
	final values = {hue: -5, saturation: -40, brightness: -20, contrast: -25};
	background.adjustGroupColor(background.players, values);
	background.adjustGroupColor(background.spectators, values);
	background.adjustGroupColor(background.opponents, values);
	
	game.camGAME.zoom = 0.85;
}

var lightsStop:Bool = false;
var lastChange:Int = 0;
var changeInterval:Int = 8;

var carWaiting:Bool = false;
var carInterruptable:Bool = true;
var car2Interruptable:Bool = true;

function onUpdate(elapsed)
{
}

function onBeat(beat)
{
	if (beat == (lastChange + changeInterval)) changeLights(beat);
}

function changeLights(beat:Int)
{
	lastChange = beat;
	lightsStop = !lightsStop;

	if(lightsStop){
		trafficLights.playAnim('tored', true);
		changeInterval = 20;
	} else {
		trafficLights.playAnim('togreen', true);
		changeInterval = 30;
	}
}