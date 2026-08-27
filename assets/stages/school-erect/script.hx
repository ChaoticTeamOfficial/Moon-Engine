import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;
import moon.game.obj.Character;

function onPostCreate()
{
	for (character in background.players.members) addShader(character);
	for (character in background.spectators.members) addShader(character);
	for (character in background.opponents.members) addShader(character);
}

function addShader(character:MoonSprite)
{
	if (character == null) return;

	if (Std.isOfType(character, Character))
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-66, -10, 24, -23);
		rim.color = 0xFF52351d;
		rim.antialiasAmt = 0;
		rim.distance = 5;
		character.shader = rim;
		rim.attachedSprite = character;
		rim.angle = 90;
		
		switch(character.character)
		{
			case 'senpai-angry', 'senpai':
				rim.altMaskImage = Paths.image('school-erect/masks/senpai_mask.png', 'stages').bitmap;
			default: 
				final maskPath = 'school-erect/masks/' + character.character + '_mask.png';
				if(Paths.exists('stages' + maskPath))
					rim.altMaskImage = Paths.image(maskPath, 'stages').bitmap;
		}

		character.animation.onFrameChange.add(() -> rim.updateFrameInfo(character.frame));
	}
}
