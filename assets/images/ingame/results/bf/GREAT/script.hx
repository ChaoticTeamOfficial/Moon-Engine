import flixel.FlxG;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;

var bf:FlxAnimate;
var gf:FlxAnimate;
function onPostCreate()
{
	gf = new FlxAnimate();
    gf.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/bf/GREAT/gf"));
    results.background.add(gf);
    gf.visible = gf.visible = false;
    gf.anim.addBySymbol("intro", "gf jumping", 24, false);
    gf.anim.onFinish.add(() -> gf.anim.play("intro", true, false, 9));

	bf = new FlxAnimate();
    bf.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/bf/GREAT/bf"));
    results.background.add(bf);
    bf.visible = gf.visible = false;
    bf.anim.addBySymbol("intro", "bf jumping ", 24, false);
    bf.anim.onFinish.add(() -> bf.anim.play("intro", true, false, 15));
	
	bf.antialiasing = gf.antialiasing = true;
	gf.scale.x = gf.scale.y = bf.scale.x = bf.scale.y = 0.93;
	
	FlxG.sound.playMusic(Paths.sound('results/bf/NORMAL.ogg', 'music'));
}

function onIntroEnd()
{
	gf.anim.play("intro", true);
	gf.setPosition(538, -131);
	
	bf.anim.play("intro", true);
	bf.setPosition(665, -232);
	bf.visible = gf.visible = true;
}