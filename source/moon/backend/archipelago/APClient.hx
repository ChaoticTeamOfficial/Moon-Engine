package moon.backend.archipelago;

import moon.backend.archipelago.APTypes.APState;
import moon.backend.archipelago.APTypes.APNetworkItem;
import haxe.Json;
import haxe.crypto.Md5;
import hx.ws.Types;
import hx.ws.WebSocket;

@:publicFields
// TODO: document the rest xP
/**
 * The Moon Engine AP Client!
 */
class APClient
{
	/**
	 * The current state of the client.
	 */
	var state:APState = DISCONNECTED;

	/**
	 * The current seed.
	 */
	var seed:String = "";

	/**
	 * The current slot.
	 */
	var slot:String = "";

	/////
	var tags:Array<String> = [];
	var slotData:Dynamic = null;
	var uuid:String;
	var onRoomInfo:Void->Void = null;
	var onConnected:Dynamic->Void = null;
	var onConnectionRefused:Array<String>->Void = null;
	var onItemsReceived:Array<APNetworkItem>->Void = null;
	var onLocationsChecked:Array<Int>->Void = null;
	var onBounced:Dynamic->Void = null;
	var onPrintJSON:Array<Dynamic>->Void = null;
	var onDisconnected:Void->Void = null;
	var onError:String->Void = null;
	var _ws:WebSocket = null;
	var _host:String = "";
	var _port:Int = 38281;
	var _password:String = "";
	var _game:String = "Moon Engine";
	var _itemsHandling:Int = 7;
	var _wantedTags:Array<String> = ["DeathLink", "AP"];
	var _inbound:Array<Dynamic> = [];
	var _nextItemIndex:Int = 0;
	var _closedByUs:Bool = false;

	public function new(uuid:String, game:String = "Moon Engine")
	{
		this.uuid = uuid;
		this._game = game;
	}

	public function connect(host:String, port:Int, slot:String, password:String = ""):Void
	{
		disconnect();

		_host = host;
		_port = port;
		this.slot = slot;
		_password = password;
		_closedByUs = false;
		_nextItemIndex = 0;
		state = CONNECTING;
		_inbound = [];

		// TODO: changeable url (the wss:// part.)
		final url = 'wss://$host:$port';
		trace('[APClient] Connecting to $url ...');

		try
		{
			_ws = new WebSocket(url);
			_ws.onopen = onSocketOpen;
			_ws.onmessage = onSocketMessage;
			_ws.onclose = onSocketClose;
			_ws.onerror = onSocketError;
		}
		catch (e:Dynamic)
		{
			state = DISCONNECTED;
			queueEvent({
				__type: "error",
				msg: Std.string(e)
			});
		}
	}

	public function disconnect():Void
	{
		_closedByUs = true;
		if (_ws != null)
		{
			try
				_ws.close()
			catch (_:Dynamic)
			{
			}
			_ws = null;
		}
		state = DISCONNECTED;
		slotData = null;
		tags = [];
		seed = "";
		_inbound = [];
	}

	public function poll():Void
	{
		while (_inbound.length > 0)
			dispatch(_inbound.shift());
	}

	public function locationChecks(ids:Array<Int>):Void
	{
		if (state != SLOT_CONNECTED || ids == null || ids.length == 0) return;
		send([{
			cmd: "LocationChecks",
			locations: ids
		}]);
	}

	public function bounce(data:Dynamic, games:Array<String> = null, slots:Array<Int> = null, tags:Array<String> = null):Bool
	{
		if (state != SLOT_CONNECTED) return false;

		final pkt:Dynamic = {
			cmd: "Bounce",
			data: data
		};

		if (games != null) pkt.games = games;
		if (slots != null) pkt.slots = slots;
		if (tags != null) pkt.tags = tags;

		send([pkt]);
		return true;
	}

	public function connectUpdate(?itemsHandling:Null<Int>, ?tags:Array<String>):Void
	{
		if (state != SLOT_CONNECTED) return;

		final pkt:Dynamic = {
			cmd: "ConnectUpdate"
		};

		if (itemsHandling != null) pkt.items_handling = itemsHandling;
		if (tags != null)
		{
			pkt.tags = tags;
			this.tags = tags;
		}
		send([pkt]);
	}

	public function sync():Void
	{
		if (state != SLOT_CONNECTED) return;
		send([{
			cmd: "Sync"
		}]);
	}

	public function statusUpdate(status:Int):Void
	{
		if (state != SLOT_CONNECTED) return;
		send([{
			cmd: "StatusUpdate",
			status: status
		}]);
	}

	function onSocketOpen():Void
	{
		// TODO...?
	}

	function onSocketMessage(msg:MessageType):Void
	{
		switch (msg)
		{
			case StrMessage(text):
				try
				{
					final parsed:Dynamic = Json.parse(text);
					if (Std.isOfType(parsed, Array))
					{
						final arr:Array<Dynamic> = cast parsed;
						for (cmd in arr) queueEvent(cmd);
					}
					else
						queueEvent(parsed);
				}
				catch (e:Dynamic)
				{
					queueEvent({
						__type: "error",
						msg: 'JSON parse failed: $e'
					});
				}
			case BytesMessage(_):
				// afaik archipelago is json only so I thinkkk this is useless!
		}
	}

	function onSocketClose():Void queueEvent({
		__type: "closed"
	});

	function onSocketError(err:Dynamic):Void queueEvent({
		__type: "error",
		msg: Std.string(err)
	});

	function queueEvent(pkt:Dynamic):Void _inbound.push(pkt);

	function dispatch(pkt:Dynamic):Void
	{
		if (pkt.__type != null)
		{
			switch (Std.string(pkt.__type))
			{
				case "closed":
					final wasConnected = state == SLOT_CONNECTED || state == ROOM_INFO || state == CONNECTING;

					state = DISCONNECTED;
					_ws = null;

					if (!_closedByUs && wasConnected && onDisconnected != null) onDisconnected();
				case "error":
					if (onError != null) onError(Std.string(pkt.msg));
			}
			return;
		}

		final cmd:String = pkt.cmd;
		if (cmd == null) return;

		switch (cmd)
		{
			case "RoomInfo":
				handleRoomInfo(pkt);
			case "ConnectionRefused":
				handleConnectionRefused(pkt);
			case "Connected":
				handleConnected(pkt);
			case "ReceivedItems":
				handleReceivedItems(pkt);
			case "RoomUpdate":
				handleRoomUpdate(pkt);
			case "Bounced":
				handleBounced(pkt);
			case "PrintJSON":
				handlePrintJSON(pkt);
			case "InvalidPacket":
				trace('[APClient] InvalidPacket: ${pkt.type} – ${pkt.text}', "WARNING");
			default:
				// boom
		}
	}

	function handleRoomInfo(pkt:Dynamic):Void
	{
		state = ROOM_INFO;
		if (pkt.seed_name != null) seed = Std.string(pkt.seed_name);

		final version:Dynamic = {
			major: 0,
			minor: 5,
			build: 1
		};

		// gotta love using reflect cus putting "class" directly makes the compiler cry
		Reflect.setField(version, "class", "Version");

		final connectPkt:Dynamic = {
			cmd: "Connect",
			password: (_password != null && _password != "") ? _password : null,
			game: _game,
			name: slot,
			uuid: uuid,
			version: version,
			items_handling: _itemsHandling,
			tags: _wantedTags,
			slot_data: true
		};

		send([connectPkt]);

		if (onRoomInfo != null) onRoomInfo();
	}

	function handleConnectionRefused(pkt:Dynamic):Void
	{
		final errors:Array<String> = pkt.errors != null ? cast pkt.errors : ["Unknown"];
		state = DISCONNECTED;
		if (onConnectionRefused != null) onConnectionRefused(errors);
	}

	function handleConnected(pkt:Dynamic):Void
	{
		state = SLOT_CONNECTED;
		slotData = pkt.slot_data;

		//
		// if (pkt.slot != null) {}

		if (pkt.tags != null) tags = cast pkt.tags;
		else
			tags = _wantedTags.copy();

		if (pkt.checked_locations != null && onLocationsChecked != null)
		{
			final ids:Array<Int> = cast pkt.checked_locations;
			if (ids.length > 0) onLocationsChecked(ids);
		}

		if (onConnected != null) onConnected(slotData);
	}

	function handleReceivedItems(pkt:Dynamic):Void
	{
		final index:Int = pkt.index != null ? Std.int(pkt.index) : 0;
		final rawItems:Array<Dynamic> = pkt.items != null ? cast pkt.items : [];

		if (index != 0 && index != _nextItemIndex)
		{
			trace('[APClient] Item index desync (got $index, expected $_nextItemIndex) – sending Sync', "WARNING");
			sync();
		}

		if (index == 0) _nextItemIndex = 0;

		final items:Array<APNetworkItem> = [];
		for (raw in rawItems)
		{
			items.push({
				item: Std.int(raw.item),
				location: Std.int(raw.location),
				player: Std.int(raw.player),
				flags: raw.flags != null ? Std.int(raw.flags) : 0
			});
		}
		_nextItemIndex = index + items.length;

		if (items.length > 0 && onItemsReceived != null) onItemsReceived(items);
	}

	function handleRoomUpdate(pkt:Dynamic):Void
	{
		if (pkt.checked_locations != null && onLocationsChecked != null)
		{
			final ids:Array<Int> = cast pkt.checked_locations;
			if (ids.length > 0) onLocationsChecked(ids);
		}
	}

	function handleBounced(pkt:Dynamic):Void
	{
		if (onBounced != null) onBounced(pkt.data != null ? pkt.data : pkt);
	}

	function handlePrintJSON(pkt:Dynamic):Void
	{
		if (onPrintJSON != null && pkt.data != null) onPrintJSON(cast pkt.data);
	}

	function send(packets:Array<Dynamic>):Void
	{
		if (_ws == null) return;
		try
		{
			_ws.send(Json.stringify(packets));
		}
		catch (e:Dynamic)
		{
			trace('[APClient] send failed: $e', "ERROR");
		}
	}
}
