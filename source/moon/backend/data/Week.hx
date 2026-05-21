package moon.backend.data;

/**
 * All the data a Week file can have.
 **/
typedef WeekFile = {
    /**
     * The name that'll be used in menus.
     */
    var displayName:String;

    /**
     * The week's description, shown in the weeks menu.
     */
    var description:String;

    /**
     * All the tracks that belongs to this week.
     */
    var tracks:Array<String>;

    /**
     * A RGB value for this week.
     */
    var color:Array<Int>;

    /**
     * The week's main mix.
     */
    var ?mainMix:String;
}

@:publicFields
@:forward

/**
 * An abstract that returns a week data from a week file.
 */
abstract Week(WeekFile) from WeekFile to WeekFile
{
    /**
     * Returns a week data from a week file.
     * @param week the week's file name.
     */
    static function get(week:String):Week
    {
        if(Paths.exists('data/weeks/$week.json'))
            return Paths.JSON('data/weeks/$week');
        else
            trace('[WEEK] $week was not found within the week directory.', "ERROR");

        return null;
    }
}