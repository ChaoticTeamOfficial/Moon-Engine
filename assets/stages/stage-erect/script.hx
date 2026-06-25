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

	for (character in background.players.members) addShader(character, -23, 12, 7, 0, 0xFFffe346, 50);

	for (character in background.spectators.members) addShader(character, -30, -9, -4, 0, 0xFFc8b023, 0);
}

function addShader(character:MoonSprite, brightness:Float, hue:Float, contrast:Float, saturation:Float, color:FlxColor, angle:Float)
{
	if (character == null) return;

	if (Std.isOfType(character, MoonSprite))
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(brightness, hue, contrast, saturation);

		rim.color = color;
		character.shader = rim;
		rim.attachedSprite = character;
		rim.angle = angle;

		character.animation.onFrameChange.add(() -> rim.updateFrameInfo(character.frame));
	}
}
