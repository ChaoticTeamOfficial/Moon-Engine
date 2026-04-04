import moon.dependency.MoonSprite;
import flixel.FlxG;
import Shortcuts;

var asmileTrail:MoonTrail;
function onPostCreate()
{
	final specs = game.stage.opponents;
	
	asmileTrail = new MoonTrail(char, null, 32, 8, 0.8, 0.12);
	specs.insert(specs.members.indexOf(char), asmileTrail);
	asmileTrail.trailVelocity = [0, 0];
}

function onUpdate(elapsed)
{
	for(wah in asmileTrail.members)
		wah.blend = 0;
		
	asmileTrail.trailVelocity = [FlxG.random.float(-164, 164), FlxG.random.float(-196, 64)];
}

function onNoteHit(playerID, note, timing, isSustain)
{
    if(playerID == 'opponent')
    {
        //char.x = 64 + FlxG.random.int(-100, 100);
		//char.y = 456 + FlxG.random.int(-200, 30);
    }
}