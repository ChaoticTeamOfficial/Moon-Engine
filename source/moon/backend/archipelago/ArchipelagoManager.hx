package moon.backend.archipelago;

import moon.backend.archipelago.APTypes.APState;
import moon.backend.archipelago.APTypes.APNetworkItem;
import haxe.crypto.Md5;

/**
 * Central owner of the archipelago client.
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
	static final onItemsReceived = new FlxTypedSignal<Array<APNetworkItem>->Void>();

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

	/**
	 * The current loaded client.
	 */
	static var client:APClient;

	static var host:String = "";
	static var port:Int = 38281;
	static var slot:String = "";
	static var password:String = "";
	static var slotData:Dynamic;

	/**
	 * Whether the current client is connected to an archipelago server.
	 */
	static var isConnected(get, never):Bool;

	static function get_isConnected():Bool return client != null && client.state == APState.SLOT_CONNECTED;

	static var initialized:Bool = false;
	static var pendingClearIndex:Int = 0;
	static var pendingClearIsWeek:Bool = false;

	/**
	 * Unix time of the last DeathLink we sent
	 */
	static var lastDeathLinkTime:Float = 0;

	/**
	 * Pending remote DeathLink payload.
	 */
	static var pendingRemoteDeath:Dynamic = null;

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

		final uuid = Md5.encode('${Sys.systemName()}-${Date.now().getTime()}-${Math.random()}');

		if (client != null)
		{
			client.disconnect();
			client = null;
		}

		client = new APClient(uuid, GAME_NAME);
		wireCallbacks();
		client.connect(host, port, slot, password);

		trace('[AP] Connecting to $host:$port as "$slot"...', "INFO");
	}

	/**
	 * Gracefully disconnects and stops polling.
	 */
	static function disconnect():Void
	{
		if (client == null) return;

		client.disconnect();
		client = null;
		slotData = null;
		onDisconnected.dispatch();
		trace('[AP] Disconnected.', "INFO");
	}

	/**
	 * Must be called every frame while a client exists.
	 */
	static function update():Void
	{
		if (client != null) client.poll();

		if (pendingRemoteDeath != null)
		{
			final data = pendingRemoteDeath;
			pendingRemoteDeath = null;
			applyRemoteDeathLink(data);
		}
	}

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

		if (fresh.length > 0) client.locationChecks(fresh);
	}

	/**
	 * Convenience for a single location.
	 */
	static function checkLocation(id:Int):Void checkLocations([id]);

	/**
	 * True when this client is participating in DeathLink.
	 */
	static function isDeathLinkEnabled():Bool
	{
		if (client != null)
		{
			for (t in client.tags) if (t == "DeathLink") return true;
		}
		if (slotData == null) return false;
		final v:Dynamic = slotData.death_link;
		return v == true || v == 1;
	}

	/**
	 * Sends a DeathLink Bounce (no-op if Death Link is off or not connected).
	 */
	static function sendDeathLink(cause:String = "died"):Void
	{
		if (client == null || !isConnected) return;
		if (!isDeathLinkEnabled())
		{
			trace('[AP] DeathLink send skipped (not enabled).', "WARNING");
			return;
		}

		final now = Date.now().getTime() / 1000;
		lastDeathLinkTime = now;
		try
		{
			if (client.bounce({
				source: slot,
				cause: cause,
				time: now
			}, null, null, ["DeathLink"])) trace('[AP] DeathLink sent ($cause).', "INFO");
			else
				trace('[AP] DeathLink Bounce failed to queue.', "WARNING");
		}
		catch (e:Dynamic)
		{
			trace('[AP] DeathLink Bounce threw: $e', "ERROR");
		}
	}

	/**
	 * Queue a remote DeathLink for the next update tick.
	 */
	static function queueRemoteDeathLink(data:Dynamic):Void
	{
		if (data == null) return;

		final source:String = (data.source != null) ? Std.string(data.source) : "";
		if (source != "" && source.toLowerCase() == slot.toLowerCase()) return;

		if (data.time != null)
		{
			final t:Float = Std.parseFloat(Std.string(data.time));
			if (!Math.isNaN(t) && Math.abs(t - lastDeathLinkTime) < 0.5) return;
		}

		pendingRemoteDeath = data;
	}

	/**
	 * Force a local game-over from a remote DeathLink (if currently in PlayState).
	 */
	static function applyRemoteDeathLink(data:Dynamic):Void
	{
		final ps = moon.game.PlayState.instance;
		if (ps == null || ps.isDead) return;

		try
		{
			if (ps.subState != null) ps.subState.close();
			ps.triggerGameOver(false);

			final source:String = (data != null && data.source != null) ? Std.string(data.source) : "?";
			final cause:String = (data != null && data.cause != null) ? Std.string(data.cause) : "DeathLink";
			trace('[AP] DeathLink from $source ($cause).', "INFO");
		}
		catch (e:Dynamic)
		{
			trace('[AP] applyRemoteDeathLink failed: $e', "ERROR");
		}
	}

	/**
	 * Pops and returns the next pending item ID.
	 */
	static function nextPendingItem():Null<Int> return ArchipelagoSave.dequeueItem();

	/**
	 * How many items are still waiting to be applied.
	 */
	static function pendingItemCount():Int return ArchipelagoSave.pendingCount();

	static function wireCallbacks():Void
	{
		client.onRoomInfo = () -> {
			// TODO ig lol
		};

		client.onConnected = (data:Dynamic) ->
		{
			slotData = data;
			if (ArchipelagoSave.data != null)
			{
				ArchipelagoSave.data.slotData = data;
				ArchipelagoSave.data.seed = client.seed;
				ArchipelagoSave.flush();
			}

			client.connectUpdate(null, ["DeathLink", "AP"]);
			if (ArchipelagoSave.data != null && ArchipelagoSave.data.checkedLocations.length > 0) client.locationChecks(ArchipelagoSave.data.checkedLocations);

			trace('[AP] Connected to slot "${client.slot}" (seed ${client.seed}, tags ${client.tags.join(",")}).', "INFO");
			onConnected.dispatch();
		};

		client.onConnectionRefused = (errors:Array<String>) ->
		{
			trace('[AP] Slot refused: ${errors.join(", ")}', "ERROR");
			disconnect();
		};

		client.onDisconnected = () ->
		{
			trace('[AP] Socket disconnected.', "WARNING");
			onDisconnected.dispatch();
		};

		client.onError = (msg:String) ->
		{
			trace('[AP] Socket error: $msg', "WARNING");
		};

		client.onItemsReceived = (items:Array<APNetworkItem>) ->
		{
			for (item in items) ArchipelagoSave.enqueueItem(item.item);

			onItemsReceived.dispatch(items);
		};

		client.onLocationsChecked = (ids:Array<Int>) ->
		{
			for (id in ids) ArchipelagoSave.markLocationChecked(id);

			onLocationsChecked.dispatch(ids);
		};

		client.onBounced = (data:Dynamic) ->
		{
			queueRemoteDeathLink(data);
			onBounced.dispatch(data);
		};

		client.onPrintJSON = (parts:Array<Dynamic>) ->
		{
			onPrintJSON.dispatch(parts);
		};
	}
}
