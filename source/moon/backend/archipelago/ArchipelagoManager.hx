package moon.backend.archipelago;

import ap.Client;
import ap.Definitions.State;
import ap.PacketTypes.NetworkItem;
import flixel.FlxG;
import flixel.util.FlxSignal;
import haxe.crypto.Md5;

/**
 * Central owner of the hxArchipelago client.
 */
@:publicFields
class ArchipelagoManager
{
	static final GAME_NAME:String = "Moon Engine";

	/**
	 * Fired once the slot is successfully authenticated.
	 */
	static final onConnected = new FlxSignal();

	/**
	 * Fired when the socket drops or the slot is refused.
	 */
	static final onDisconnected = new FlxSignal();

	/**
	 * Fired for every batch of items that arrives (including on reconnect).
	 */
	static final onItemsReceived = new FlxTypedSignal<Array<NetworkItem>->Void>();

	/**
	 * Fired when the server confirms locations were checked (local or remote).
	 */
	static final onLocationsChecked = new FlxTypedSignal<Array<Int>->Void>();

	/** 
	 * Fired for DeathLink / other Bounce packets.
	 */
	static final onBounced = new FlxTypedSignal<Dynamic->Void>();

	/**
	 * Fired for colourful chat server messages.
	 */
	static final onPrintJSON = new FlxTypedSignal<Array<Dynamic>->Void>();

	static var client:Client;
	static var host:String = "";
	static var port:Int = 38281;
	static var slot:String = "";
	static var password:String = "";
	static var slotData:Dynamic;
	static var isConnected(get, never):Bool;

	static function get_isConnected():Bool return client != null && client.state == State.SLOT_CONNECTED;

	static var initialized:Bool = false;
	static var pendingClearIndex:Int = 0;
	static var pendingClearIsWeek:Bool = false;

	/** When true, local death will not be broadcast (set when killed by remote DeathLink). */
	static var ignoreNextDeathLink:Bool = false;

	static function init():Void
	{
		if (initialized) return;
		initialized = true;

		ArchipelagoSave.init();

		FlxG.signals.preUpdate.add(update);
	}

	/**
	 * Starts a connection attempt.
	 */
	static function connect(host:String, port:Int, slot:String, password:String = ""):Void
	{
		ArchipelagoManager.host = host;
		ArchipelagoManager.port = port;
		ArchipelagoManager.slot = slot;
		ArchipelagoManager.password = password;

		ArchipelagoSave.load(host, port, slot);

		final uri = '${host}:$port';
		final uuid = Md5.encode('${Sys.systemName()}-${Date.now().getTime()}-${Math.random()}');

		if (client != null) client = null;

		client = new Client(uuid, GAME_NAME, uri);
		wireCallbacks();

		trace('[AP] Connecting to $uri as "$slot"...', "INFO");
	}

	/**
	 * Gracefully disconnects and stops polling.
	 */
	static function disconnect():Void
	{
		if (client == null) return;

		client = null;
		slotData = null;
		onDisconnected.dispatch();
		trace('[AP] Disconnected.', "INFO");
	}

	/**
	 * Must be called every frame while a client exists.
	 */
	static function update():Void if (client != null) client.poll();

	/**
	 * Sends one or more location checks. Already-checked IDs are filtered out.
	 */
	static function checkLocations(ids:Array<Int>):Void
	{
		if (client == null || ids.length == 0) return;

		final fresh:Array<Int> = [];
		for (id in ids)
		{
			if (!ArchipelagoSave.isLocationChecked(id))
			{
				fresh.push(id);
				ArchipelagoSave.markLocationChecked(id);
			}
		}

		if (fresh.length > 0) client.LocationChecks(fresh);
	}

	/**
	 * Convenience for a single location.
	 */
	static function checkLocation(id:Int):Void checkLocations([id]);

	/**
	 * Sends a DeathLink Bounce.
	 */
	static function isDeathLinkEnabled():Bool
	{
		if (slotData == null) return false;
		final v:Dynamic = slotData.death_link;
		return v == true || v == 1;
	}

	/**
	 * Sends a DeathLink Bounce (no-op if Death Link is off or not connected).
	 */
	static function sendDeathLink(cause:String = "died"):Void
	{
		if (client == null || !isConnected || !isDeathLinkEnabled()) return;
		if (ignoreNextDeathLink)
		{
			ignoreNextDeathLink = false;
			return;
		}

		if (client.Bounce({
			source: slot,
			cause: cause,
			time: Date.now().getTime() / 1000
		}, [], [], ["DeathLink"])) trace('[AP] DeathLink sent ($cause).', "INFO");
	}

	/**
	 * Force a local game-over from a remote DeathLink (if currently in PlayState).
	 */
	static function applyRemoteDeathLink(data:Dynamic):Void
	{
		trace('pass deathlink enabled');
		if (!isDeathLinkEnabled()) return;

		trace('pass source check');
		final source:String = (data != null && data.source != null) ? Std.string(data.source) : "";
		if (source != "" && source.toLowerCase() == slot.toLowerCase()) return;

		trace('now the rest.');
		final ps = moon.game.PlayState.instance;
		if (ps == null || ps.isDead) return;

		if (ps.subState != null) ps.subState.close();
		ps.paused = false;

		ignoreNextDeathLink = true;
		ps.isDead = true;
		if (ps.playField != null && ps.playField.playback != null) ps.playField.playback.state = PAUSE;
		ps.openSubState(new moon.game.submenus.Gameover());

		final cause = (data != null && data.cause != null) ? Std.string(data.cause) : "DeathLink";
		trace('[AP] DeathLink from $source ($cause).', "INFO");
	}

	/**
	 * Pops and returns the next pending item ID.
	 */
	static function nextPendingItem():Null<Int> return ArchipelagoSave.dequeueItem();

	/**
	 * How many items are still waiting to be applied.
	 */
	static function pendingItemCount():Int return ArchipelagoSave.pendingCount();

	// --- internal stuff!!! ---------------------------------------------------------

	static function wireCallbacks():Void
	{
		client.onRoomInfo.add(() ->
		{
			client.ConnectSlot(slot, password == "" ? null : password, 7, ["DeathLink", "AP"], {
				major: 0,
				minor: 5,
				build: 1
			});
		});

		client.onSlotConnected.add((data:Dynamic) ->
		{
			slotData = data;
			if (ArchipelagoSave.data != null)
			{
				ArchipelagoSave.data.slotData = data;
				ArchipelagoSave.data.seed = client.seed;
				ArchipelagoSave.flush();
			}

			if (ArchipelagoSave.data != null && ArchipelagoSave.data.checkedLocations.length > 0) client.LocationChecks(ArchipelagoSave.data.checkedLocations);

			trace('[AP] Connected to slot "${client.slot}" (seed ${client.seed}).', "INFO");
			onConnected.dispatch();
		});

		client.onSlotRefused.add((errors:Array<String>) ->
		{
			trace('[AP] Slot refused: ${errors.join(", ")}', "ERROR");
			disconnect();
		});

		client.onSocketDisconnected.add(() ->
		{
			trace('[AP] Socket disconnected.', "WARNING");
			onDisconnected.dispatch();
		});

		client.onSocketError.add((msg:String) ->
		{
			trace('[AP] Socket error: $msg', "WARNING");
		});

		client.onItemsReceived.add((items:Array<NetworkItem>) ->
		{
			for (item in items) ArchipelagoSave.enqueueItem(item.item);

			onItemsReceived.dispatch(items);
		});

		client.onLocationChecked.add((ids:Array<Int>) ->
		{
			for (id in ids) ArchipelagoSave.markLocationChecked(id);

			onLocationsChecked.dispatch(ids);
		});

		client.onBounced.add((data:Dynamic) ->
		{
			applyRemoteDeathLink(data);
			onBounced.dispatch(data);
		});

		client.onPrintJSON.add((parts, _item, _receiving) ->
		{
			onPrintJSON.dispatch(parts);
		});
	}
}
