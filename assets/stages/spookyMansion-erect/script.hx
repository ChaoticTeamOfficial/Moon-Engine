import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import moon.dependency.MoonSprite;
import moon.dependency.MoonSound;
import moon.dependency.user.MoonSettings;
import moon.hardcoded_shaders.DropShadowShader;
import moon.game.PlayState;
import Shortcuts;

var lightningStrikeBeat:Int = 0;
var lightningStrikeOffset:Int = 8;

function onPostCreate()
{
	for (snd in ["thunder_1", "thunder_2"]) FlxG.sound.cache(Paths.sound('stages/spookyMansion-erect/' + snd + '.ogg', 'sounds'));
}

function onBeat(beat)
{
	if (beat == 4 && PlayState.songData.song == "spookeez") doLightningStrike(false, beat);

	if (FlxG.random.bool(10) && beat > (lightningStrikeBeat + lightningStrikeOffset)) doLightningStrike(true, beat);
}

function onUpdate(elapsed)
{
}

function doLightningStrike(playSound:Bool, beat:Int)
{
	if (playSound) Paths.playSFX('stages/spookyMansion-erect/thunder_' + FlxG.random.int(1, 2) + '.ogg', true);

	lightningStrikeBeat = beat;
	lightningStrikeOffset = FlxG.random.int(8, 24);

	background.getObject('stairsLight').alpha = background.getObject('bgLight').alpha = 1;

	new FlxTimer().start(0.06, _ ->
	{
		background.getObject('stairsLight').alpha = background.getObject('bgLight').alpha = 0;
	});

	new FlxTimer().start(0.12, _ ->
	{
		background.getObject('stairsLight').alpha = background.getObject('bgLight').alpha = 1;

		for (bgEl in [
			background.getObject('stairsLight'),
			background.getObject('bgLight')
		]) FlxTween.tween(bgEl, {
			alpha: 0
		}, 1.5);
	});
}
