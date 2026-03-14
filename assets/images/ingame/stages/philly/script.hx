import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;
import moon.dependency.MoonSound;
import moon.dependency.user.MoonSettings;
import moon.hardcoded_shaders.DropShadowShader;
import flixel.math.FlxMath;
import Shortcuts;

var trainSound:MoonSound;

var trainMoving:Bool = false;
var trainFinishing:Bool = false;
var trainEnabled:Bool = true;

var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainCooldown:Int = 0;

function onPostCreate()
{
	// preload the train sound.
	trainSound = new MoonSound().loadEmbedded(Paths.sound('stages/philly/train_passes.ogg', 'sounds'), false, false);
	
	// oh yeah for a sound to update you gotta **add** it. thats stupid...
	game.add(trainSound);
	
	if(trainSound.playing) trainSound.stop();
	trainSound.volume = MoonSettings.callSetting('SFX Volume') / 100;
}

final lightColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFBA633, 0xFFFD4531];
function onBeat(beat)
{
	// does the thingy on the building windows every four beats
	if(beat % 4 == 0)
	{
		background.getObject('win').color = lightColors[FlxG.random.int(0, lightColors.length - 1)];
		background.getObject('win').alpha = 1;
	}
	
	if (trainEnabled)
    {
		// update the train's cooldown
		if (!trainMoving) trainCooldown += 1;

		// start train
		if (beat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
		{
			trainCooldown = FlxG.random.int(-4, 0);
			trainStart();
		}
    }
}

function onUpdate(elapsed)
{
	background.getObject('win').alpha = FlxMath.lerp(background.getObject('win').alpha, 0.3, elapsed);
	
	// update some train stuff
    if (trainEnabled && trainMoving)
    {
		trainFrameTiming += elapsed;

		if (trainFrameTiming >= 1 / 24)
		{
			updateTrainPos();
			trainFrameTiming = 0;
		}
    }
}

function trainStart():Void
{
	trainMoving = true;
	trainSound.play(true);
}

var startedMoving:Bool = false;

function updateTrainPos():Void
{
	if (trainSound.time >= 4700)
	{
		startedMoving = true;
		Shortcuts.getSpectator().playAnim('idle-0', true);
	}

	if (startedMoving)
	{
		var train = background.getObject('train');
		train.x -= 400;

		if (train.x < -2000 && !trainFinishing)
		{
			train.x = -1150;
			trainCars -= 1;

			if (trainCars <= 0) trainFinishing = true;
		}

		if (train.x < -4000 && trainFinishing) trainReset();
	}
}

function trainReset():Void
{
	Shortcuts.getSpectator().playAnim('idle-0', true);
	background.getObject('train').x = 2000;

	trainMoving = false;
	trainCars = 8;
	trainFinishing = false;
	startedMoving = false;
}

function addShader(character:MoonSprite)
{
	/*if(character==null) return;
	
	if(Std.isOfType(character, MoonSprite))
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFff6b6b;
		character.shader = rim;
		rim.attachedSprite = character;
		rim.angle = 90;

		character.animation.onFrameChange.add(() -> rim.updateFrameInfo(character.frame));
	}*/
}