package moon.backend.data;

typedef WeekFile = {
    var displayName:String;
    var description:String;

    var tracks:Array<String>;
    var color:Array<Int>;

    var ?mainMix:String;
}

@:publicFields
@:forward
abstract Week(WeekFile) from WeekFile to WeekFile
{
    static function getWeek(week:String):Week
    {
        if(Paths.exists('data/weeks/$week.json'))
            return Paths.JSON('data/weeks/$week');
        else
            trace('[WEEK] $week was not found within the week directory.', "ERROR");

        return null;
    }
}