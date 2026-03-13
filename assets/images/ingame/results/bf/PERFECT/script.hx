import flixel.FlxG;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import moon.dependency.MoonSprite;

var fuckers:MoonSprite;
function onPostCreate()
{
	fuckers = new MoonSprite();
    fuckers.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/bf/PERFECT/bed"));
    results.background.add(fuckers);

	//TODO: FIX THIS SCREEN...
    fuckers.visible = false;
    fuckers.anim.addBySymbol("intro", "boyfriend perfect rank", 24, false);
    fuckers.anim.onFinish.add(() -> fuckers.anim.play("intro", true, false, 69));
	fuckers.antialiasing = true;
}

function onIntroEnd()
{
	FlxG.sound.playMusic(Paths.sound('results/bf/PERFECT.ogg', 'music'));
	fuckers.visible = true;
	fuckers.anim.play("intro", true);
	//fuckers.screenCenter();
	fuckers.setPosition(500, -300);
}