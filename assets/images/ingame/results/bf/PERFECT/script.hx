import flixel.FlxG;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;

var fuckers:FlxAnimate;
function onPostCreate()
{
	fuckers = new FlxAnimate();
    fuckers.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/bf/PERFECT/bed"));
    results.background.add(fuckers);

    fuckers.visible = false;
    fuckers.anim.addBySymbol("intro", "boyfriend perfect rank", 24, false);
    fuckers.anim.onFinish.add(() -> fuckers.anim.play("intro", true, false, 120));
}

function onIntroEnd()
{
	FlxG.sound.playMusic(Paths.sound('results/bf/PERFECT.ogg', 'music'));
	fuckers.visible = true;
	fuckers.anim.play("intro", true);
	//fuckers.screenCenter();
	fuckers.setPosition(1385, 370);
}