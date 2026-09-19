package moon.game.obj.notes;

import moon.backend.gameplay.Timings.Judgement;
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
		this.data = data;
		this.isCPU = isCPU;
		this.playerID = playerID;
		this.conductor = conductor;

		// ensure our sub-groups are children
		add(notesGroup);
		add(sustainsGroup);
		add(splashGroup);

		// load the initial skin (this will call _updtGraphics)
		// wow thanks past toffee nobody would've figured it out mhm
		set_skin(skin);
	}

	@:noCompletion
	private function get_skin():String return _skin;

	@:noCompletion
	private function set_skin(value:String):String
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
		final data = NoteskinData.get(_skin);
		final dir = MoonUtils.intToDir(this.data);

		// ---- Strum setupsies ---- //
		strumNote = new StrumNote(_skin, this.data, isCPU);
		strumNote.centerAnimations = true;
		add(strumNote);
		MoonUtils.applyNoteskinPiece(strumNote, data.strum, dir, data.strumScale ?? 1, data.antialiasing ?? true);

		strumNote.animation.onFinish.add(function(anim:String)
		{
			if (anim == '$dir-confirm' && isCPU) strumNote.playAnim('$dir-static');
		});

		strumNote.playAnim('$dir-static', true);

		// ---- Splash setupsies ---- //
		splash = new RegularSplash(_skin, this.data);
		splashGroup.add(splash);

		MoonUtils.applyNoteskinPiece(splash, data.splash, dir, data.splashScale ?? 1, data.antialiasing ?? true);
		splash.playRandom = data.extra?.splashPlayRandom ?? false;

		if (data.extra?.splashAlphaOnFrame != null) splash.animation.onFrameChange.add((_, _, _) -> splash.alpha = data.extra.splashAlphaOnFrame);

		sustainSplash = new SustainSplash(_skin, this.data);
		splashGroup.add(sustainSplash);

		MoonUtils.applyNoteskinPiece(sustainSplash, data.sustainSplash, dir, data.splashScale ?? 1, data.antialiasing ?? true);

		sustainSplash.animation.onFinish.add((anim:String) ->
		{
			if (anim == '$dir-end') sustainSplash.visible = sustainSplash.active = false;
			else if (anim == 'pre') sustainSplash.playAnim('$dir-loop', true);
		});

		spacing = data.spacing ?? 0;
		judgementsSkin = data.judgementsSkin ?? 'moon-engine';
	}

	/**
	 * Called upon note hitting.
	 * @param note      The note that got hit.
	 * @param judgement The judgement when hitting the note.
	 * @param isSustain Whether or not it’s a sustain note.
	 */
	public function onNoteHit(?note:Note, judgement:Judgement = SICK, isSustain:Bool = false)
	{
		final dir = MoonUtils.intToDir(data);

		strumNote.playAnim('$dir-confirm', true);

		if (judgement == SICK && !isCPU && !isSustain && splash.animation.getAnimationList().length > 0) splash.spawn();

		if (!isSustain && note != null && note.duration > 90 && sustainSplash.animation.getAnimationList().length > 0) sustainSplash.spawn();
	}

	override public function update(elapsed:Float)
	{
		SpriteUtils.centerSprite(splash, strumNote);
		SpriteUtils.centerSprite(sustainSplash, strumNote);

		if (this.visible)
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

		for (note in notesGroup.members) note.update(0);

		return this.visible;
	}
}
