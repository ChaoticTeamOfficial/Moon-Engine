import flixel.FlxG;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import moon.dependency.MoonSprite;

var fuckers:MoonSprite;

function onPostCreate()
{
	fuckers = new MoonSprite();
	fuckers.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/bf/LOSS/bfgf"));
	results.background.add(fuckers);

	fuckers.visible = false;
	fuckers.anim.addBySymbol("intro", "LOSS Animation", 24, false);
	fuckers.anim.onFinish.add(() -> fuckers.anim.play("intro", true, false, 160));

	FlxG.sound.playMusic(Paths.sound('results/bf/LOSS-intro.ogg', 'music'), 1, false);
	fuckers.antialiasing = true;

	FlxG.sound.music.onComplete = () ->
	{
		FlxG.sound.playMusic(Paths.sound('results/bf/LOSS.ogg', 'music'));
	}
}

function onIntroEnd()
{
	fuckers.visible = true;
	fuckers.anim.play("intro", true);
	// fuckers.screenCenter();
	fuckers.setPosition(600, -386);
}
