import flixel.FlxG;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import moon.dependency.MoonSprite;

var bf:MoonSprite;
var gf:MoonSprite;

function onPostCreate()
{
	gf = new MoonSprite();
	gf.frames = Paths.getSparrowAtlas('ingame/results/bf/GOOD/resultGirlfriendGOOD');
	gf.animation.addByPrefix('appear', 'Girlfriend Good Anim', 24, false);
	gf.animation.onFinish.add((anim) ->
	{
		gf.playAnim('appear');
		gf.animation.curAnim.curFrame = 9;
	});
	results.background.add(gf);

	bf = new MoonSprite();
	bf.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/bf/GOOD/bf"));
	results.background.add(bf);

	bf.anim.addBySymbol("intro", "Boyfriend Good Anim", 24, false);
	bf.anim.onFinish.add(() -> bf.anim.play("intro", true, false, 14));

	bf.visible = gf.visible = false;
	bf.antialiasing = gf.antialiasing = true;

	FlxG.sound.playMusic(Paths.sound('results/bf/NORMAL.ogg', 'music'));
}

function onIntroEnd()
{
	gf.playAnim("appear", true);
	gf.setPosition(616, 296);

	bf.anim.play("intro", true);
	bf.setPosition(662, -200);
	bf.visible = gf.visible = true;
}
