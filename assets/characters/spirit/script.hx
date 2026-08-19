import moon.dependency.MoonSprite;
import flixel.FlxG;
import Shortcuts;

var trail:MoonTrail;

function onPostCreate()
{
	trail = new MoonTrail(char, null, 32, 16, 0.9, 0.3);
	game.stage.opponents.insert(game.stage.opponents.members.indexOf(char), trail);

	final diff = 200;
	/*char.animation.onFrameChange.add((anim, idx, awawa) ->
	{
		trail.trailVelocity = switch (anim)
		{
			case 'idle-0':
				[0, 0];
			case 'singLEFT':
				[-diff, 0];
			case 'singDOWN':
				[0, diff];
			case 'singUP':
				[0, -diff];
			case 'singRIGHT':
				[diff, 0];
		};
	});*/
	trail.offsets = [0, 64];
	trail.overrideColor = 0xFFff0000;
	trail.overrideBlend = 0;
}