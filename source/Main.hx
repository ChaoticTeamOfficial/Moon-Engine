package;

import moon.toolkit.ChartConvert;
import flixel.FlxG;
import flixel.FlxGame;
import openfl.display.Sprite;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import lime.app.Application;
import haxe.ui.Toolkit;
#if sys
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

using StringTools;

class Main extends Sprite
{
	public static var fps:FPS;

	public function new()
	{
		super();

		#if sys
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos)
		{
			// All definitions with each lil prefix.
			final logLevels = [
				// Doing sidenotes for the colors cause theyre confusing as fuck
				"DEBUG" => {prefix: "[>]", color: "\x1b[32m"}, // Green
				"WARNING" => {prefix: "[!]", color: "\x1b[33m"}, // Yellow
				"ERROR" => {prefix: "[X]", color: "\x1b[31m"}, // Red
				"INFO" => {prefix: "[?]", color: "\x1b[36m"} // Cyan blue whatever
			];

			// Determine log level.
			final logLevel = infos != null && infos.customParams != null && infos.customParams.length > 0 ? infos.customParams[0] : "INFO";

			// Skips debug messages if debug info is disabled.
			if (logLevel == "DEBUG" && !Constants.TRACE_DEBUG_INFO)
				return;

			// Gets some details. It fallbacks to INFO if the prefix is empty.
			final levelData = logLevels.exists(logLevel) ? logLevels[logLevel] : logLevels["INFO"];
			final infoBefore = '';

			// And then displays the pretty text on the console. :D
			Sys.println('${levelData.color}${levelData.prefix} > ${v}\x1b[0m');
		};
		#end

		FlxG.fixedTimestep = false;

		#if !hl
		DiscordRPC.initialize("1297678826809200720");
		#end

		// - Init haxeui stuff - //
		Toolkit.init();
		Toolkit.theme = 'dark';
		Toolkit.autoScale = false;
		haxe.ui.focus.FocusManager.instance.autoFocus = false;

		// There's other stuffies that's initialized at MoonGame btw!
		var game = new MoonGame(Constants.GAME_WIDTH, Constants.GAME_HEIGHT, Constants.INITIAL_STATE, Constants.GAME_FRAMERATE, Constants.GAME_FRAMERATE,
			Constants.SKIP_SPLASH);
		addChild(game);

		fps = new FPS(10, 10);
		addChild(fps);

		var beta = new BetaBuild(10, 10);
		addChild(beta);
		fps.y = beta.y + beta.height + 10;

		MoonSettings.updateGlobalSettings();
		MoonSettings.updateWindow();

		Global.allowInputs = true;
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		flixel.FlxG.signals.postUpdate.add(function()
		{
			if (flixel.FlxG.keys.justPressed.F5)
			{
				moon.Global.clearScriptList();
				if (moon.game.obj.Countdown.onStart != null)
				{
					moon.game.obj.Countdown.onStart.removeAll();
				}
				flixel.FlxG.signals.preStateSwitch.addOnce(function()
				{
					AssetManager.clearUnused();
				});
				flixel.FlxG.resetState();
			}
		});

		// trace(TweenUtils.easeList);

		#if sys
		// idk who put this coconut image on the files but when I tried to delete it the game just wouldn't start.
		// words cannot describe my fucking confusion.
		// if (!Paths.exists("data/importantdata-do-not-delete.png"))
		// {
		//	Application.current.window.alert("Funkin' but at what cost...", "Put it back. Now.");
		//	Sys.exit(1);
		// }
		#end
	}

	function onCrash(e:UncaughtErrorEvent):Void
	{
		#if sys
		if (!FileSystem.exists("crash/"))
			FileSystem.createDirectory("crash/");
		#end

		var message:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");

		path = 'crash/ME_${dateNow}.txt';

		message += 'Sorry, but an error has occurred.\n\n${e.error}\n\n';

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					message += '$file (Line: $line)\n';
				default:
					#if sys
					Sys.println(stackItem);
					#end
			}
		}

		message += '\nReport this error at #playtesting-feedback\nONLY if you think this wasn\'t your mistake.';

		#if sys
		File.saveContent(path, message + "\n");
		Sys.println(message);
		Sys.println('Crash dump saved in ${Path.normalize(path)}');
		Application.current.window.alert(message, "Error!");

		Sys.exit(1);
		#end
	}
}
