package moon.backend.data;

using StringTools;

/**
 * Structure for a Character's Dialogue data.
 **/
typedef DialogueChar = {
    /**
     * The name that will be displayed when a character is speaking.
     */
    var ?displayName:String;

    /**
     * Data for dialogue sounds.
     * @param sounds All the sounds the dialogue can play when typing.
     * @param playType How will the sound play. Types: `order`, `random`, `order-double` and `even-odds`.
     * @param pitchIntensity How much will the pitch vary when typing.
     */
    var ?soundData:{sounds:Array<String>, ?playType:String, ?pitchIntensity:Float};

    /**
     * Position of the character in-screen.
     */
    var position:Array<Float>;

    /**
     * The sprite's antialiasing,
     */
    var antialiasing:Bool;

    /**
     * All the animations on this portrait.
     */
    var animations:Array<Paths.AnimationData>;

    /**
     * The color that will override the character's default.
     */
    var color:Array<Int>;
}

@:publicFields
@:forward

/**
 * An abstract that reads a DialogueChar file and returns its data.
 */
abstract DialogueCharacter(DialogueChar) from DialogueChar to DialogueChar
{
    /**
     * Gets the dialogueChar file and returns its data.
     * @param characterPath The character's name.
     */
    static function getChar(characterPath:String):DialogueCharacter
    {
        final actualPath = 'characters/$characterPath/dialogue/data';
        if (Paths.exists('$actualPath.json'))
            return Paths.JSON(actualPath);

        trace('[DIALOGUE-CHARACTER] $actualPath.json was not found.', "ERROR");
        return null;
    }
}