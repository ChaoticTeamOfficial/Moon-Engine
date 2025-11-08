import flixel.FlxG;

final scale = 0.6;

//TODO: UPDATE
function createReceptor(direction)
{
    //trace("Hello there! From noteskin~", "DEBUG");

    final p = 'ingame/UI/notes/v-slice/'; // just the path so I dont need to do crazy copy pasting

    // <SETUP STRUMNOTE> //
    strumNote.frames = Paths.getSparrowAtlas(p + 'strumline');

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


    // <SETUP SPLASH> //
    splash.frames = Paths.getSparrowAtlas(p + 'splash');
	splash.playRandom = true;
    splash.animation.addByPrefix('splash0', direction + '10', 32, false);
    splash.animation.addByPrefix('splash1', direction + '20', 32, false);
    splash.scale.set(scale + 0.2, scale + 0.2);


    // <SETUP SUSTAIN SPLASH> //
    sustainSplash.frames = Paths.getSparrowAtlas(p + 'holdSplash');

    sustainSplash.animation.addByPrefix('pre', 'pre', 24, false);
    sustainSplash.animation.addByPrefix(direction + '-loop', direction + '-loop', 20, true);
    sustainSplash.animation.addByPrefix(direction + '-end', direction + '-end', 20, false);
    sustainSplash.playAnim(direction + '-end', true);
    sustainSplash.animation.onFinish.add(function(anim:String)
    {
        if(anim == direction + '-end') sustainSplash.visible = sustainSplash.active = false;
        else if (anim == 'pre') sustainSplash.playAnim(direction + '-loop', true);
    });
    
    // Blend Mode. 0 is ADD! you can reference all the blend modes from here: https://api.openfl.org/openfl/display/BlendMode.html
    splash.blend = 0;
    //sustainSplash.blend = 0;

    sustainSplash.antialiasing = splash.antialiasing = strumNote.antialiasing = true;
}

function createStaticNote(skin, direction)
{
    staticNote.frames = Paths.getSparrowAtlas('ingame/UI/notes/' + skin + '/staticArrows');

    staticNote.animation.addByPrefix(direction, direction + '0', 24, true);
    staticNote.animation.addByPrefix(direction + '-hold', direction + '-hold0', 24, true);
    staticNote.animation.addByPrefix(direction + '-holdEnd', direction +'-holdend0', 24, true);
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
function onNoteHit(playerID, note, timing, isSustain)
{
    if(playerID == 'p1' && timing == 'sick' && !isSustain)
    {
        splash.angle = FlxG.random.float(-360, 360);
    }
}