import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

var lumoraTrail:MoonTrail;
function onPostCreate()
{
	final specs = game.stage.spectators;
	char.y -= 64;
	FlxTween.tween(char, {y: char.y + 164}, 2, {ease: FlxEase.quadInOut, type: 4});
	
	lumoraTrail = new MoonTrail(char, null, 32, 10, 0.7, 0.13);
	specs.insert(specs.members.indexOf(char) + 1, lumoraTrail);
	lumoraTrail.trailVelocity = [-240, 0];
}

function onUpdate(elapsed)
{
	for(wah in lumoraTrail.members)
		wah.blend = 0;
}