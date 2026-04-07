package moon.backend.data;

/**
 * A typedef that represents all data a judgements-combo file can contain.
 */
typedef JudgementsComboFile = {
    //TODO: Update the links lol, currently are a placeholder.

    /**
     * The judgement's appear and disappear list.
     * @see [All the available animations.](https://www.youtube.com)
     */
    var judgementAnims:PopAnimations;

    /**
     * The combo's appear and disappear list.
     * @see [All the available animations.](https://www.youtube.com)
     */
    var comboAnims:PopAnimations;

    /**
     * Whether should the combo play a roll animation or not.
     */
    var comboRolls:Bool;

    /**
     * Whether should both the combo and judgements have antialiasing or not.
     */
    var antialiasing:Bool;

    /**
     * The judgement's size.
     */
    var judgementsSize:Float;

    /**
     * The combo's size.
     */
    var comboSize:Float;
}

/**
 * A typedef that contains both the appear and disappear animations.
 * @see [All the available animations.](https://www.youtube.com)
 */
typedef PopAnimations = {
    /**
     * The appear animation.
     */
    var appear:String;

    /**
     * The disappear animation.
     */
    var disappear:String;
}

@:publicFields
@:forward

/**
 * An abstract that reads a judgements-combo file and returns its data.
 */
abstract JudgementsCombo(JudgementsComboFile) from JudgementsComboFile to JudgementsComboFile
{
    /**
     * Reads a judgements-combo data file and returns its data.
     * @param skin the skin name.
     */
    static function getData(skin:String):JudgementsCombo
    {
        if(Paths.exists('images/combo_judgements/$skin/config.json'))
            return Paths.JSON('images/combo_judgements/$skin/config');
        else
            trace('[JUDGEMENTS-COMBO] $skin was not found within the combo judgements directory.', "ERROR");

        return null;
    }
}