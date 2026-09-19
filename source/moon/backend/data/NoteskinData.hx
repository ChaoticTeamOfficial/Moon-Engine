package moon.backend.data;

/**
 * Definition of a single animation that can be registered on a noteskin piece.
 */
typedef NoteskinAnim =
{
	/**
	 * The name the code will call (e.g. "left-static", "splash0", "left-hold")
	 */
	var name:String;

	/** 
	 * The prefix inside the sparrow atlas.
	 */
	var prefix:String;

	/**
	 * FPS
	 */
	var ?fps:Int;

	/**
	 * Whether the animation loops.
	 */
	var ?looped:Bool;
}

/**
 * Common visual settings that can be applied to any noteskin piece.
 */
typedef NoteskinPiece =
{
	/**
	 * Path to the sparrow atlas.
	 */
	var ?asset:String;

	var ?scale:Float;
	var ?antialiasing:Bool;

	/**
	 * Whether animations should try to center automatically.
	 */
	var ?centerAnimations:Bool;

	/**
	 * Regular offsets.
	 */
	var ?offset:
		{x:Float, y:Float};

	/**
	 * Extra offsets.
	 */
	var ?extraOffset:
		{x:Float, y:Float};

	var ?blend:String;

	/**
	 * List of animations for this piece
	 */
	var ?animations:Array<NoteskinAnim>;
}

/**
 * All the data a noteskin file holds.
 */
typedef NoteskinFile =
{
	var ?name:String;
	var ?uiSkin:String;
	var ?judgementsSkin:String;
	var ?spacing:Float;
	var ?hasQuantization:Bool;
	var ?noteScale:Float;
	var ?strumScale:Float;
	var ?splashScale:Float;

	var ?antialiasing:Bool;

	var ?strum:NoteskinPiece;
	var ?note:NoteskinPiece;
	var ?splash:NoteskinPiece;
	var ?sustainSplash:NoteskinPiece;

	/**
	 * Optional separate atlas used when hasQuantization is applicable.
	 */
	var ?quantAsset:String;

	/** 
	 * Anything skin-specific that doesn’t fit the typed fields...
	 */
	var ?extra:Dynamic;
}

@:publicFields
@:forward
abstract NoteskinData(NoteskinFile) from NoteskinFile to NoteskinFile
{
	static function get(skin:String):NoteskinData
	{
		final jsonPath = 'images/notes/$skin/noteskin';
		if (Paths.exists(jsonPath + '.json')) return Paths.JSON(jsonPath);

		return {
			name: skin,
			uiSkin: 'moon-engine',
			judgementsSkin: 'moon-engine',
			spacing: 0,
			hasQuantization: false,
			noteScale: 1,
			strumScale: 1,
			splashScale: 1,
			antialiasing: true
		};
	}
}
