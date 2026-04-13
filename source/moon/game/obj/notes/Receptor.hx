package moon.game.obj.notes;

import flixel.group.FlxGroup.FlxTypedGroup;
import moon.dependency.scripting.MoonScript;
import flixel.group.FlxSpriteGroup;

/**
 * A receptor on your desired position with skin and other data.
 */
class Receptor extends FlxSpriteGroup
{
    /**
     * Backing storage for the skin; do not access directly.
     */
    private var _skin:String;

    /**
     * Skin used for the receptor; changing this at runtime will rebuild the receptor.
     */
    public var skin(get, set):String;

    /**
     * The direction data (e.g. 0, 1, 2, 3...)
     */
    public var data:Int = 0;

    /**
     * Whether is a CPU or not.
     */
    public var isCPU:Bool = false;

    /**
     * The player ID for this. can be opponent, p1, etc...
     */
    public var playerID:String;

    /**
     * The skin for the judgements. Here so they can be defined per noteskin.
     */
    public var judgementsSkin:String = 'moon-engine';
	
	/**
	 * The X Spacing between each note.
	 */
	public var spacing:Float = 0;

    /**
     * The conductor for this class.
     */
    public var conductor:Conductor;

    /**
     * The strum note.
     */
    public var strumNote:StrumNote;

    /**
     * The note splash.
     */
    public var splash:RegularSplash;

    /**
     * The sustain note splash (when holding one.)
     */
    public var sustainSplash:SustainSplash;

    /**
     * Script for the noteskins.
     */
    public var script:MoonScript;
    
    /**
     * Group for the notes on this receptor.
     */
    public var notesGroup:FlxTypedSpriteGroup<MoonSprite> = new FlxTypedSpriteGroup<MoonSprite>();

    /**
     * Group for the sustain pieces on this receptor.
     */
    public var sustainsGroup:FlxTypedSpriteGroup<NoteSustain> = new FlxTypedSpriteGroup<NoteSustain>();

    /**
     * Group for the splashes on this receptor.
     */
    public var splashGroup:FlxTypedSpriteGroup<MoonSprite> = new FlxTypedSpriteGroup<MoonSprite>();

    /**
     * Creates a receptor at (x,y) with the given initial skin, data, CPU flag, etc.
     */
    public function new(x:Float, y:Float, ?skin:String = 'v-slice', data:Int, ?isCPU:Bool = false, playerID:String, conductor:Conductor)
    {
        super(x, y);

        // I just realized that this is prob the only placed I did this separation bullshit LOL
        this.data      = data;
        this.isCPU     = isCPU;
        this.playerID  = playerID;
        this.conductor = conductor;

        // ensure our sub-groups are children
        add(notesGroup);
        add(sustainsGroup);
        add(splashGroup);

        // load the initial skin (this will call _updtGraphics)
        set_skin(skin);
    }

    @:noCompletion private function get_skin():String
        return _skin;

    @:noCompletion private function set_skin(value:String):String
    {
        if (value == _skin) return _skin;
        _skin = value;

        // load the new noteskin script
        script = new MoonScript();
        Global.registerScript('receptor-$playerID-$data', script);
        script.load('images/notes/$value/noteskin.hx');
        script.set("this", this);

        // clear any old visuals
        clear();
        notesGroup.clear();
        sustainsGroup.clear();
        splashGroup.clear();

        // rebuild everything
        _updtGraphics();
        return _skin;
    }

    /**
     * (Re)creates the strum arrow, splash animations, etc.
     */
    private function _updtGraphics():Void
    {
        // -- Create Strum Arrow -- //
        strumNote = new StrumNote(_skin, data, isCPU);
        strumNote.centerAnimations = true;
        add(strumNote);
        script.set("strumNote", strumNote);

        // -- Create Note Splash -- //
        splash = new RegularSplash(_skin, data);
        splashGroup.add(splash);
        script.set("splash", splash);

        // -- Create Sustain Splash -- //
        sustainSplash = new SustainSplash(_skin, data);
        splashGroup.add(sustainSplash);
		
        script.set("sustainSplash", sustainSplash);

        script.call("createReceptor", [MoonUtils.intToDir(data)]);

		spacing = script.get("spacing") ?? 0;
        judgementsSkin = script.get("judgementsSkin") ?? 'moon-engine';
        // update hitboxes
        strumNote.updateHitbox();
        splash.updateHitbox();
        sustainSplash.updateHitbox();
    }

    /**
     * Called upon note hitting.
     * @param note      The note that got hit.
     * @param judgement The judgement when hitting the note.
     * @param isSustain Whether or not it’s a sustain note.
     */
    public function onNoteHit(?note:Note, judgement:String = 'sick', isSustain:Bool = false)
    {
        // set positions
        final dir = MoonUtils.intToDir(data);
        final cx = strumNote.x + strumNote.width / 2;
        final cy = strumNote.y + strumNote.height / 2;
        
        strumNote.playAnim('$dir-confirm', true);

        // splash for taps (only sick non-sustains)
        if (judgement == 'sick' && !isCPU && !isSustain
            && splash.animation.getAnimationList().length > 0)
        {
            splash.setPosition((cx - splash.width / 2), (cy - splash.height / 2));
            splash.spawn();
        }
        
        // sustain splash
        if (!isSustain && note != null && note.duration > 90
            && sustainSplash.animation.getAnimationList().length > 0)
        {
            sustainSplash.setPosition((cx - sustainSplash.width / 2), (cy - sustainSplash.height / 2));
            sustainSplash.spawn();
        }
    }

    override public function update(elapsed:Float)
    {
		if(this.visible)
		{
			sustainSplash.visible = MoonSettings.callSetting('Hold Note Splashes');
			splash.visible = MoonSettings.callSetting('Note Splashes');
		}
		else
			sustainSplash.visible = splash.visible = false;
		
        super.update(elapsed);
        notesGroup.alpha = sustainsGroup.alpha = (visible) ? 1 : 0.00001;
    }
	
	override public function set_visible(visible:Bool):Bool
	{
		this.visible = visible;
		
		splash.visible = sustainSplash.visible = splashGroup.visible = visible;
		notesGroup.visible = sustainsGroup.visible = visible;

        for(note in notesGroup.members) note.update(0);
		
		return this.visible;
	}
}
