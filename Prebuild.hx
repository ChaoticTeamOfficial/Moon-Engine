package;

import sys.io.File;

/**
 * A script which executes before the game is built.
 * Originally Made by Funkin' Crew.
 */
class Prebuild
{
	static inline final BUILD_TIME_FILE:String = '.build_time';
	public static var compileMsgs:Array<String> = [
		"We love legacy mods. VS Hex my beloved <3...",
		"yo nene",
		"dih",
		"I'm writing this at 12:30 PM, I'm hungry.",
		"Hello, World!",
		"Don't forget to drink some water!",
		"Why do we brainstorm with ideas only when we're not working?",
		"I bet you have some awesome ideas stored in.",
		"Also try Doido Engine!",
		"Also try TechNotDrip Engine!",
		"Also try WTF Engine!",
		"Kade engine"
	];

	static function main():Void
	{
		saveBuildTime();
		traceMessage();
	}

	public static function traceMessage():Void
	{
		final message = compileMsgs[Std.random(compileMsgs.length)];
		Sys.println('\x1b[36m[INFO] Today\'s message: $message\x1b[0m');
	}

	static function saveBuildTime():Void
	{
		var fo:sys.io.FileOutput = File.write(BUILD_TIME_FILE);
		var now:Float = Sys.time();
		fo.writeDouble(now);
		fo.close();
	}
}
