package moon.backend.data;

using StringTools;

/**
 * One actor declared at the top of a cutscene.
 * Actors are spawned before actions run.
 */
typedef CutsceneActor =
{
	/**
	 * Unique id used by actions.
	 */
	var id:String;

	/**
	 * Character folder name under `characters/`.
	 * If omitted, the actor is a plain MoonSprite loaded from `image`.
	 */
	var ?character:String;

	/**
	 * Image path when not using a character.
	 */
	var ?image:String;

	/**
	 * Atlas type for image actors.
	 */
	var ?atlasType:AtlasType;

	/** 
	 * Animations for the actor.
	 */
	var ?animations:Array<Paths.AnimationData>;

	var ?x:Float;
	var ?y:Float;
	var ?scale:Float;
	var ?alpha:Float;
	var ?visible:Bool;
	var ?flipX:Bool;
	var ?antialiasing:Bool;

	/**
	 * If true, try to reuse an existing character from the gameplay scene.
	 */
	var ?bindExisting:Bool;

	/**
	 * Camera this actor is drawn on: camGAME, camHUD, camALT (defaults to camGAME).
	 */
	var ?camera:String;
}

/**
 * A single action in the cutscene timeline.
 */
typedef CutsceneAction =
{
	/**
	 * The action type. (think of it like an event name!)
	 */
	var type:String;

	/**
	 * Seconds to wait after this action starts before the next sequential action.
	 */
	var ?duration:Float;

	/**
	 * Ease name for this action.
	 */
	var ?ease:String;

	/**
	 * Target actor id, camera name, or character role.
	 */
	var ?target:String;

	var ?force:Bool;

	/**
	 * If true, this action does not block the queue, as the next action starts immediately.
	 */
	var ?parallel:Bool;

	var ?values:Dynamic;
}

// ROOT?! wait a minute....

/**
 * Root cutscene file structure.
 */
typedef CutsceneFile =
{
	/**
	 * Either display name or a debug id.
	 */
	var ?id:String;

	/**
	 * Whether the player can skip the whole cutscene.
	 */
	var ?skippable:Bool;

	/**
	 * Whether pause is allowed during the cutscene.
	 */
	var ?canPause:Bool;

	/**
	 * Actors spawned/bound before the first action.
	 */
	var ?actors:Array<CutsceneActor>;

	/**
	 * Ordered list of actions.
	 */
	var actions:Array<CutsceneAction>;
}

@:publicFields
@:forward
/**
 * Loads a cutscene JSON and returns its data.
 */
abstract Cutscene(CutsceneFile) from CutsceneFile to CutsceneFile
{
	/**
	 * Loads a cutscene file.
	 * @param cutsceneFile Path without extension (Paths usage not needed).
	 */
	static function get(cutsceneFile:String):Cutscene
	{
		if (Paths.exists('$cutsceneFile.json'))
		{
			final data:CutsceneFile = Paths.JSON(cutsceneFile);
			if (data == null || data.actions == null)
			{
				trace('[CUTSCENE] $cutsceneFile.json is empty or missing actions.', "ERROR");
				return null;
			}
			return data;
		}

		trace('[CUTSCENE] $cutsceneFile.json was not found.', "ERROR");
		return null;
	}
}
