import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;

function onPostCreate()
{	
	final rim = {brightness: -21, hue: -10, contrast: -28, saturation: -45};
	background.adjustGroupColor(background.opponents, rim);
	background.adjustGroupColor(background.spectators, rim);
	background.adjustGroupColor(background.players, rim);
}