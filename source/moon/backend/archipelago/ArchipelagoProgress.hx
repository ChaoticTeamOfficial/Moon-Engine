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
	static final TRAP_HEALTH_DRAIN:Int = 9100;
	static final TRAP_AD_VIDEO:Int = 9101;
	static final TRAP_DROP_HP:Int = 9102;
	///////////////////////////////////////////////////////////////////////////////////
	static final HEALTH_DRAIN_RATE:Float = 5;
	static final HEALTH_DRAIN_DURATION:Float = 40.0;

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

	/**
	 * Trap item IDs waiting to be applied during gameplay.
	 */
	static var pendingTraps:Array<Int> = [];

	/**
	 * Remaining seconds of active Health Drain effect.
	 */
	static var healthDrainRemaining:Float = 0;

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
			autoCheckSoftlocks();
		});
	}

	/**
	 * How many song clear locations the seed was generated with.
	 */
	static function generatedSongCount():Int
	{
		final sd = ArchipelagoManager.slotData;
		if (sd == null || sd.song_clear_count == null) return songPool.length;
		final n:Int = Std.int(sd.song_clear_count);
		return n > 0 ? n : songPool.length;
	}

	/**
	 * How many week clear locations the seed was generated with.
	 */
	static function generatedWeekCount():Int
	{
		final sd = ArchipelagoManager.slotData;
		if (sd == null || sd.week_clear_count == null) return 0;
		final n:Int = Std.int(sd.week_clear_count);
		return n > 0 ? n : 0;
	}

	/**
	 * Playable song slots.
	 */
	static function effectiveSongCount():Int
	{
		final gen = generatedSongCount();
		final installed = songPool.length;
		if (gen <= 0) return installed;
		return Std.int(Math.min(gen, installed));
	}

	/**
	 * Playable week slots.
	 */
	static function effectiveWeekCount():Int
	{
		final gen = generatedWeekCount();
		if (gen <= 0) return 0;
		return Std.int(Math.min(gen, weekPool.length));
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

		if (ArchipelagoManager.isConnected) autoCheckSoftlocks();
	}

	static function autoCheckSoftlocks():Void
	{
		if (!ArchipelagoManager.isConnected) return;

		final genSongs = generatedSongCount();
		final genWeeks = generatedWeekCount();

		final extra:Array<Int> = [];

		if (genSongs > songPool.length && songPool.length >= 0)
		{
			for (i in (songPool.length + 1)...(genSongs + 1))
			{
				final locId = songClearLocationId(i);
				if (!ArchipelagoSave.isLocationChecked(locId)) extra.push(locId);
			}
		}

		if (genWeeks > weekPool.length && weekPool.length >= 0)
		{
			for (i in (weekPool.length + 1)...(genWeeks + 1))
			{
				final locId = weekClearLocationId(i);
				if (!ArchipelagoSave.isLocationChecked(locId)) extra.push(locId);
			}
		}

		if (extra.length > 0)
		{
			ArchipelagoManager.checkLocations(extra);
			trace('[AP] Auto-checked ${extra.length} unreachable location(s).', "INFO");
		}
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
			final names = ["Easy", "Normal", "Hard", "Erect"];
			final idx = itemId - DIFFICULTY_UNLOCK_BASE;
			if (idx >= 0 && idx < names.length) unlockedDifficulties.set(names[idx].toLowerCase(), true);
			return;
		}

		// TODO: clean these up.
		if (itemId == TRAP_HEALTH_DRAIN || itemId == TRAP_AD_VIDEO || itemId == TRAP_DROP_HP)
		{
			pendingTraps.push(itemId);
			trace('[AP] Queued trap ${trapName(itemId)}.', "INFO");
			tryApplyTraps();
		}
	}

	static function trapName(id:Int):String
	{
		return switch (id)
		{
			case TRAP_HEALTH_DRAIN:
				"Health Drain";
			case TRAP_AD_VIDEO:
				"AD Video";
			case TRAP_DROP_HP:
				"Drop HP to 1";
			default:
				'Trap#$id';
		}
	}

	/**
	 * Apply any queued traps if the player is currently in an active PlayState.
	 */
	static function tryApplyTraps():Void
	{
		final ps = moon.game.PlayState.instance;
		if (ps == null || ps.isDead) return;
		if (ps.playField == null) return;

		while (pendingTraps.length > 0)
		{
			final id = pendingTraps.shift();
			switch (id)
			{
				case TRAP_HEALTH_DRAIN:
					healthDrainRemaining = Math.max(healthDrainRemaining, 0) + HEALTH_DRAIN_DURATION;
					trace('[AP] Health Drain active for ${healthDrainRemaining}s.', "INFO");

				case TRAP_DROP_HP:
					ps.triggerDropHpTrap();
					trace('[AP] Drop HP to 1 applied.', "INFO");

				case TRAP_AD_VIDEO:
					ps.triggerVideoTrap();
					trace('[AP] AD Video trap triggered.', "INFO");
					return;

				default:
			}
		}
	}

	/**
	 * Updates ongoing trap effects.
	 */
	static function updateTraps(elapsed:Float):Void
	{
		final ps = moon.game.PlayState.instance;
		if (ps == null || ps.isDead || ps.paused) return;

		if (pendingTraps.length > 0) tryApplyTraps();

		if (healthDrainRemaining > 0)
		{
			healthDrainRemaining -= elapsed;
			ps.triggerHealthDrain(HEALTH_DRAIN_RATE * elapsed);
			if (healthDrainRemaining <= 0)
			{
				healthDrainRemaining = 0;
				trace('[AP] Health Drain ended.', "INFO");
			}
		}
	}

	static function resetSongTrapState():Void
	{
		// TODO... uhh... :P
		healthDrainRemaining = 0;
	}

	// ---- queries!!!!!!!!! ----------------------------------------------------------

	static function isSongUnlocked(index:Int):Bool
	{
		if (index < 1 || index > effectiveSongCount()) return false;
		return unlockedSongs.exists(index) && unlockedSongs.get(index);
	}

	static function isWeekUnlocked(index:Int):Bool
	{
		if (index < 1 || index > effectiveWeekCount()) return false;
		return unlockedWeeks.exists(index) && unlockedWeeks.get(index);
	}

	static function isDifficultyUnlocked(name:String):Bool
	{
		final sd = ArchipelagoManager.slotData;
		if (sd == null || !sd.unlockable_difficulties) return true;

		final key = name.toLowerCase();
		if (unlockedDifficulties.exists(key) && unlockedDifficulties.get(key)) return true;

		if (!hasDiffUnlock()) return key == "hard" || key == "normal" || key == "easy";

		return false;
	}

	static function hasDiffUnlock():Bool
	{
		for (_ in unlockedDifficulties) return true;
		return false;
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
			if (!isSongUnlocked(index)) continue;
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
			if (!on || !isSongUnlocked(index)) continue;
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
			if (!on || !isWeekUnlocked(index)) continue;
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
		final max = effectiveSongCount();
		for (index => on in unlockedSongs) if (on && index >= 1 && index <= max) n++;
		return n;
	}

	static function weekUnlockCount():Int
	{
		var n = 0;
		final max = effectiveWeekCount();
		for (index => on in unlockedWeeks) if (on && index >= 1 && index <= max) n++;
		return n;
	}

	/**
	 * Called when the player successfully clears a song.
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

		final gen = generatedSongCount();
		if (index > gen)
		{
			trace('[AP] Song clear index ${index} exceeds generated count ${gen}, skipping.', "WARNING");
			ArchipelagoManager.pendingClearIndex = 0;
			ArchipelagoManager.pendingClearIsWeek = false;
			return;
		}

		final locId = songClearLocationId(index);
		ArchipelagoManager.checkLocation(locId);
		trace('[AP] Checked location Song Clear ${index} (id ${locId}) for "${songName}".', "INFO");

		ArchipelagoManager.pendingClearIndex = 0;
		ArchipelagoManager.pendingClearIsWeek = false;

		autoCheckSoftlocks();
	}

	/**
	 * Called when the player successfully clears a week.
	 */
	static function reportWeekClear():Void
	{
		if (!ArchipelagoManager.isConnected) return;

		final index = ArchipelagoManager.pendingClearIndex;
		if (index <= 0)
		{
			trace('[AP] No clear index for week, skipping location check.', "WARNING");
			return;
		}

		final gen = generatedWeekCount();
		if (index > gen)
		{
			trace('[AP] Week clear index ${index} exceeds generated count ${gen}, skipping.', "WARNING");
			ArchipelagoManager.pendingClearIndex = 0;
			ArchipelagoManager.pendingClearIsWeek = false;
			return;
		}

		final locId = weekClearLocationId(index);
		ArchipelagoManager.checkLocation(locId);
		trace('[AP] Checked location Week Clear ${index} (id ${locId}).', "INFO");

		ArchipelagoManager.pendingClearIndex = 0;
		ArchipelagoManager.pendingClearIsWeek = false;

		autoCheckSoftlocks();
	}

	static function isSongNew(index:Int):Bool return isSongUnlocked(index) && !ArchipelagoSave.isSongSeen(index);

	static function isWeekNew(index:Int):Bool return isWeekUnlocked(index) && !ArchipelagoSave.isWeekSeen(index);
}
