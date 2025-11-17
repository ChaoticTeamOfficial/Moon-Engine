package moon.backend.data;

using StringTools;

/**
 * Structure for a Character's Dialogue data.
 **/
typedef DialogueChar = {
    /**
     * The name that will be displayed when a character is speaking.
     */
    ?displayName:String,

    /**
     * The position the character will be.
     */
    ?pos:Array<Float>,

    /**
     * Data for dialogue sounds.
     */
    ?soundData:{sounds:Array<String>, ?playType:String, ?pitchIntensity:Float, ?volume:Float},

    /**
     * The color that will override the character's default.
     */
    ?color:Array<Int>
}

@:publicFields
@:forward
abstract DialogueCharacter(DialogueChar) from DialogueChar to DialogueChar
{
    static function getChar(characterPath:String):DialogueCharacter
    {
        final actualPath = 'characters/$characterPath/dialogue/data';
        if (Paths.exists('$actualPath.json'))
            return Paths.JSON(actualPath);

        trace('$actualPath.json was not found.', "ERROR");
        return null;
    }
}