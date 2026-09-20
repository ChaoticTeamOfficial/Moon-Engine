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

	public var strumBG:MoonSprite = new MoonSprite().makeGraphic(1, 1, FlxColor.BLACK);

	var _bgW:Int = 0;
	var _bgH:Int = 0;

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

	inline function effectiveGap(receptor:Receptor):Float return (receptorSpacing != 0) ? receptorSpacing : (receptor.spacing ?? 0);

	/**
	 * Total width of the whole receptor cluster.
	 */
	function clusterWidth():Float
	{
		if (members.length == 0 || members[0] == null || members[0].strumNote == null) return 1;

		return members.length * members[0].strumNote.width + (members.length - 1) * effectiveGap(members[0]);
	}

	/**
	 * Repositions all receptors.
	 */
	public function repositionReceptors():Void
	{
		if (members.length == 0 || members[0] == null || members[0].strumNote == null) return;

		// W speed
		final noteW = members[0].strumNote.width;
		final gap = effectiveGap(members[0]);
		final totalW = clusterWidth();
		final startX = x - totalW * 0.5;

		for (i in 0...members.length)
		{
			final receptor = members[i];
			if (receptor == null) continue;

			// yummy emoji
			receptor.setPosition(startX + i * (noteW + gap), y);
			receptor.ID = i;
		}

		updateStrumBG();
	}

	public function updateStrumBG():Void
	{
		final size = measureReceptorCluster();
		final w = Std.int(Math.max(1, Math.ceil(size.width)));
		final h = Std.int(Math.max(1, Math.ceil(size.height)));

		if (w == _bgW && h == _bgH && strumBG.graphic != null) return;

		_bgW = w;
		_bgH = h;
		strumBG.makeGraphic(w, h, FlxColor.BLACK);
		strumBG.origin.set(0, 0);
		strumBG.offset.set(0, 0);
	}

	function measureReceptorCluster():
		{width:Float, height:Float}
	{
		if (members.length == 0) return {
			width: 1,
			height: FlxG.height
		};

		var minX = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY;

		for (receptor in members)
		{
			if (receptor == null || receptor.strumNote == null) continue;

			final left = receptor.strumNote.x;
			final right = receptor.strumNote.x + receptor.strumNote.width;

			if (left < minX) minX = left;
			if (right > maxX) maxX = right;
		}

		if (minX == Math.POSITIVE_INFINITY) return {
			width: clusterWidth(),
			height: FlxG.height
		};

		return {
			width: maxX - minX,
			height: FlxG.height
		};
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		final size = measureReceptorCluster();
		final w = Std.int(Math.max(1, Math.ceil(size.width)));
		final h = Std.int(Math.max(1, Math.ceil(size.height)));
		if (w != _bgW || h != _bgH) updateStrumBG();
	}

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

		_bgW = 0;
		_bgH = 0;

		repositionReceptors();
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
