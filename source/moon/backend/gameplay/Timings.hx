package moon.backend.gameplay;

import flixel.util.FlxColor;

@:publicFields

//TODO: reorganize this class, and documment it properly.
// the reason as to why i'm not doing it *right now* is simply because I
// will change how the judgements are organized!
class Timings
{
    static var judgementsMap:Map<String, Array<Dynamic>> = [
        /**
            Accuracy count (0)
            max milliseconds (1)
            score from it (2)
            health gain (3)
            judgement color (4)
        **/
        'sick' => [1.0,     45,      350,   2,     0xFF2883ff],
        'good' => [0.5,     90,      150,   1,     0xFF44cd4d],
        'bad'  => [-0.02,   135,     0,     0.5,   0xFFa8738a],
        'shit' => [-0.5,    157.5,  -50,   -1,     0xFF59443f],
        'miss' => [-1.0,    180,    -600,  -4.5,   0xFF894331]
    ];

    static var thresholds:Array<RankData> = [
        {limit: 60, rank: 'LOSS', short: 'L', color: 0xFF6044FF},
        {limit: 80, rank: 'GOOD', short: 'G', color: 0xFFEF8764},
        {limit: 90, rank: 'GREAT', short: 'G', color: 0xFFEAF6FF},
        {limit: 98, rank: 'EXCELLENT', short: 'E', color: 0xFFFDCB42},
        {limit: 100, rank: 'PERFECT', short: 'P', color: 0xFFFF58B4},
        {limit: 101, rank: 'PERFECT-GOLD', short: 'P', color: 0xFFFFB619}
    ];

    static var values(get, default):Array<String>;

    /**
     * Get a rank based on accuracy.
     * @param accuracy The accuracy value.
     */  
    static function getRank(accuracy:Float):RankData
    {
        for (t in thresholds)
            if (accuracy < t.limit)
                return t;

        return {limit: 0, rank: 'NOT FOUND.', short: 'N', color: FlxColor.WHITE};
    }

    /**
     * Get a parameter data from a judgement.
     * @param jt The judgement that will iterate data from.
     */
    static function getParameters(jt:String):Array<Dynamic>
        return judgementsMap.get(jt);

    @:noCompletion
    static function get_values():Array<String>
    {
        values = ['sick', 'good', 'bad', 'shit', 'miss'];
        return values;
    }
}

typedef RankData = {
    var limit:Float;
    var rank:String;
    var short:String;
    var color:FlxColor;
}