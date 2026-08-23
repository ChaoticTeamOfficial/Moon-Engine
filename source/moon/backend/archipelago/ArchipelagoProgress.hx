package moon.backend.archipelago;

import moon.backend.data.SongLibrary;
import moon.backend.data.SongBase;
import moon.backend.data.Week;

/**
 * Tracks which abstract AP unlocks the player has and maps them
 * onto real songs/weeks.
 */
@:publicFields
class ArchipelagoProgress
{
	static final SONG_UNLOCK_BASE:Int = 1000;
	static final WEEK_UNLOCK_BASE:Int = 2000;
	static final DIFFICULTY_UNLOCK_BASE:Int = 3000;
	// Location IDs
	static final SONG_CLEAR_BASE:Int = 10000;
	static final WEEK_CLEAR_BASE:Int = 20000;

	/**
	 * Sorted unique song names available in the library.
	 */
	static var songPool:Array<String> = [];

	/**
	 * Week ids (excluding "all"), in categoryOrder.
	 */
	static var weekPool:Array<String> = [];

	/**
	 * Song unlock indices the player owns (1-based).
	 */
	static var unlockedSongs:Map<Int, Bool> = new Map();

	/**
	 * Week unlock indices the player owns (1-based).
	 */
	static var unlockedWeeks:Map<Int, Bool> = new Map();

	/**
	 * Difficulty names unlocked when unlockable_difficulties is on.
	 */
	static var unlockedDifficulties:Map<String, Bool> = new Map();

	static var initialized:Bool = false;

	static function init():Void
	{
		if (initialized) return;
		initialized = true;

		rebuildPools();

		ArchipelagoManager.onItemsReceived.add(onItems);
		ArchipelagoManager.onConnected.add(() ->
		{
			rebuildPools();
			drainPending();
		});
	}

	/**
	 * Rebuild song/week pools from the current SongLibrary.
	 */
	static function rebuildPools():Void
	{
		final lib = SongLibrary.get();
		final seen = new Map<String, Bool>();
		songPool = [];

		for (entry in lib.allSongs)
		{
			final key = entry.song.toLowerCase();
			if (!seen.exists(key))
			{
				seen.set(key, true);
				songPool.push(entry.song);
			}
		}
		songPool.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));

		weekPool = [];
		for (id in lib.categoryOrder) if (id != "all") weekPool.push(id);
	}

	static function onItems(items:Array<ap.PacketTypes.NetworkItem>):Void drainPending();

	/**
	 * Apply every pending item from the save queue.
	 */
	static function drainPending():Void
	{
		while (true)
		{
			final id = ArchipelagoManager.nextPendingItem();
			if (id == null) break;
			applyItem(id);
		}
	}

	static function applyItem(itemId:Int):Void
	{
		if (itemId > SONG_UNLOCK_BASE && itemId < WEEK_UNLOCK_BASE)
		{
			unlockedSongs.set(itemId - SONG_UNLOCK_BASE, true);
			return;
		}
		if (itemId > WEEK_UNLOCK_BASE && itemId < DIFFICULTY_UNLOCK_BASE)
		{
			unlockedWeeks.set(itemId - WEEK_UNLOCK_BASE, true);
			return;
		}
		if (itemId >= DIFFICULTY_UNLOCK_BASE && itemId < 9000)
		{
			final names = [
				"Easy",
				"Normal",
				"Hard",
				"Erect",
				"Nightmare"
			];
			final idx = itemId - DIFFICULTY_UNLOCK_BASE;
			if (idx >= 0 && idx < names.length) unlockedDifficulties.set(names[idx].toLowerCase(), true);
		}
	}

	// ---- queries!!!!!!!!! ----------------------------------------------------------

	static function isSongUnlocked(index:Int):Bool return unlockedSongs.exists(index) && unlockedSongs.get(index);

	static function isWeekUnlocked(index:Int):Bool return unlockedWeeks.exists(index) && unlockedWeeks.get(index);

	static function isDifficultyUnlocked(name:String):Bool
	{
		// If the option is off, everything is unlocked!
		final sd = ArchipelagoManager.slotData;
		if (sd == null || !sd.unlockable_difficulties) return true;
		return unlockedDifficulties.exists(name.toLowerCase()) && unlockedDifficulties.get(name.toLowerCase());
	}

	/**
	 * Song name for abstract index (1-based), or null if out of range.
	 */
	static function songNameForIndex(index:Int):Null<String>
	{
		if (index < 1 || index > songPool.length) return null;
		return songPool[index - 1];
	}

	/**
	 * Week id for abstract index (1-based), or null if out of range.
	 */
	static function weekIdForIndex(index:Int):Null<String>
	{
		if (index < 1 || index > weekPool.length) return null;
		return weekPool[index - 1];
	}

	/**
	 * Index (1-based) for a song name, or 0 if not in pool.
	 */
	static function indexForSong(name:String):Int
	{
		final lower = name.toLowerCase();
		for (i in 0...songPool.length) if (songPool[i].toLowerCase() == lower) return i + 1;
		return 0;
	}

	/**
	 * All SongBase entries for unlocked songs.
	 */
	static function unlockedSongEntries():Array<SongBase>
	{
		final lib = SongLibrary.get();
		final result:Array<SongBase> = [];
		final added = new Map<String, Bool>();

		for (index => _ in unlockedSongs)
		{
			final name = songNameForIndex(index);
			if (name == null) continue;

			for (entry in lib.allSongs)
			{
				if (entry.song.toLowerCase() != name.toLowerCase()) continue;
				final key = '${entry.song}|${entry.mix}|${entry.difficulty}';
				if (added.exists(key)) continue;
				added.set(key, true);
				result.push(entry);
			}
		}
		return result;
	}

	/**
	 * Unique song names that are unlocked (for song-list view).
	 */
	static function unlockedSongNames():Array<String>
	{
		final names:Array<String> = [];
		for (index => on in unlockedSongs)
		{
			if (!on) continue;
			final name = songNameForIndex(index);
			if (name != null) names.push(name);
		}
		names.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		return names;
	}

	/**
	 * Week ids that are unlocked.
	 */
	static function unlockedWeekIds():Array<String>
	{
		final ids:Array<String> = [];
		for (index => on in unlockedWeeks)
		{
			if (!on) continue;
			final id = weekIdForIndex(index);
			if (id != null) ids.push(id);
		}
		return ids;
	}

	/**
	 * Location ID to send when clearing song index (1-based).
	 */
	static function songClearLocationId(index:Int):Int return SONG_CLEAR_BASE + index;

	/**
	 * Location ID to send when clearing week index (1-based).
	 */
	static function weekClearLocationId(index:Int):Int return WEEK_CLEAR_BASE + index;

	/**
	 * How many song unlocks the player currently has.
	 */
	static function songUnlockCount():Int
	{
		var n = 0;
		for (_ in unlockedSongs) n++;
		return n;
	}

	static function weekUnlockCount():Int
	{
		var n = 0;
		for (_ in unlockedWeeks) n++;
		return n;
	}

	/**
	 * Call when the player successfully clears a song.
	 */
	static function reportSongClear(songName:String, ?difficulty:String):Void
	{
		if (!ArchipelagoManager.isConnected) return;

		var index = ArchipelagoManager.pendingClearIndex;
		if (index <= 0) index = indexForSong(songName);
		if (index <= 0)
		{
			trace('[AP] No clear index for song "${songName}", skipping location check.', "WARNING");
			return;
		}

		final locId = songClearLocationId(index);
		ArchipelagoManager.checkLocation(locId);
		trace('[AP] Checked location Song Clear ${index} (id ${locId}) for "${songName}".', "INFO");

		ArchipelagoManager.pendingClearIndex = 0;
		ArchipelagoManager.pendingClearIsWeek = false;
	}
}
