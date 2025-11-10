package moon.backend.gameplay;

import flixel.math.FlxMath;
import moon.game.obj.Character;
import moon.game.obj.notes.Note.NoteState;
import moon.game.obj.notes.*;
import moon.backend.gameplay.Timings;

/**
 * Class meant to handle note inputs in a gameplay scene.
 **/
class InputHandler
{
    /**
     * Playerstats used in here.
     * TODO: make a better description for this ;V
     */
    public var stats:PlayerStats;

    /**
     * The player ID, used for many things, but mainly note reading.
     */
    public var playerID:String;
	
	/**
	 * Wheter is a CPU or not, used for checking inputs.
	 */
	public var CPUMode:Bool = false;

    /**
     * The strumline, used for triggering animations and maybe more.
     */
    public var strumline:Strumline;

    /**
     * The conductor class, used for many things among with note timings.
     */
    public var conductor:Conductor;

    /**
     * Map for the sustain notes.
     */
    public var heldSustains:Map<Int, Note> = new Map<Int, Note>();

    /**
     * Array for the notes in this class, needed for reading their timings and such.
     */
    public var thisNotes:Array<Note> = [];

    /**
     * Function called whenever a note gets hit (Good Hit.)
     */
    public var onNoteHit:(Note, String, Bool)->Void;

    /**
     * Function called whenever a note is missed (Bad Hit.)
     */
    public var onNoteMiss:Note->Void;
    
    /**
     * Function called whenever a key is pressed (if ghost tapping is off, it'll call onNoteMiss right after.)
     */
    public var onGhostTap:Int->Void;

    /**
     * Function called whenever a key is released.
     */
    public var onKeyRelease:Int->Void;

    /**
     * Function called whenever a sustain gets completed (held till the end.)
     */
    public var onSustainComplete:Note->Void;

    /**
     * An character to be attached, useful for playing animations.
     */
    public var attachedChar:Character;

    /**
     * Array for all the the keys on the 'justPressed' state.
     */
    public var justPressed:Array<Bool> = [];

    /**
     * Array for all the the keys on the 'pressed' state.
     */
    public var pressed:Array<Bool> = [];

    /**
     * Array for all the the keys on the 'released' state.
     */
    public var released:Array<Bool> = [];

    /**
     * Creates input handler instance, all this does is handling inputs for a player you choose.
     * @param thisNotes The notes array that it will read.
     * @param playerID  The ID for the player. currently supported are [`opponent, p1`]
     * @param strumline The strumline, used for triggering animations on it.
     * @param conductor The conductor instance, used for many things.
     */
    public function new(thisNotes:Array<Note>, playerID:String, strumline:Strumline, conductor:Conductor)
    {
        this.thisNotes = thisNotes;
        this.playerID = playerID;
        this.strumline = strumline;
        this.conductor = conductor;
        this.stats = new PlayerStats(playerID);
    }

    public function update():Void
    {
        if(!CPUMode)
            processInputs();
        else
            processCPUInputs();

        checkSustains();
        onLateMiss();

        stats.health = FlxMath.bound(stats.health, 0, 101);
    }

    private function processCPUInputs():Void
    {
        for (i in 0...4)
        {
            // get the possible notes thats in the... perfect timing
            final possibleNotes = thisNotes.filter(note ->
            return (note.direction == i &&
                note.lane == playerID &&
                note.time - conductor.time <= 0 &&
                note.state == NONE)
            );

            // sort them bc why not :P
            //possibleNotes.sort((a, b) -> Std.int(a.time - b.time));
            // we dont need sorting for cpu dumbass

            // then call onhit
            if (possibleNotes.length > 0)
                onHit(possibleNotes[0], i, 'sick', true);
        }
    }

    private function processInputs():Void
    {
        // now, since this is for player's inputs and needs to have timing, it'll be a lil more complex.
        for (i in 0...justPressed.length)
        {
            // iterates through the keys and checks if any of them got pressed.
            if (justPressed[i])
            {
                // now filter through the possible notes to hit, matching its current time to the next available judgement
                final possibleNotes = thisNotes.filter(note ->
                return (note.direction == i &&
                    note.lane == playerID &&
                    isWithinTiming(note) &&
                    note.state == NONE)
                );

                // then sort through notes or else timings will act weird-ish
                possibleNotes.sort((a, b) -> Std.int(a.time - b.time));

                if (possibleNotes.length > 0)
                {
                    // and then finally call on hit for the notes
                    final note = possibleNotes[0];
                    final timing = checkTiming(note);

                    if (timing != null)
                    {
                        onHit(note, i, timing, false);
                        stats.totalNotes++;
                        stats.accuracyCount += Timings.getParameters(timing)[0];
                    }
                }
                else // and this is called when you ghost tap.
                {
                    if(onGhostTap != null) onGhostTap(i);

                    strumline.members[i].strumNote.playAnim('${MoonUtils.intToDir(i)}-press', true);
                    if(!MoonSettings.callSetting('Ghost Tapping')){
                        if(attachedChar != null) 
                        {
                            attachedChar.playAnim('sing${MoonUtils.intToDir(i).toUpperCase()}-miss', true);
                            attachedChar.animationHold = 0;
                        }
                        onMiss(null);
                    }
                }
            }
        }

        // iterate through every released key
        for (i in 0...released.length)
        {
            if(released[i])
            {
                // call on release if a released key is detected (like that one vs hex song yes its defnitely a reference hahaha laugh now.)
                if (onKeyRelease != null) onKeyRelease(i);
                strumline.members[i].strumNote.playAnim('${MoonUtils.intToDir(i)}-static', true);

                // now all this does is check if a key got released early while holding a sustain
                // then 'kill' it (not necessarily kill. we dont kill notes around here...)
                // shh emoji
                if (heldSustains.exists(i))
                {
                    strumline.members[i].sustainSplash.despawn(true);
                    final heldNote = heldSustains.get(i);
                    heldSustains.remove(i);

                    if (heldNote != null && heldNote.state == GOT_HIT && heldNote.child != null)
                        heldNote.child.visible = heldNote.child.active = false;
                }
            }
        }
    }

    private function onHit(note:Note, ID:Int, timing:String, isCPU:Bool, ?isSustain:Bool = false):Void
    {
        final convertedDir = MoonUtils.intToDir(note.direction);
        
        if(!isSustain)
        {
            note.state = GOT_HIT;
            note.visible = note.active = false;
            stats.judgementsCounter.set(timing, stats.judgementsCounter.get(timing) + 1);
            stats.noSustainCombo++;
            //trace(stats.judgementsCounter, "DEBUG");
            if (note.duration > 0) {
                heldSustains.set(ID, note);
                lastSustainStep.set(ID, conductor.curStep);
            }
        }
        
        stats.health += (!isSustain) ? Timings.getParameters(timing)[3] : 0.5;
        stats.score += (!isSustain) ? Timings.getParameters(timing)[2] : 2;
        stats.combo++;
        strumline.members[note.direction].onNoteHit(note, timing, isSustain);
        stats.updtAccuracy();
        
        // little workaround if it doesnt despawn, which may happen sometimes...
        if(!isSustain) strumline.members[note.direction].sustainSplash.despawn((CPUMode));
        
        if(attachedChar != null) 
        {
            attachedChar.playAnim('sing${convertedDir.toUpperCase()}', true);
            attachedChar.animationHold = 0;
        }

        (timing != 'miss' && onNoteHit != null) ? onNoteHit(note, timing, isSustain) : (timing == 'miss') ? onMiss(note) : null;
    }

    public function onMiss(note:Note):Void
    {
        if(note != null)
        {
            note.state = TOO_LATE;
            note.visible = note.active = false;

            if(attachedChar != null) 
            {
                attachedChar.playAnim('sing${MoonUtils.intToDir(note.direction).toUpperCase()}-miss', true);
                attachedChar.animationHold = 0;
            }
        }
        
        stats.accuracyCount += Timings.getParameters('miss')[0];
        stats.score += Timings.getParameters('miss')[2];
        stats.health += Timings.getParameters('miss')[3];
        stats.misses++;
        stats.combo = 0;
        stats.noSustainCombo = 0;
        stats.updtAccuracy();
        
        if(onNoteMiss != null) onNoteMiss(note);
    }

    // Map for tracking the last conductor step a sustain note was hit on.
     private var lastSustainStep:Map<Int, Float> = new Map<Int, Float>();
    private function checkSustains():Void
    {
        for (direction in heldSustains.keys())
        {
            final heldNote = heldSustains.get(direction);
            // on hold note hit
            if (heldNote != null && heldNote.state == GOT_HIT && heldNote.child != null && heldNote.child.active)
            {
                if (lastSustainStep.exists(direction) && conductor.curStep > lastSustainStep.get(direction))
                {
                    onHit(heldNote, direction, null, (CPUMode), true);
                    lastSustainStep.set(direction, conductor.curStep);
                    stats.score += 2;
                }

                if (conductor.time >= heldNote.time + heldNote.duration)
                {
                    heldNote.child.visible = heldNote.child.active = false;
                    heldSustains.remove(direction);
                    lastSustainStep.remove(direction);
                }
            }
            // on sustain note complete, basically, when you hold it till the end.
            else
            {
                heldSustains.remove(direction);
                strumline.members[heldNote.direction].sustainSplash.despawn((CPUMode));
                if(onSustainComplete != null) onSustainComplete(heldNote);
            }
        }
    }

    private function onLateMiss():Void
        // iterates through all notes and checks if they're too late.
        for (note in thisNotes)
            if (note.state != GOT_HIT && note.state != NoteState.TOO_LATE && note.lane == playerID &&
                conductor.time > note.time + Timings.getParameters('miss')[1])
                onMiss(note);

    /**
     * Checks if the note is within timing,
     * @param note 
     * @return Bool
        return checkTiming(note) != null
     */
    private function isWithinTiming(note:Note):Bool
        return checkTiming(note) != null;

    /**
     * Checks the timing for a note, then it'll return its appropriate judgement.
     * @param note 
     * @return String
     */
    private function checkTiming(note:Note):String
    {
        final timeDifference = Math.abs(note.time - conductor.time);
        for (jt in Timings.values)
            if (timeDifference <= Timings.getParameters(jt)[1])
                return jt;

        return null;
    }
}
