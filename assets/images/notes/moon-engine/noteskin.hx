import flixel.FlxG;

final scale = 0.6;

function createReceptor(direction)
{
    judgementsSkin = 'moon-engine';

    // <SETUP STRUMNOTE> //
    strumNote.frames = Paths.getSparrowAtlas('notes/v-slice/strumline');

    strumNote.animation.addByPrefix(direction + '-static', direction + '-static', 24, true);
    strumNote.animation.addByPrefix(direction + '-press', direction + '-press', 24, false);
    strumNote.animation.addByPrefix(direction + '-confirm', direction + '-confirm', 24, false);

    strumNote.playAnim(direction + '-static', true);

    strumNote.animation.onFinish.add(function(animation:String)
    {
        if(animation == direction + '-confirm') strumNote.playAnim((!strumNote.isCPU) ? direction + '-press' : direction + '-static');
    });

    // Rescale the note cause its big af
    strumNote.scale.set(scale, scale);
	
	final sGraph = Paths.getSparrowAtlas('notes/moon-engine/moonEngineSplash');
	
    // <SETUP SPLASH> //
    splash.frames = sGraph;
    splash.animation.addByPrefix('splash', direction + '0', 32, false);
    splash.scale.set(scale + 0.4, scale + 0.4);
	splash.animation.onFinish.add(_ -> splash.angle = FlxG.random.float(-360, 360));
	splash.playRandom = false;

    // <SETUP SUSTAIN SPLASH> //
    sustainSplash.frames = sGraph;

    sustainSplash.animation.addByPrefix('pre', direction + '-loop', 24, false);
    sustainSplash.animation.addByPrefix(direction + '-loop', direction + '-loop', 20, true);
    sustainSplash.animation.addByPrefix(direction + '-end', direction + '-end', 20, false);
    sustainSplash.playAnim(direction + '-end', true);
    sustainSplash.animation.onFinish.add(function(anim:String)
    {
        if(anim == direction + '-end') sustainSplash.visible = sustainSplash.active = false;
        else if (anim == 'pre') sustainSplash.playAnim(direction + '-loop', true);
    });
	sustainSplash.scale.set(scale + 1, scale + 1);
	sustainSplash.updateHitbox();
    
    // Blend Mode. 0 is ADD! you can reference all the blend modes from here: https://api.openfl.org/openfl/display/BlendMode.html
    splash.blend = sustainSplash.blend = 0;

    sustainSplash.antialiasing = splash.antialiasing = strumNote.antialiasing = true;
}

function createStaticNote(skin, direction)
{
    staticNote.frames = Paths.getSparrowAtlas('notes/v-slice/staticArrows');

    staticNote.animation.addByPrefix(direction, direction + '0', 24, true);
    staticNote.animation.addByPrefix(direction + '-hold', direction + '-hold0', 24, true);
    staticNote.animation.addByPrefix(direction + '-holdEnd', direction +'-holdend0', 24, true);
    staticNote.antialiasing = true;
}

/**
 * This function is called whenever a note is hit.
 * @param playerID  The ID of the player. (can be either opponent, or p1)
 * @param note      The note that is being hit.
 * @param judgement The judgement got from hitting said note.
 * @param isSustain Whether or not its a sustain note.
 */
function onNoteHit(playerID, note, timing, isSustain)
{
    if(playerID == 'p1' && timing == 'sick' && !isSustain)
    {
        //splash.angle = FlxG.random.float(-360, 360);
    }
}