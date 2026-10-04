package moon.backend.archipelago;

/**
 * Network item delivered by ReceivedItems / LocationInfo.
 */
typedef APNetworkItem =
{
	var item:Int;
	var location:Int;
	var player:Int;
	var flags:Int;
}

/**
 * Connection state of the current AP client.
 */
enum abstract APState(Int) from Int to Int
{
	var DISCONNECTED = 0;
	var CONNECTING = 1;
	var ROOM_INFO = 2;
	var SLOT_CONNECTED = 3;
}
