package moon.dependency.user;

#if (cpp && !android)
import flixel.FlxG;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import sys.thread.Thread;

class DiscordRPC
{
	public static var presence:DiscordRichPresence;

	public static function initialize(appId:String = "1297678826809200720"):Void
	{
		trace('[DISCORD-RPC] Initializing Discord RPC...');

		final handlers:DiscordEventHandlers = new DiscordEventHandlers();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);

		Discord.Initialize(appId, cpp.RawPointer.addressOf(handlers), false, null);

		Thread.create(function():Void
		{
			while (true)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end

				Discord.RunCallbacks();
				Sys.sleep(1 / 60);
			}
		});
	}

	public static function shutdown():Void
	{
		trace('[DISCORD-RPC] Shutting down Discord RPC...');
		Discord.Shutdown();
	}

	public static var lastTime:Int = 0;

	public static function updatePresence(?icoType:RPCIconType = OG, details:String, state:String, reset:Bool = false):Void
	{
		if (reset) lastTime = Math.floor(Date.now().getTime() / 1000);

		presence.type = DiscordActivityType_Playing;
		presence.details = details;
		presence.state = state;
		presence.largeImageKey = '$icoType';
		presence.largeImageText = 'Moon Engine v.${lime.app.Application.current.meta.get("version")}';

		switch (icoType)
		{
			case AWAY:
				presence.smallImageKey = 'paused';
				presence.smallImageText = 'Paused!';
			case PLAYMODE:
				presence.smallImageKey = 'playmode';
				presence.smallImageText = 'Playing';
			case EDITOR:
				presence.smallImageKey = 'editor';
				presence.smallImageText = 'Editing';
			case OG:
				presence.smallImageKey = null;
				presence.smallImageText = null;
		}

		presence.startTimestamp = lastTime;

		final button1:DiscordButton = new DiscordButton();
		button1.label = "test1";
		button1.url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
		presence.buttons[0] = button1;

		final button2:DiscordButton = new DiscordButton();
		button2.label = "test2";
		button2.url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
		presence.buttons[1] = button2;

		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		trace('[DISCORD-RPC] Connected to user @${request[0].username} successfully.');
		presence = new DiscordRichPresence();

		updatePresence(OG, "Welcome to Moon Engine!", "Initializing...", true);
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void trace(
		'[DISCORD-RPC] Disconnected ($errorCode: $message)',
		"WARNING"
	);

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void trace('[DISCORD-RPC] Error ($errorCode: $message)', "ERROR");
}
#else
class DiscordRPC
{
	// these just exist so I dont need to do ifs for every damn call in here
	public static function initialize(appId:String = ""):Void
	{
	}

	public static function shutdown():Void
	{
	}

	public static function updatePresence(?icoType:RPCIconType = OG, details:String, state:String, reset:Bool = false):Void
	{
	}
}
#end

enum abstract RPCIconType(String)
{
	var PLAYMODE = 'iconregular';
	var OG = 'icondefault';
	var AWAY = 'iconaway';
	var EDITOR = 'iconeditor';
}
