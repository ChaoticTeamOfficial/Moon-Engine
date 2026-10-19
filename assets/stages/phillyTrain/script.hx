// TODO: Make literally anything work
/*
import flixel.FlxG;
import flixel.addons.display.FlxRuntimeShader;
import moon.game.PlayState;
import moon.dependency.MoonSprite;
import Shortcuts;

var curLight:Int;
var lightColors:Array<FlxColor> = [
  0xFF31A2FD,
  0xFF31FD8C,
  0xFFFB33F5,
  0xFFFBA633,
  0xFFFD4531
];
var lightWindow:MoonSprite;
var lightShader:FlxRuntimeShader;
var trainSound;
var trainEnabled:Bool = true;

function onPostCreate()
{
  trainEnabled = true;

  if (PlayState.instance == null) trainEnabled = false;

  // NOTE: You pass the constructor variables directly, not as an array.
  lightShader = new BuildingEffectShader(1.0);
  trainSound = FlxG.sound.cache(Paths.sound('stages/phillyTrain/sounds/train-passes.ogg', 'sounds'));

  lightWindow = background.getObject('lights');
  lightWindow.shader = lightShader;
}

var trainMoving:Bool = false;
var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainFinishing:Bool = false;
var trainCooldown:Int = 0;

function onUpdate(elapsed)
{
  // Update beat lights
  var shaderInput:Float = (game.conductor.beat / 1000) * elapsed * 1.5;
  lightShader.update(shaderInput);

  // Update train
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

function onBeatHit(beat)
{
  if (trainEnabled)
  {
    // Update train cooldown
    if (!trainMoving) trainCooldown += 1;

    // Start train
    if (beat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
    {
      trainCooldown = FlxG.random.int(-4, 0);
      trainStart();
    }
  }

  // Update lights
  if (beat % 4 == 0)
  {
    // Reset opacity
    lightShader.reset();

    // Switch to a different light
    curLight = FlxG.random.int(0, lightColors.length - 1);
    lightWindow.color = lightColors[curLight];
  }
}

function onSongEnd()
{
  trainMoving = false;
  trainEnabled = false;
  if (trainSound != null)
  {
    trainSound.stop();
    trainSound = null;
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
    Shortcuts.getSpectator().playAnimation('hairBlow');
  }

  if (startedMoving)
  {
    var train:MoonSprite = background.getObject('train');
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

function trainReset()
{
  if (startedMoving) Shortcuts.getSpectator().playAnimation('hairFall');

  background.getObject('train').x = FlxG.width + 200;

  trainMoving = false;
  trainCars = 8;
  trainFinishing = false;
  startedMoving = false;
}
*/

/**
 * Make sure the train is reset when the song restarts.
 */
/*
function onSongRetry()
{
  trainReset();

  if (trainSound != null) trainSound.stop();

  if (Shortcuts.getSpectator() != null)
  {
    Shortcuts.getSpectator().dance(true);
    Shortcuts.getSpectator().animation.finish();
  }
}

function kill()
{
  lightShader = null;
}
*/
