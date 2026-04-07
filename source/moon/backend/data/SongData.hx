package moon.backend.data;

import flixel.util.FlxSave;
import haxe.ds.StringMap;

typedef SongScoreData = {
    score:Int,
    misses:Int,
    accuracy:Float
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
    static var songs:StringMap<SongScoreData> = new StringMap<SongScoreData>();

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
        {
            var data:Dynamic = save.data.songs;
            for (field in Reflect.fields(data))
            {
                var val:Dynamic = Reflect.field(data, field);
                songs.set(field, {
                    score: val.score,
                    misses: val.misses,
                    accuracy: val.accuracy
                });
            }
        }
    }

    /**
     * Saves a song data.
     * @param songName The song's name.
     * @param difficulty The song's difficulty
     * @param mix The character mix.
     * @param score The score.
     * @param misses The misses.
     * @param accuracy The accuracy.
     * returns if the data got saved or not.
     */
    static function saveData(songName:String, difficulty:String, mix:String, score:Int, misses:Int, accuracy:Float):Bool
    {
        var key:String = '(${mix})' + '${songName}-${difficulty}';
        var old:SongScoreData = songs.get(key);

        var shouldSave:Bool = false;

        if (old == null)
            shouldSave = true;
        else
        {
            if (score > old.score)
                shouldSave = true;
            else if (score == old.score && misses < old.misses)
                shouldSave = true;
            else if (score == old.score && misses == old.misses && accuracy > old.accuracy)
                shouldSave = true;
        }

        if (shouldSave)
        {
            songs.set(key, {
                score: score,
                misses: misses,
                accuracy: accuracy
            });

            trace('[SONG-DATA] Saving data for $key');

            var saveData:Dynamic = {};
            for (k in songs.keys())
                Reflect.setField(saveData, k, songs.get(k));

            save.data.songs = saveData;
            save.flush();
            return true;
        }

        return false;
    }

    static function retrieveData(songName:String, difficulty:String, mix:String):SongScoreData
    {
        var key:String = '(${mix})' + '${songName}-${difficulty}';
        return songs.get(key);
    }
}