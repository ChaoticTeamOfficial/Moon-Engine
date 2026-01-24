import flixel.FlxG;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;

var fuckers:FlxAnimate;
function onPostCreate()
{	
	fuckers = new FlxAnimate();
    fuckers.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/bf/EXCELLENT/bfgf"));
    results.background.add(fuckers);

    fuckers.visible = false;
    fuckers.anim.addBySymbol("intro", "bf results excellent", 24, false);
    fuckers.anim.onFinish.add(() -> fuckers.anim.play("intro", true, false, 29));
	fuckers.antialiasing = true;

	FlxG.sound.playMusic(Paths.sound('results/bf/EXCELLENT-intro.ogg', 'music'), 1, false);	
	FlxG.sound.music.onComplete = () -> FlxG.sound.playMusic(Paths.sound('results/bf/EXCELLENT.ogg', 'music'));
}

function onIntroEnd()
{
	fuckers.visible = true;
	fuckers.anim.play("intro", true);
	//fuckers.screenCenter();
	fuckers.setPosition(540, -490);
}