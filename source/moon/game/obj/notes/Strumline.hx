package moon.game.obj.notes;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class Strumline extends FlxTypedSpriteGroup<Receptor>
{
	/**
	 * Spacing between each receptor.
	 */
	public var receptorSpacing(default, set):Float = 0;

	/**
	 * Sets the ID for recognizing this strumline (whether its opponent or not.)
	 */
	public var playerID:String;

	/**
	 * This skin.
	 */
	public var skin(default, set):String;

	/**
	 * Whether is a CPU or not.
	 */
	public var isCPU:Bool;

	/**
	 * The conductor, useful for tracking time stuff.
	 */
	public var conductor:Conductor;

	/**
	 * Creates a strumline in screen.
	 * @param x         X Position.
	 * @param y         Y Position.
	 * @param skin      This skin.
	 * @param isCPU     Whether is a CPU or not.
	 * @param playerID  The player ID for this. can be opponent, p1, etc...
	 * @param conductor The conductor, useful for tracking time stuff.
	 */
	public function new(x:Float = 0, y:Float = 0, skin:String = 'v-slice', isCPU:Bool = false, playerID:String, conductor:Conductor)
	{
		super(x, y);
		this.playerID = playerID;
		this.conductor = conductor;
		this.isCPU = isCPU;
		this.skin = skin;
	}

	/**
	 * Repositions all receptors based on current `receptorSpacing`.
	 */
	public function repositionReceptors():Void
	{
		final centerOffset = ((4 * 0.5) * members[0].strumNote.width);

		for (i in 0...members.length)
		{
			var receptor = members[i];
			if (receptor == null) continue;

			receptor.setPosition(x, y);

			// yummy emoji
			receptor.x -= centerOffset;
			receptor.x += (receptor.strumNote.width + (receptorSpacing != 0 ? receptorSpacing : receptor.spacing)) * i;

			receptor.ID = i;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public var strumBG:MoonSprite = new MoonSprite().makeGraphic(0, 0);

	@:noCompletion
	public function set_skin(skin:String):String
	{
		this.skin = skin;
		this.clear();

		for (i in 0...4)
		{
			this.recycle(Receptor, () ->
			{
				var receptor = new Receptor(0, 0, skin, i, isCPU, playerID, conductor);
				receptor.ID = i;
				return receptor;
			});
		}

		repositionReceptors();

		strumBG.makeGraphic(Std.int(this.width), FlxG.height, FlxColor.BLACK);

		return skin;
	}

	@:noCompletion
	public function set_receptorSpacing(receptorSpacing:Float):Float
	{
		this.receptorSpacing = receptorSpacing;
		repositionReceptors();
		return this.receptorSpacing;
	}
}
