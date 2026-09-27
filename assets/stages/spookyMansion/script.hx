import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import moon.dependency.MoonSprite;
import moon.dependency.MoonSound;
import moon.dependency.user.MoonSettings;
import moon.hardcoded_shaders.DropShadowShader;
import moon.hardcoded_shaders.SilhouetteGlowShader;
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
	if (playSound) Paths.playSFX('stages/spookyMansion-erect/thunder_' + FlxG.random.int(1, 2) + '.ogg', 'sounds', true);

	lightningStrikeBeat = beat;
	lightningStrikeOffset = FlxG.random.int(8, 24);

	background.getObject('halloween_bg').playAnim("lightning", true);
	
	if (Shortcuts.getPlayer() != null)
		Shortcuts.getPlayer().playAnim('scared', true);
	  
	if (Shortcuts.getSpectator() != null)
		Shortcuts.getSpectator().playAnim('scared', true);
}
