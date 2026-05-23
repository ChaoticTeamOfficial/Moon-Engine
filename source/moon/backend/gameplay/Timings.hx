package moon.backend.gameplay;

import flixel.util.FlxColor;

/**
 * Data for a single judgement tier.
 */
typedef JudgementData = {
    var accuracyCount:Float;
    var maxMs:Float;
    var score:Int;
    var healthGain:Float;
    var color:FlxColor;
}

/**
 * Data for a single rank.
 */
typedef RankData = {
    var limit:Float;
    var rank:String;
    var short:String;
    var color:FlxColor;
}

/**
 * All valid judgement names.
 */
enum abstract Judgement(String) to String from String {
    var SICK = 'sick';
    var GOOD = 'good';
    var BAD = 'bad';
    var SHIT = 'shit';
    var MISS = 'miss';
}

@:publicFields

/**
 * The class that handles timings and everything related to them.
 */
class Timings
{
    /**
     * A Map that holds all the judgements with their respective data.
     */
    static final judgements:Map<Judgement, JudgementData> = [
        SICK  => { accuracyCount:  1.0,  maxMs:  50,  score:  350, healthGain:  2.0,  color: 0xFF2883ff },
        GOOD  => { accuracyCount:  0.5,  maxMs: 100,  score:  150, healthGain:  1.0,  color: 0xFF44cd4d },
        BAD   => { accuracyCount: -0.02, maxMs: 135,  score:    0, healthGain:  0.5,  color: 0xFFa8738a },
        SHIT  => { accuracyCount: -0.5,  maxMs: 160,  score:  -50, healthGain: -1.0,  color: 0xFF59443f },
        MISS  => { accuracyCount: -1.0,  maxMs: 180,  score: -600, healthGain: -4.5,  color: 0xFF894331 }
    ];

    /**
     * All ranks and their thresholds.
     */
    static final thresholds:Array<RankData> = [
        { limit: 60,  rank: 'LOSS',         short: 'L', color: 0xFF6044FF },
        { limit: 80,  rank: 'GOOD',         short: 'G', color: 0xFFEF8764 },
        { limit: 90,  rank: 'GREAT',        short: 'G', color: 0xFFEAF6FF },
        { limit: 98,  rank: 'EXCELLENT',    short: 'E', color: 0xFFFDCB42 },
        { limit: 100, rank: 'PERFECT',      short: 'P', color: 0xFFFF58B4 },
        { limit: 101, rank: 'PERFECT-GOLD', short: 'P', color: 0xFFFFB619 }
    ];

    static final values:Array<Judgement> = [SICK, GOOD, BAD, SHIT, MISS];

    /**
     * Returns rank data for a given accuracy value.
     */
    static function getRank(accuracy:Float):RankData
    {
        for (t in thresholds)
            if (accuracy < t.limit)
                return t;

        return { limit: 0, rank: 'NOT FOUND.', short: 'N', color: FlxColor.WHITE };
    }

    /**
     * Returns typed judgement data for a given judgement.
     */
    static function get(j:Judgement):JudgementData
        return judgements.get(j);
}