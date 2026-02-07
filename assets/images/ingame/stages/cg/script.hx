import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;

function onCreate()
{

}

function onPostCreate()
{	
	for(character in [background.players.members[0], background.opponents.members[0], background.spectators.members[0]])
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFff6b6b;
		character.shader = rim;
		rim.attachedSprite = character;
		rim.angle = 90;

		character.animation.onFrameChange.add(() -> rim.updateFrameInfo(character.frame));
	}
}