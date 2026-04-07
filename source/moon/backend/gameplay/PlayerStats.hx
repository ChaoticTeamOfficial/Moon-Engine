package moon.backend.gameplay;

@:publicFields

/**
 * A class in which stores stats for a player.
 */
class PlayerStats
{
    /**
     * Used for storing total notes that got hit or missed by the player.
     */
    var totalNotes(default, set):Int = 0;

    /**
     * Used for checking a total accuracy you got on said judgement.
     */
    var accuracyCount(default, set):Float = 0;

    /**
     * The player's precise accuracy.
     */
    var accuracy:Float = 0;

    /**
     * The player's total misses, either by ghost tapping or missing notes.
     */
    var misses(default, set):Int = 0;

    /**
     * The player's total score that increases depending on the judgement.
     */
    var score:Int = 0;

    /**
     * The combo of notes hit in a row without missing.
     */
    var combo(default, set):Int = 0;

    /**
     * The combo of notes hit in a row without missing, except it doesn't take sustain notes in account.
     */
    var noSustainCombo(default, set):Int = 0;

    /**
     * The highest combo the player got.
     */
    var highestCombo:Int = 0;

    /**
     * The highest combo the player got, ignoring the sustains.
     */
    var noSustainHighestCombo:Int = 0;

    /**
     * This player's total health.
     */
    var health(default, set):Float = 50;

    /**
     * This player's ID.
     */
    var playerID:String = 'p1';

    /**
     * A map containing all the notes hit on said judgement.
     */
    var judgementsCounter:Map<String, Int> =
    [
        'sick' => 0,
        'good' => 0,
        'bad' => 0,
        'shit' => 0,
        'miss' => 0
    ];

    var isGold:Bool = true;

    /**
     * Creates states for a specific player
     * @param playerID The player ID that'll be used. (e.g. `p1`, `opponent`)
     */
    function new(playerID:String = 'p1')
    {
        this.playerID = playerID;
        reset();
    }

    /**
     * Function called for updating the accuracy based on everything.
     */
    function updtAccuracy()
        accuracy = Math.round((accuracyCount / totalNotes) * 10000) / 100;

    /**
     * Resets all stats back to their default values on upon calling.
     */
    function reset()
    {
        accuracyCount = totalNotes = 0;
        accuracy = misses = score = combo = highestCombo = noSustainCombo = noSustainHighestCombo = 0;
        health = 50;
        isGold = true;

        for(judge => counter in judgementsCounter)
            judgementsCounter.set(judge, 0);
    }

    @:dox(hide)
    @:noCompletion function set_accuracyCount(value:Float):Float
    {
        accuracyCount = value;
        updtAccuracy();
        return value;
    }

    @:dox(hide)
    @:noCompletion function set_totalNotes(value:Int):Int
    {
        totalNotes = value;
        updtAccuracy();
        return value;
    }

    @:dox(hide)
    @:noCompletion function set_health(value:Float):Float
    {
        if(value <= 100)
            health = value;

        return value;
    }

    @:dox(hide)
    @:noCompletion function set_misses(misses:Int):Int
    {
        this.misses = misses;

        judgementsCounter.set('miss', judgementsCounter.get('miss') + 1);

        return this.misses;
    }

    @:dox(hide)
    @:noCompletion function set_combo(combo:Int):Int
    {
        this.combo = combo;

        if (combo > highestCombo)
            highestCombo = combo;

        return this.combo;
    }

    @:dox(hide)
    @:noCompletion function set_noSustainCombo(noSustainCombo:Int):Int
    {
        this.noSustainCombo = noSustainCombo;

        if (noSustainCombo > noSustainHighestCombo)
            noSustainHighestCombo = noSustainCombo;

        return this.noSustainCombo;
    }
}