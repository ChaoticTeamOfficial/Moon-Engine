import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;

function onPostCreate()
{	
	for(character in background.opponents.members)
		addShader(character);
		
	for(character in background.players.members)
		addShader(character);
	
	for(character in background.spectators.members)
		addShader(character);
}

function addShader(character:MoonSprite)
{
	if(character==null) return;
	
	if(Std.isOfType(character, MoonSprite))
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