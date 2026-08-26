package moon.backend.archipelago;

import flixel.util.FlxSave;
import haxe.crypto.Md5;

/**
 * Per-server save data for an Archipelago connection.
 */
typedef ArchipelagoSaveData =
{
	/**
	 * Location IDs that have already been checked and sent.
	 */
	var checkedLocations:Array<Int>;

	/**
	 * All the seen songs.
	 */
	var seenSongs:Array<Int>;

	/**
	 * All the seen weeks.
	 */
	var seenWeeks:Array<Int>;

	/**
	 * Item IDs the client has already processed (with counts for progressive items).
	 */
	var receivedItems:Map<Int, Int>;

	/**
	 * Items that arrived but have not yet been applied.
	 */
	var pendingItems:Array<Int>;

	/** 
	 * Slot data snapshot from the last successful connect.
	 */
	var ?slotData:Dynamic;

	/**
	 * Seed name of the multiworld this save belongs to.
	 */
	var ?seed:String;
}

@:publicFields
/**
 * Handles persistence and the offline/reconnect item queue for Archipelago.
 */
class ArchipelagoSave
{
	static final SAVE_BIND:String = "moon_archipelago";
	static var save:FlxSave = new FlxSave();
	static var currentKey:String = "";
	static var data:ArchipelagoSaveData;

	static function init():Void save.bind(SAVE_BIND);

	/**
	 * Builds a stable key for a given connection target.
	 */
	static function makeKey(host:String, port:Int, slot:String):String return Md5.encode('${host.toLowerCase()}:$port:${slot.toLowerCase()}');

	/**
	 * Loads (or creates) the save for the given connection.
	 */
	static function load(host:String, port:Int, slot:String):Void
	{
		currentKey = makeKey(host, port, slot);

		if (save.data.saves == null) save.data.saves = {};

		final raw:Dynamic = Reflect.field(save.data.saves, currentKey);
		if (raw != null)
		{
			data = {
				checkedLocations: cast raw.checkedLocations ?? [],
				seenSongs: cast raw.seenSongs ?? [],
				seenWeeks: cast raw.seenWeeks ?? [],
				receivedItems: raw.receivedItems != null ? mapFromDynamic(raw.receivedItems) : new Map(),
				pendingItems: cast raw.pendingItems ?? [],
				slotData: raw.slotData,
				seed: raw.seed
			};
		}
		else
		{
			data = {
				checkedLocations: [],
				seenSongs: [],
				seenWeeks: [],
				receivedItems: new Map(),
				pendingItems: [],
				slotData: null,
				seed: null
			};
		}
	}

	/**
	 * Writes the current in-memory data back to disk.
	 */
	static function flush():Void
	{
		if (currentKey == "" || data == null) return;

		if (save.data.saves == null) save.data.saves = {};

		Reflect.setField(save.data.saves, currentKey, {
			checkedLocations: data.checkedLocations,
			seenSongs: data.seenSongs,
			seenWeeks: data.seenWeeks,
			receivedItems: mapToDynamic(data.receivedItems),
			pendingItems: data.pendingItems,
			slotData: data.slotData,
			seed: data.seed
		});

		save.flush();
	}

	/**
	 * Marks a location as checked and persists.
	 */
	static function markLocationChecked(id:Int):Void
	{
		if (data == null) return;
		if (data.checkedLocations.indexOf(id) == -1) data.checkedLocations.push(id);
		flush();
	}

	/**
	 * Returns true if the location was already checked according to our save.
	 */
	static function isLocationChecked(id:Int):Bool return data != null && data.checkedLocations.indexOf(id) != -1;

	static function isSongSeen(index:Int):Bool return data != null && data.seenSongs.indexOf(index) != -1;

	static function isWeekSeen(index:Int):Bool return data != null && data.seenWeeks.indexOf(index) != -1;

	static function markSongSeen(index:Int):Void
	{
		if (data == null || data.seenSongs.indexOf(index) != -1) return;
		data.seenSongs.push(index);
		flush();
	}

	static function markWeekSeen(index:Int):Void
	{
		if (data == null || data.seenWeeks.indexOf(index) != -1) return;
		data.seenWeeks.push(index);
		flush();
	}

	/**
	 * Records that an item has been received and queues it for application.
	 * Returns true if this is a newly seen item instance that should be applied.
	 */
	static function enqueueItem(itemId:Int):Bool
	{
		if (data == null) return false;

		final prev = data.receivedItems.exists(itemId) ? data.receivedItems.get(itemId) : 0;
		data.receivedItems.set(itemId, prev + 1);
		data.pendingItems.push(itemId);
		flush();
		return true;
	}

	/**
	 * Pops the next pending item.
	 */
	static function dequeueItem():Null<Int>
	{
		if (data == null || data.pendingItems.length == 0) return null;
		final id = data.pendingItems.shift();
		flush();
		return id;
	}

	/**
	 * How many items are waiting to be applied.
	 */
	static function pendingCount():Int return data != null ? data.pendingItems.length : 0;

	/**
	 * Clears the pending queue without applying.
	 */
	static function clearPending():Void
	{
		if (data == null) return;
		data.pendingItems = [];
		flush();
	}

	// ------ le cool helpers ----------------------------------------------------------

	static function mapFromDynamic(raw:Dynamic):Map<Int, Int>
	{
		final map = new Map<Int, Int>();
		for (key in Reflect.fields(raw)) map.set(Std.parseInt(key), Reflect.field(raw, key));
		return map;
	}

	static function mapToDynamic(map:Map<Int, Int>):Dynamic
	{
		final obj:Dynamic = {};
		for (key => value in map) Reflect.setField(obj, Std.string(key), value);
		return obj;
	}
}
