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
    var appear:AppearAnim;

    /**
     * The disappear animation.
     */
    var disappear:DisappearAnim;
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

    static function getSpawnList(?exclude:Array<AppearAnim>):Array<AppearAnim>
    {
        final all:Array<AppearAnim> = [JUMP_IN, JUMP_OUT, SCALE, PULSE, SKEW_X, SKEW_Y, SKEW_BOTH, SLIDE, SLIDE_SKEW, LIGHT, ANGLE, LASER, SHAKE];
        
        if(exclude != null && exclude.length > 0)
            for(ex in exclude)
                if(all.contains(ex))
                    all.remove(ex);

        return all;
    }

    static function getDespawnList(?exclude:Array<DisappearAnim>):Array<DisappearAnim>
    {
        final all:Array<DisappearAnim> = [FADE, SCALE, SCALE_FADE, BOUNCE, BOUNCE_FADE, SKEW_X, SKEW_Y, SKEW_BOTH, SKEW_X_FADE, SKEW_Y_FADE, SKEW_BOTH_FADE, SQUISH_X, SQUISH_Y];
        
        if(exclude != null && exclude.length > 0)
            for(ex in exclude)
                if(all.contains(ex))
                    all.remove(ex);

        return all;
    }
}

enum abstract AppearAnim(String) from String to String
{
    var NOTESKIN = 'Noteskin Default';
    var JUMP_IN = 'jump-in';
    var JUMP_OUT = 'jump-out';
    var SCALE = 'scale';
    var PULSE = 'pulse';
    var SKEW_X = 'skewX';
    var SKEW_Y = 'skewY';
    var SKEW_BOTH = 'skewBoth';
    var SLIDE = 'slide';
    var SLIDE_SKEW = 'slide&skew';
    var LIGHT = 'light';
    var ANGLE = 'angle';
    var LASER = 'laser';
    var SHAKE = 'shake';
}

enum abstract DisappearAnim(String) from String to String
{
    var NOTESKIN = 'Noteskin Default';
    var FADE = 'fade';
    var SCALE = 'scale';
    var SCALE_FADE = 'scale&fade';
    var BOUNCE = 'bounce';
    var BOUNCE_FADE = 'bounce&fade';
    var SKEW_X = 'skewX';
    var SKEW_Y = 'skewY';
    var SKEW_BOTH = 'skewBoth';
    var SKEW_X_FADE = 'skewX&fade';
    var SKEW_Y_FADE = 'skewY&fade';
    var SKEW_BOTH_FADE = 'skewBoth&fade';
    var SQUISH_X = 'squishX';
    var SQUISH_Y = 'squishY';
}