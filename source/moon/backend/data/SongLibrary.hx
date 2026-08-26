package moon.backend.data;

using StringTools;

// public fields on my life

@:publicFields
/**
 * The SongLibrary class basically handles the entire game Song List!
 * It separates weeks onto categories.
 */
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
		songsByWeek = ['all' => []];

		for (songFolder in Paths.readDir('songs/'))
		{
			for (mix in Paths.readDir('songs/$songFolder'))
			{
				if (mix == 'events') continue;

				final dir = 'songs/$songFolder/$mix/';
				final registered = new Map<String, Bool>();

				// Shared multi-diff chart.
				if (Paths.exists(dir + 'chart.json'))
				{
					final shared:Dynamic = Paths.JSON('$dir/chart');
					if (shared != null && shared.notes != null && Type.typeof(shared.notes) == TObject && !Std.isOfType(shared.notes, Array))
					{
						for (diffName in Reflect.fields(shared.notes)) pushSongEntry(songFolder, mix, diffName, registered);
					}
					else
					{
						// Legacy flat chart.json as it register every empty-suffix difficulty.
						for (diff in allDifficulties) if ((diff.suffix ?? '') == '') pushSongEntry(songFolder, mix, diff.name, registered);
					}
				}

				// Per-difficulty chart-{name} files.
				for (chartFile in Paths.readDir(
					dir,
					['.json'],
					true
				)) if (chartFile.startsWith('chart-')) pushSongEntry(songFolder, mix, chartFile.substr(6), registered);
			}
		}

		// Collect weeks then sort by order
		final weeks:Array<
			{id:String, data:Week}> = [];
		for (weekFile in Paths.readDir('data/weeks/', ['.json'], true))
		{
			final wd:Week = Week.get(weekFile);
			if (wd != null && wd.tracks != null) weeks.push({
				id: weekFile,
				data: wd
			});
		}

		weeks.sort((a, b) -> (a.data.order ?? 999) - (b.data.order ?? 999));

		final seenInWeeks = new Map<String, Bool>();

		for (w in weeks)
		{
			final wSongs:Array<SongBase> = [];

			for (track in w.data.tracks)
			{
				for (song in allSongs)
				{
					if (song.song.toLowerCase() != track.toLowerCase()) continue;

					final key = '${song.song}/${song.mix}/${song.difficulty}';
					if (seenInWeeks.exists(key)) continue;

					wSongs.push(song);
					seenInWeeks.set(key, true);
				}
			}

			songsByWeek.set(w.id, wSongs);
			categoryOrder.push(w.id);
		}

		final orderedAll:Array<SongBase> = [];
		final added = new Map<String, Bool>();

		for (w in weeks)
		{
			final list = songsByWeek.get(w.id);
			if (list == null) continue;
			for (s in list)
			{
				final key = '${s.song}/${s.mix}/${s.difficulty}';
				if (added.exists(key)) continue;
				added.set(key, true);
				orderedAll.push(s);
			}
		}

		for (song in allSongs)
		{
			final key = '${song.song}/${song.mix}/${song.difficulty}';
			if (added.exists(key)) continue;
			orderedAll.push(song);
		}

		allSongs = orderedAll;
		songsByWeek.set('all', orderedAll);
	}

	private function pushSongEntry(song:String, mix:String, difficulty:String, registered:Map<String, Bool>):Void
	{
		final key = '$song/$mix/$difficulty';
		if (registered.exists(key)) return;
		registered.set(key, true);

		final entry:SongBase = {
			song: song,
			mix: mix,
			difficulty: difficulty
		};
		allSongs.push(entry);
		songsByWeek.get('all').push(entry);
	}

	/**
	 * Returns all available difficulties for a song.
	 * @param song The song's name.
	 * @param mix  The song's mix.
	 */
	function availableDifficulties(song:String, mix:String):Array<Difficulty>
	{
		final available:Array<Difficulty> = [];
		final shared:Dynamic = Paths.exists('songs/$song/$mix/chart.json') ? Paths.JSON('songs/$song/$mix/chart') : null;

		for (diff in allDifficulties)
		{
			if (Paths.exists('songs/$song/$mix/chart-${diff.name}.json'))
			{
				available.push(diff);
				continue;
			}

			// Shared multi-diff chart
			if (shared != null && shared.notes != null)
			{
				if (Std.isOfType(shared.notes, Array) && (diff.suffix ?? '') == '') available.push(diff);
				else if (Type.typeof(shared.notes) == TObject && Reflect.hasField(shared.notes, diff.name)) available.push(diff);
			}
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
