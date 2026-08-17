import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import moon.utils.MoonUtils;

final scale = 5;

// TODO: UPDATE

function createReceptor(direction)
{
	final p = 'notes/pixel/';
	spacing = 8;
	judgementsSkin = 'moon-pixel';

	// strum notes
	strumNote.frames = Paths.getSparrowAtlas(p + 'strumline');
	strumNote.animation.addByPrefix(direction + '-static', direction + '-static', 24, true);
	strumNote.animation.addByPrefix(direction + '-press', direction + '-press', 24, false);
	strumNote.animation.addByPrefix(direction + '-confirm', direction + '-confirm', 24, false);
	strumNote.playAnim(direction + '-static', true);

	strumNote.animation.onFinish.add(function(animation:String)
	{
		if (animation == direction + '-confirm' && strumNote.isCPU) strumNote.playAnim(direction + '-static');
	});
	strumNote.scale.set(scale, scale);

	// regular splash
	splash.frames = Paths.getSparrowAtlas(p + 'splash');
	splash.animation.addByPrefix('splash', direction + '0', 48, false);
	splash.animation.onFrameChange.add(_ -> splash.alpha = 0.8);
	splash.playRandom = false;
	splash.scale.set(scale, scale);
	splash.blend = 0;

	// sustain splash
	sustainSplash.frames = Paths.getSparrowAtlas(p + 'holdSplash');
	sustainSplash.animation.addByPrefix('pre', 'loop-' + direction + '0', 32, false);
	sustainSplash.animation.addByPrefix(direction + '-loop', 'loop-' + direction + '0', 32, true);
	sustainSplash.animation.addByPrefix(direction + '-end', 'explode-' + direction + '0', 40, false);
	sustainSplash.playAnim(direction + '-end', true);
	sustainSplash.animation.onFinish.add(function(anim:String)
	{
		if (anim == direction + '-end') sustainSplash.visible = sustainSplash.active = false;
		else if (anim == 'pre') sustainSplash.playAnim(direction + '-loop', true);
	});
	sustainSplash.scale.set(scale, scale);
	sustainSplash.updateHitbox();
	sustainSplash.extraOffset.y = 18;
	//sustainSplash.blend = 0;

	splash.antialiasing = strumNote.antialiasing = sustainSplash.antialiasing = false;
}

function createStaticNote(skin, direction)
{
	staticNote.frames = Paths.getSparrowAtlas('notes/pixel/staticNotes');

	staticNote.animation.addByPrefix(direction, direction + '0', 24, true);
	staticNote.animation.addByPrefix(direction + '-hold', direction + '-hold0', 24, true);
	staticNote.animation.addByPrefix(direction + '-holdEnd', direction + '-holdend0', 24, true);
	staticNote.antialiasing = false;
	staticNote.scale.set(scale, scale);
	staticNote.updateHitbox();
}

function onNoteHit(playerID, note, timing, isSustain)
{
}
