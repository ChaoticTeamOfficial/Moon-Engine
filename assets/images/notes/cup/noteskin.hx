import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

final scale = 0.6;

final p = 'notes/cup/';
function createReceptor(direction)
{
    //trace("Hello there! From noteskin~", "DEBUG");

    //judgementsSkin = 'moon-engine';
	final s = Paths.getSparrowAtlas(p + 'NOTE_cup');

    // <SETUP STRUMNOTE> //
    strumNote.frames = s;

    strumNote.animation.addByPrefix(direction + '-static', 'arrow' + direction.toUpperCase(), 24, true);
    strumNote.animation.addByPrefix(direction + '-press', direction + ' press instance 1', 24, false);
    strumNote.animation.addByPrefix(direction + '-confirm', direction + ' confirm instance 1', 24, false);

    strumNote.playAnim(direction + '-static', true);

    strumNote.animation.onFinish.add(function(animation:String)
    {
        if(animation == direction + '-confirm') strumNote.playAnim((!strumNote.isCPU) ? direction + '-press' : direction + '-static');
    });

    // Rescale the note cause its big af
    strumNote.scale.set(scale, scale);

    // <SETUP SPLASH> //
    splash.frames = Paths.getSparrowAtlas(p + 'AllnoteSplashes');
	splash.playRandom = false;
    splash.animation.addByPrefix('splash', direction + ' instance 10', 34, false);
    splash.scale.set(scale + 0.2, scale + 0.2);

    // Blend Mode. 0 is ADD! you can reference all the blend modes from here: https://api.openfl.org/openfl/display/BlendMode.html
    splash.blend = sustainSplash.blend = 0;
	
	sustainSplash.frames = Paths.getSparrowAtlas('ingame/UI/notes/v-slice/holdSplash');

    sustainSplash.animation.addByPrefix('pre', 'pre', 24, false);
    sustainSplash.animation.addByPrefix(direction + '-loop', direction + '-loop', 20, true);
    sustainSplash.animation.addByPrefix(direction + '-end', direction + '-end', 20, false);
    sustainSplash.playAnim(direction + '-end', true);
    sustainSplash.animation.onFinish.add(function(anim:String)
    {
        if(anim == direction + '-end') sustainSplash.visible = sustainSplash.active = false;
        else if (anim == 'pre') sustainSplash.playAnim(direction + '-loop', true);
    });

    splash.antialiasing = strumNote.antialiasing = true;

    sustainSplash.antialiasing = splash.antialiasing = strumNote.antialiasing = true;
}

function createStaticNote(skin, direction)
{
    staticNote.frames = Paths.getSparrowAtlas(p + 'NOTE_cup');
	final dir = direction.toUpperCase();

    staticNote.animation.addByPrefix(direction, dir + ' alone0', 24, true);
    staticNote.animation.addByPrefix(direction + '-hold', dir + ' hold0', 24, true);
    staticNote.animation.addByPrefix(direction + '-holdEnd', dir +' tail0', 24, true);
    staticNote.scale.set(scale, scale);
    staticNote.antialiasing = true;
}

/**
 * This function is called whenever a note is hit.
 * @param playerID  The ID of the player. (can be either opponent, or p1)
 * @param note      The note that is being hit.
 * @param judgement The judgement got from hitting said note.
 * @param isSustain Whether or not its a sustain note.
 */
 var tT:FlxTween;
function onNoteHit(playerID, note, timing, isSustain)
{

}