import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import lime.app.Future;
import moon.dependency.MoonSound;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;

var cartoonPlayer:MoonSound;

function onCreate()
{
	// dj setup
	dj.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/menus/freeplay/bf/freeplay-bf"));

	// Main Anims
	dj.animation.addBySymbol("intro", "boyfriend dj intro", 24, false);
	dj.animation.addBySymbol("idle", "bf chilling", 24, false);
	dj.addOffset('idle', -5, -426);
	dj.animation.addBySymbol("newChar", "Boyfriend DJ new character", 24, true);
	dj.animation.addBySymbol("confirm", "Boyfriend DJ confirm", 24, false);
	dj.addOffset('confirm', 44, -426);
	dj.animation.addBySymbol("leave", "Boyfriend DJ to CS", 24, false);
	dj.addOffset('leave', 55, -346);

	// Rank Anims
	dj.animation.addBySymbol("rankWin", "Boyfriend DJ fist pump", 24, false);
	dj.addOffset('rankWin', -5, -415);
	dj.animation.addBySymbol("rankLoss", "Boyfriend DJ loss reaction 1", 24, false);
	dj.addOffset('rankLoss', -5.5, -413);

	// Extra
	dj.animation.addBySymbol("afk1", "bf dj afk", 24, false);
	dj.addOffset('afk1', -5, -263);
	dj.animation.addBySymbol("afk2", "Boyfriend DJ watchin tv OG", 24, false);
	dj.addOffset('afk2', 15, 30.5);
	dj.canDance = false;

	// dj.centerAnimations = true;
	dj.playAnim("intro", true);

	// now we setup some onFinish stuff
	dj.animation.onFinish.add(anim ->
	{
		switch (anim)
		{
			case 'rankWin', 'rankLoss', 'afk1', 'intro':
				dj.canDance = true;
			case 'afk2':
				chooseNextDJAction();
		}
	});

	// pos setup and more
	dj.screenCenter();
	dj.antialiasing = true;
	dj.x -= 232;
	dj.y += 32;

	// cartoon sound setup
	cartoonPlayer = new MoonSound();
}

var afkIndex = 0;

function onUpdate(elapsed)
{
	// if(FlxG.keys.justPressed.E) dj.AFK_TIMER += 30;
	// if(FlxG.keys.justPressed.P) dj.playAnim('rankLoss', true);
	switch (afkIndex)
	{
		case 0:
			if (dj.AFK_TIMER >= 60)
			{
				dj.canDance = false;
				dj.playAnim("afk1", true);
				afkIndex += 1;
				dj.AFK_TIMER = 0;
			}
		case 1:
			if (dj.AFK_TIMER >= 100)
			{
				FlxTween.tween(freeplay, {
					songVolume: 0.08
				}, 2.2, {
					startDelay: 2.2
				});
				dj.canDance = false;
				dj.playAnim("afk2", true);
				afkIndex += 1;
				dj.AFK_TIMER = 0;

				new FlxTimer().start(3.5, function(_)
				{
					FlxG.sound.play(Paths.sound('menus/freeplay/tv_on.ogg', 'sounds'));
					new FlxTimer().start(0.3, (_) -> playRandomCartoon());
				});
			}
	}
}

function chooseNextDJAction()
{
	if (FlxG.random.bool(16)) // change channel
	{
		dj.playAnim("afk2", true, false, 55);
		new FlxTimer().start(1, function(_)
		{
			FlxG.sound.play(Paths.sound('menus/freeplay/channel_switch.ogg', 'sounds'));
			new FlxTimer().start(0.3, (_) -> playRandomCartoon());
		});
	}
	else // keep watching the same channel
		dj.playAnim("afk2", true, false, 112);
}

function playRandomCartoon()
{
	if (cartoonPlayer != null)
	{
		FlxG.sound.list.remove(cartoonPlayer);
		cartoonPlayer.stop();
		cartoonPlayer.destroy();
	}

	cartoonPlayer.loadEmbedded(Paths.sound('menus/freeplay/cartoons/cartoon' + FlxG.random.int(1, 24) + '.ogg', 'sounds'));
	cartoonPlayer.play();
	cartoonPlayer.volume = 1;
	FlxG.sound.list.add(cartoonPlayer);
}
