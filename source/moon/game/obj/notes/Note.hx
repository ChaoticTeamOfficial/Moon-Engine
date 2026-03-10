package moon.game.obj.notes;

import moon.dependency.scripting.MoonScript;
import openfl.filters.ColorMatrixFilter;

/**
 * The state of a note in the game.
 */
enum NoteState 
{
    /**
     * Means that the note won't be updated in any way.
     */
    CHART_EDITOR;

    /**
     * When a note is hit.
     */
    GOT_HIT;

    /**
     * When a note is too late.
     */
    TOO_LATE;

    /**
     * When a note is missed.
     */
    MISSED;

    /**
     * None state.
     */
    NONE;
}

class Note extends MoonSprite
{
    /**
     * Defines the note state.
     * E.G; `MISSED, GOT_HIT, TOO_LATE` etc.
     */
    public var state:NoteState = NONE;

    /**
     * The note's direction.
     */
    public var direction:Int = 0;

    /**
     * The note's time in miliseconds.
     */
    public var time:Float = 0;

    /**
     * The note's speed, used for sustain length calculations.
     */
    public var speed:Float = 1;

    /**
     * The note's type.
     */
    public var type:String = 'default';

    /**
     * The note's skin, usually based on how it's on settings.
     */
    public var skin(default, set):String = 'default';

    /**
     * The note's sustain duration.
     */
    public var duration:Float = 0;

    /**
     * The note's strumline, in which it's attached to
     */
    public var lane:String = 'P1';

    /**
     * The receptor in which the note will go to.
     */
    public var receptor(default, set):Receptor;

    /**
     * This note's sustain.
     */
    public var child:NoteSustain;
 
    public var conductor:Conductor;
    public var script:MoonScript;

    /**
     * Brightness adjustment for feedback in editor
     */
    public var brightness(default, set):Float = 0;

    private static var sharedScripts:Map<String, MoonScript> = new Map();

    public function new(direction:Int, time:Float, ?type:String = "default", ?skinName:String = "v-slice", 
        duration:Float = 0, conductor:Conductor = null)
    {
        super();
        this.direction = direction;
        this.time = time;
        this.type = type;
        this.duration = duration;
        this.conductor = conductor;
        centerAnimations = true;
        
        this.skin = skinName;
    }

    private function _updateGraphics():Void
    {
        var curSkin = ((type != "default" || type != null) && Paths.exists('images/ingame/UI/notes/$type')) ? type : skin;
        var dir = MoonUtils.intToDir(direction);

        if (!sharedScripts.exists(curSkin))
        {
            var wawa = new MoonScript();
            wawa.load('images/notes/$curSkin/noteskin.hx');
            sharedScripts.set(curSkin, wawa);

            if(!Global.scripts.exists(curSkin)) Global.registerScript(curSkin, wawa);
        }

        script = sharedScripts.get(curSkin);
        script.set("staticNote", this);
        script.get("createStaticNote")(curSkin, dir);
        updateHitbox();
        playAnim(dir);
    }

    @:noCompletion public function set_skin(skinName:String):String
    {
        this.skin = skinName;
        _updateGraphics();
        return skinName;
    }

    @:noCompletion public function set_brightness(value:Float):Float
    {
        this.brightness = value;
        
        FlxSpriteUtil.setBrightness(this, value);
        
        return value;
    }

    override public function update(dt:Float):Void
    {
        super.update(dt);
        if(state == GOT_HIT || state == MISSED || state == TOO_LATE)
            visible = active = false;

        if (receptor != null && state == NONE)
            scale.copyFrom(receptor.strumNote.scale);

        updateNotePos();
    }

    public function updateNotePos()
    {
        if (receptor != null && state == NoteState.NONE)
        {
            visible = active = true;

            final timeDiff = (time - conductor.time);
            var ypos = receptor.y + timeDiff * speed;

            if (MoonSettings.callSetting('Downscroll')) ypos = receptor.y - timeDiff * speed;

            y = ypos;
            x = receptor.x + (receptor.width - width) * 0.5;

            if (child != null) child.downscroll = MoonSettings.callSetting('Downscroll');
        }
    }

    function set_receptor(receptor:Receptor):Receptor
    {
        this.receptor = receptor;
        scale.set(receptor.strumNote.scale.x, receptor.strumNote.scale.y);
        updateHitbox();

        if(child!=null)child.updateOther();
        return this.receptor;
    }

    // Editor stuffies
    public var sustainHandle:MoonSprite;

    public function makeHandle():Void
    {
        if (sustainHandle != null) return;

        sustainHandle = new MoonSprite();
        sustainHandle.frames = Tilemap.getAtlasFrames("mainUI");
        sustainHandle.frame = Tilemap.getFrame('sustainHandle', 'mainUI');
        //sustainHandle.centerOffsets();
        //sustainHandle.centerOrigin();
        sustainHandle.antialiasing = false;
        sustainHandle.blend = ADD;
        sustainHandle.active = false;
        sustainHandle.alpha = 0.28;

        // gotta set width shit manually cause weirdo hitboxes
        sustainHandle.width = 32;
        sustainHandle.height = 16;
    }

    public function updateHandle():Void
    {
        if (sustainHandle == null) return;

        final endY = (child != null) ? child.y + child.height : (y + height);

        sustainHandle.x = x + (width - sustainHandle.width) * 0.5;
        sustainHandle.y = endY - sustainHandle.height * 0.5;
    }

    override function destroy():Void
    {
        if (sustainHandle != null)
        {
            sustainHandle.destroy();
            sustainHandle = null;
        }

        child = null;
        super.destroy();
    }
}