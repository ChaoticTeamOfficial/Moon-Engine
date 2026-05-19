package moon.backend.data;

using StringTools;

// public fields on my life
@:publicFields

/**
 * The SongLibrary class basically handles the entire game Song List!
 * It separates weeks onto categories.
 **/
class SongLibrary
{
	@:dox(hide)
	static var instance:SongLibrary;

	static function get():SongLibrary
	{
		if(instance == null) instance = new SongLibrary();
		return instance;
	}

	/**
	 * An array containing all the found difficulties.
	 */
	var allDifficulties:Array<Difficulty> = [];

	/**
	 * All the songs separated by week. `all` is a value that'll list every available song.
	 */
	var songsByWeek:Map<String, Array<SongBase>> = [];

	/**
	 * All the available songs.
	 */
	var allSongs:Array<SongBase> = [];

	@:dox(hide)
	function new()
	{
		loadDifficulties();
		scanSongs();
	}

	private function loadDifficulties():Void
	{
		// we want to reset the array just to guarantee nothing goes wrong...
		allDifficulties = [];

		// loads all the difficulties in the data folder
		for (file in Paths.readDir('data/difficulties/', ['.json'], true))
		{
			final data:Difficulty = Paths.JSON('data/difficulties/$file');
			if(data != null && data.name != null)
				allDifficulties.push(data);
		}

		// why is this kinda funny? lol
		// TODO: Make it pop-up a error window once I get my hands on Funkin's windows utilities.
		if(allDifficulties.length == 0) trace('[SONG-LIBRARY] CONCERNING ERROR: NO DIFFICULTIES WERE FOUND!!!', "ERROR");
	}

	private function scanSongs()
	{
		allSongs = [];

		// we scan for all available songs.
		for(songFolder in Paths.readDir('songs/'))
		{
			for(mix in Paths.readDir('songs/$songFolder'))
			{
				// this is a funny thing to do XD
				if(mix == 'events') continue;

				for(chartFile in Paths.readDir('songs/$songFolder/$mix/', ['.json'], true))
				{
					if(chartFile.startsWith('chart-'))
					{
						final entry:SongBase = {
							song: songFolder,
							mix: mix,
							difficulty: chartFile.substr(6)
						};

						allSongs.push(entry);

						if(!songsByWeek.exists('all'))
							songsByWeek.set('all', []);

						songsByWeek.get('all').push(entry);
					}
				}
			}
		}

		// now we load actual week files from data/weeks/
		for(weekFile in Paths.readDir('data/weeks/', ['.json'], true))
		{
			//trace(weekFile);
			//WD GASTER IS THAT YOU?!?!
			final wd:Week = Week.get(weekFile);
			//trace(wd);
			if(wd != null && wd.tracks != null)
			{
				// W songs!!
				// thats a short for weekSongs lol
				final wSongs:Array<SongBase> = [];

				for(track in wd.tracks)
				{
					for(song in allSongs)
					{
						if(song.song.toLowerCase() == track.toLowerCase())
							wSongs.push(song);
					}
				}

				songsByWeek.set(weekFile, wSongs);
			}
		}

		//trace(songsByWeek);
	}

	/**
	 * Returns all available difficulties for a song.
	 * @param song The song's name.
	 * @param mix  The song's mix.
	 */
	function availableDifficulties(song:String, mix:String):Array<Difficulty>
	{
		final available:Array<Difficulty> = [];

		for(diff in allDifficulties)
		{
			if(Paths.exists('songs/$song/$mix/chart-${diff.name}.json'))
				available.push(diff);
		}

		return available;
	}

	/**
	 * Gets a song list for a specific week (returns all found songs if week == 'all')
	 * @param week The week's name.
	 */
	function weekSonglist(week:String = 'all'):Array<SongBase>
		return (week == 'all') ? allSongs : (songsByWeek?.get(week) ?? []);
}

/**
 * A typedef containing all difficulty info.
 */
typedef Difficulty = {

	/**
	 * Internal name used in chart files.
	 */
	var name:String;

	/**
	 * The display name, shown in freeplay, story mode, etc.
	 */
	var displayName:String;

	/**
	 * The suffix for instrumentals.
	 */
	var ?instSuffix:String;

	/**
	 * The suffix for voices.
	 */
	var ?voicesSuffix:String;

	/**
	 * Color used for the UI text.
	 */
	var ?color:Array<Int>;
}