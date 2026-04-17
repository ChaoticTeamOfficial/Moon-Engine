import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;
import moon.game.PlayState;

var rainShader:RainShader;

// I don't want to do a switch cause I'm a bitch
// so! put the song ID on the left, then, the array's
// first value is the intensity on the song start, and the last is
// on the song end, it'll smoothly go from the first value to the second one throughout the song.

// I really don't like how... weak the rain is on the erect stage.
// because... to me at least, I think it doesn't make sense!
// the sky's all gray and everythin...
final rainIntensityMap = {
	'darnell': [0, 0.01],
	'lit-up': [0.01, 0.02],
	'2-hot': [0.02, 0.04]
};

function onPostCreate()
{	
	final rim = {brightness: -21, hue: -10, contrast: -28, saturation: -45};
	background.adjustGroupColor(background.opponents, rim);
	background.adjustGroupColor(background.spectators, rim);
	background.adjustGroupColor(background.players, rim);

	rainShader = new RainShader();
	rainShader.scale = FlxG.height / 200;
	//TODO: figure out why tf changing the intensity doesn't work.
	rainShader.intensity = 0.0;
	game.camGAME.filters = [new ShaderFilter(rainShader)];
}

function onPostUpdate(elapsed)
{
	final shaderDur = Reflect.field(rainIntensityMap, PlayState.songData.song) ?? [0.0, 0.01];
	rainShader.intensity = FlxMath.remapToRange(game.conductor.time, 0, (game.playField.playback.inst[0] != null ? game.playField.playback.inst[0].length : 0), shaderDur[0], shaderDur[1]);
	rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
	rainShader.update(elapsed);
}