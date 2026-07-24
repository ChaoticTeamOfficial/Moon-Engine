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
		if (instance == null) instance = new SongLibrary();
		return instance;
	}

	// uhm... as easy as this XD

	static function destroy()
	{
		instance = null;
	}

	/**
	 * An array containing all the found difficulties, sorted by `order`.
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

	/**
	 * Ordered list of category (week) ids, always starting with "all".
	 */
	var categoryOrder:Array<String> = [];

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
			if (data != null && data.name != null) allDifficulties.push(data);
		}

		// sort by order (unset order goes last)
		allDifficulties.sort((a, b) ->
		{
			final aOrder = a.order ?? 999;
			final bOrder = b.order ?? 999;
			return aOrder - bOrder;
		});

		// why is this kinda funny? lol
		if (allDifficulties.length == 0) trace('[SONG-LIBRARY] CONCERNING ERROR: NO DIFFICULTIES WERE FOUND!!!', "ERROR");
	}

	private function scanSongs()
	{
		allSongs = [];
		categoryOrder = ['all'];

		// we scan for all available songs.
		for (songFolder in Paths.readDir('songs/'))
		{
			for (mix in Paths.readDir('songs/$songFolder'))
			{
				// skip non-mix directories (e.g. shared assets)
				if (mix == 'events') continue;

				for (chartFile in Paths.readDir('songs/$songFolder/$mix/', ['.json'], true))
				{
					if (chartFile.startsWith('chart-'))
					{
						final entry:SongBase = {
							song: songFolder,
							mix: mix,
							difficulty: chartFile.substr(6)
						};

						allSongs.push(entry);

						if (!songsByWeek.exists('all')) songsByWeek.set('all', []);

						songsByWeek.get('all').push(entry);
					}
				}
			}
		}

		// now we load actual week files from data/weeks/
		for (weekFile in Paths.readDir('data/weeks/', ['.json'], true))
		{
			final wd:Week = Week.get(weekFile);
			if (wd != null && wd.tracks != null)
			{
				final wSongs:Array<SongBase> = [];

				for (track in wd.tracks)
				{
					for (song in allSongs)
					{
						if (song.song.toLowerCase() == track.toLowerCase()) wSongs.push(song);
					}
				}

				songsByWeek.set(weekFile, wSongs);
				categoryOrder.push(weekFile);
			}
		}
	}

	/**
	 * Returns all available difficulties for a song.
	 * @param song The song's name.
	 * @param mix  The song's mix.
	 */
	function availableDifficulties(song:String, mix:String):Array<Difficulty>
	{
		final available:Array<Difficulty> = [];

		for (diff in allDifficulties)
		{
			if (Paths.exists('songs/$song/$mix/chart-${diff.name}.json')) available.push(diff);
		}

		return available;
	}

	/**
	 * Gets a song list for a specific week (returns all found songs if week == 'all')
	 * @param week The week's name.
	 */
	function weekSonglist(week:String = 'all'):Array<SongBase> return (week == 'all') ? allSongs : (songsByWeek?.get(week) ?? []);

	/**
	 * Looks up a Difficulty by its internal name.
	 * @param name The difficulty's internal name (e.g. "hard", "erect")
	 */
	static function getDifficulty(name:String):Difficulty
	{
		for (diff in get().allDifficulties) if (diff.name == name) return diff;
		return null;
	}

	/**
	 * Returns all registered difficulties, sorted by `order`.
	 */
	static function getDifficultyList():Array<Difficulty> return get().allDifficulties;

	/**
	 * Returns the general file suffix for a difficulty (e.g. "-erect").
	 * @param name The difficulty's internal name
	 */
	static function getSuffix(name:String):String
	{
		final diff = getDifficulty(name);
		return diff?.suffix ?? '';
	}

	/**
	 * Returns the suffix to use for instrumental files.
	 * Falls back to the general `suffix` if `instSuffix` is not set.
	 * @param name The difficulty's internal name
	 */
	static function getInstSuffix(name:String):String
	{
		final diff = getDifficulty(name);
		if (diff?.instSuffix != null) return diff.instSuffix;
		return diff?.suffix ?? '';
	}

	/**
	 * Returns the suffix to use for voices files.
	 * Falls back to the general `suffix` if `voicesSuffix` is not set.
	 * @param name The difficulty's internal name
	 */
	static function getVoicesSuffix(name:String):String
	{
		final diff = getDifficulty(name);
		if (diff?.voicesSuffix != null) return diff.voicesSuffix;
		return diff?.suffix ?? '';
	}

	/**
	 * Returns a display name for a category (week) id.
	 */
	static function getCategoryDisplayName(id:String):String
	{
		if (id == 'all') return 'All Songs';

		final wd:Week = Week.get(id);
		if (wd != null && wd.displayName != null) return wd.displayName;

		return id;
	}
}

/**
 * A typedef containing all difficulty info.
 */
typedef Difficulty =
{
	/**
	 * Internal name used in chart files. (e.g. "hard")
	 */
	var name:String;

	/**
	 * The display name, shown in freeplay, story mode, etc.
	 */
	var displayName:String;

	/**
	 * General suffix applied to events, metadata, inst, and voices files.
	 * (e.g. "-erect" looks for `events-erect.json`, `meta-erect.json`, `Inst-erect.ogg`, etc.)
	 * 
	 * Can be overridden for specific file types using `instSuffix` / `voicesSuffix`.
	 */
	var ?suffix:String;

	/**
	 * Override suffix for instrumentals only.
	 * If null, falls back to `suffix`.
	 */
	var ?instSuffix:String;

	/**
	 * Override suffix for voices only.
	 * If null, falls back to `suffix`.
	 */
	var ?voicesSuffix:String;

	/**
	 * Color used for the UI text.
	 */
	var ?color:String;

	/**
	 * Sorting order for UI display. Lower values appear first.
	 * Defaults to 999 if unset.
	 */
	var ?order:Int;
}
