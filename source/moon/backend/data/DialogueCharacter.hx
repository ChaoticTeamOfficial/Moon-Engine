package moon.backend.data;

using StringTools;

/**
 * Structure for a Character Dialogue data.
 **/
typedef DialogueLine = {
    /**
     * The character who's speaking.
     */
    ?character:String,
    /**
     * The expression a character will do.
     */
    ?expression:String,
    /**
     * The text displayed when a character speaks.
     */
    text:String,
    /**
     * The text's speed.
     */
    ?speed:Float,
    /**
     * The event that'll execute on this dialogue line (if exists.)
     */
    ?events:Array<DialogueEvent>,
    /**
     * Color that overrides the character's one if exists.
     */
    ?color:String
}

@:publicFields
@:forward
abstract Dialogue(DialogueFile) from DialogueFile to DialogueFile
{
    static function getDialogue(characterPath:String):Dialogue
    {
        final actualPath = 'characters/'
        if (Paths.exists(characterPath))
            return Paths.JSON(characterPath);

        trace('$characterPath was not found.', "ERROR");
        return null;
    }
}