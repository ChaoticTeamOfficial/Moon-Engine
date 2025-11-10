package moon.backend.data;

import flixel.FlxG;
import flixel.util.FlxSave;
import haxe.Json;

typedef SongScoreData = {
    var score:Int;
    var misses:Int;
    var accuracy:Float;
}

@:publicFields
class SongData
{
    /**
     * This FlxSave instance used to persist data.
     */
    static var save:FlxSave = new FlxSave();

    /**
     * A map containing all the songs and each data.
     */
    static var songs:Map<String, SongScoreData> = [];

    static function init()
    {
        save.bind(Constants.SONGDATA_SAVE_BIND);
        load();
    }

    /**
     * Loads data from the save if it exists.
     */
    static function load()
    {
        if (save.data.songs != null)
            songs = save.data.songs;
    }

    /**
     * Saves a song data.
     * @param songName The song's name.
     * @param difficulty The song's difficulty
     * @param mix The character mix.
     * @param score The score.
     * @param misses The misses.
     * @param accuracy The accuracy.
     */
    static function saveData(songName:String, difficulty:String, mix:String, score:Int, misses:Int, accuracy:Float)
    {
        final old = songs.get('($mix)$songName-$difficulty');

        var shouldSave = false;

        if (old == null)
            shouldSave = true;
        else
        {
            shouldSave = 
                score > old.score ||
                misses < old.misses ||
                accuracy > old.accuracy;
        }

        if (shouldSave)
        {
            songs.set('($mix)$songName-$difficulty', {
                score: score > old.score ? score : old?.score ?? 0,
                misses: misses < old.misses ? misses : old?.misses ?? 0,
                accuracy: accuracy > old.accuracy ? accuracy : old?.accuracy ?? 0
            });

            trace('Saving data for song ($mix)${songName}-${difficulty}"', "DEBUG");

            save.data.songs = songs;
            save.flush();
        }
    }

    static function retrieveData(songName:String, difficulty:String, mix:String):SongScoreData
        return songs.get('($mix)$songName-$difficulty');
}