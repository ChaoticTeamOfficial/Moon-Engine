import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;
import moon.game.PlayState;

var rainShader:RainShader;
var rainFilter:ShaderFilter;

// I don't want to do a switch cause I'm a bitch
// so! put the song ID on the left, then, the array's
// first value is the intensity on the song start, and the last is
// on the song end, it'll smoothly go from the first value to the second one throughout the song.
final rainIntensityMap = {
	'darnell': [0.04, 0.06],
	'lit-up': [0.06, 0.08],
	'2-hot': [0.08, 0.12]
};

function onPostCreate()
{	
	final rim = {brightness: -21, hue: -10, contrast: -28, saturation: -45};
	background.adjustGroupColor(background.opponents, rim);
	background.adjustGroupColor(background.spectators, rim);
	background.adjustGroupColor(background.players, rim);

	rainShader = new RainShader();

	// hmm, I think that since the erect stage seems to be like a weaker rain,
	// it makes sense to make the rain more thin, no?
	rainShader.scale = FlxG.height / 600;

	//TODO:
	//rainShader.rainColor = 0xFFa8adb5;

	rainFilter = new ShaderFilter(rainShader);
	game.camGAME.filters = [rainFilter];
}

function onPostUpdate(elapsed)
{
	final shaderDur = Reflect.field(rainIntensityMap, PlayState.songData.song) ?? [0.0, 0.01];

	if(game.playField.inCountdown || game.playField.inCutscene)	rainShader.intensity = shaderDur[0];
	else rainShader.intensity = FlxMath.remapToRange(game.conductor.time, 0, (game.playField.playback.inst[0] != null ? game.playField.playback.inst[0].length : 0), shaderDur[0], shaderDur[1]);
	//rainShader.intensity = 0.03;
	rainShader.updateViewInfo(FlxG.width, FlxG.height, game.camGAME);
	rainShader.update(elapsed);
}