import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;

function onPostCreate()
{
	background.adjustGroupColor(background.opponents, {
		brightness: -33,
		hue: -32,
		contrast: -23,
		saturation: 0
	});
	
	background.adjustGroupColor(background.spectators, {
		brightness: -30,
		hue: -9,
		contrast: -4,
		saturation: 0
	});
	
	background.adjustGroupColor(background.players, {
		brightness: -23,
		hue: 12,
		contrast: 7,
		saturation: 0
	});

	//for (character in background.players.members) addShader(character, -23, 12, 7, 0, 0xFFffe346, 50);

	//for (character in background.spectators.members) addShader(character, -30, -9, -4, 0, 0xFFc8b023, 0);
}
