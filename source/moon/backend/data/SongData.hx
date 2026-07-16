package moon.backend.data;

import flixel.util.FlxSave;

/**
 * The stats data that will be saved once a song is completed.
 */
typedef SongScoreData =
{
	/**
	 * The score the player got.
	 */
	var score:Int;

	/**
	 * The misses the player got.
	 */
	var misses:Int;

	/**
	 * The player's accuracy during a song.
	 */
	var accuracy:Float;
}

/**
 * A single stored entry, keeping the song's identity alongside its score data.
 * Needed so we can list/iterate saved songs without having to re-parse the save key.
 */
typedef SavedSongEntry =
{
	var song:SongBase;
	var data:SongScoreData;
}

/**
 * A record of what got saved in a single `saveData()` call, kept in `sessionLog`
 * so you can tell exactly which songs got touched and which fields changed.
 */
typedef SongSaveLog =
{
	var song:SongBase;

	/**
	 * Which fields actually got updated. Can contain `score`, `misses`, `accuracy`, or `new` (for a first-time save).
	 */
	var updatedFields:Array<String>;
}

@:publicFields
/**
 * A class that's used for saving a song's score, misses and accuracy.
**/
class SongData
{
	/**
	 * This FlxSave instance used to persist data.
	 */
	static var save:FlxSave = new FlxSave();

	/**
	 * A map containing all the songs and each data.
	 */
	static var songs:Map<String, SavedSongEntry> = new Map<String, SavedSongEntry>();

	/**
	 * A running log of every song that got its data saved (and what exactly changed) this session.
	 */
	static var sessionLog:Array<SongSaveLog> = [];

	@:dox(hide)
	static function init()
	{
		save.bind(Constants.SONGDATA_SAVE_BIND);
		sessionLog = [];
		load();
	}

	static function toKey(song:SongBase):String return '(${song.mix})' + '${song.song}-${song.difficulty}';

	/**
	 * Attempts to parse an old-format key `(mix)song-difficulty` back into a SongBase.
	 * Used purely for migrating old saves that only stored the key + raw score data.
	 * (I don't want to lose my scores, man!!!!)
	 */
	private static function keyToSong(key:String):SongBase
	{
		final mixEnd = key.indexOf(')');

		final rest = key.substring(mixEnd + 1);
		final lastDash = rest.lastIndexOf('-');

		final songName = (lastDash != -1) ? rest.substring(0, lastDash) : rest;
		final difficulty = (lastDash != -1) ? rest.substring(lastDash + 1) : '';

		return {
			song: songName,
			difficulty: difficulty,
			mix: key.substring(1, mixEnd)
		};
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

				final entry:SavedSongEntry = (Reflect.hasField(val, 'song') && Reflect.hasField(val, 'data')) ? {
					song: {
						song: val.song.song,
						difficulty: val.song.difficulty,
						mix: val.song.mix,
						displayName: val.song?.displayName
					},
					data: {
						score: val.data.score,
						misses: val.data.misses,
						accuracy: val.data.accuracy
					}
				} : {
					// old save: reconstruct the SongBase from the key itself.
					song: keyToSong(field),
					data: {
						score: val.score,
						misses: val.misses,
						accuracy: val.accuracy
					}
					};

				songs.set(field, entry);
			}
			flush();
		}
	}

	/**
	 * Saves a song's data if it has any new bests.
	 * @param song     The song's identity (song, difficulty, mix).
	 * @param score    The score.
	 * @param misses   The misses.
	 * @param accuracy The accuracy.
	 * @return An array of the fields that actually got updated (`score`, `misses`, `accuracy`), or `["new"]` for a first-time save. Empty if nothing changed.
	 */
	static function saveData(song:SongBase, score:Int, misses:Int, accuracy:Float):Array<String>
	{
		final key:String = toKey(song);
		final existing:SavedSongEntry = songs.get(key);

		var updatedFields:Array<String> = [];

		if (existing == null)
		{
			songs.set(key, {
				song: song,
				data: {
					score: score,
					misses: misses,
					accuracy: accuracy
				}
			});
			updatedFields.push('new');
		}
		else
		{
			final old = existing.data;

			if (score > old.score)
			{
				old.score = score;
				updatedFields.push('score');
			}

			if (misses < old.misses)
			{
				old.misses = misses;
				updatedFields.push('misses');
			}

			if (accuracy > old.accuracy)
			{
				old.accuracy = accuracy;
				updatedFields.push('accuracy');
			}

			// keep the song's identity current (e.g. if displayName got added later)
			existing.song = song;
		}

		if (updatedFields.length > 0)
		{
			trace('[SONG-DATA] Saving data for $key (${updatedFields.join(", ")})');
			sessionLog.push({
				song: song,
				updatedFields: updatedFields
			});
			flush();
		}

		return updatedFields;
	}

	/**
	 * Retrieves the saved data for a song, if any.
	 * @param song The song's identity (song, difficulty, mix).
	 */
	static function retrieveData(song:SongBase):SongScoreData
	{
		final entry = songs.get(toKey(song));
		return (entry != null) ? entry.data : null;
	}

	/**
	 * Returns every song that currently has saved data, as an array of `SavedSongEntry`.
	 */
	static function getAllSaved():Array<SavedSongEntry> return[for (entry in songs) entry];

	/**
	 * Writes the current `songs` map to disk.
	 */
	private static function flush()
	{
		var saveData:Dynamic = {};
		for (k in songs.keys()) Reflect.setField(saveData, k, songs.get(k));

		save.data.songs = saveData;
		save.flush();
	}
}
