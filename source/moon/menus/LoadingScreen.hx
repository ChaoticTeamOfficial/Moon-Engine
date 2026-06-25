package moon.menus;

import flixel.ui.FlxBar;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import haxe.CallStack;
import moon.menus.obj.*;
import moon.game.*;
import moon.game.obj.*;
import moon.game.obj.notes.*;
import moon.menus.obj.freeplay.*;

using StringTools;

class LoadingScreen extends FlxTransitionableState
{
	var preloadGrp = new FlxGroup();
	private var loadingBar:FlxBar;
	private var loadText:FlxText;
	private var loadDisplay:MoonSprite;
	var loadComplete:Bool = false;
	var loadProgress:Int = 0;
	var loadError:Dynamic = null;
	var tracker:Float = 0;
	var trackerB:Bool = false;
	var transitioning = false;
	var failed:Bool = false;

	override public function create():Void
	{
		super.create();
		Global.allowInputs = true;

		add(preloadGrp);

		var cover = new MoonSprite().makeGraphic(FlxG.width + 64, FlxG.height + 64, FlxColor.BLACK);
		add(cover);

		var scrollingArts = new ScrollingArts("images/menus/loading/arts");
		add(scrollingArts);

		loadingBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 560, 10).createFilledBar(FlxColor.fromRGB(13, 13, 16), FlxColor.WHITE);
		loadingBar.y = (FlxG.height - loadingBar.height) - 50;
		loadingBar.screenCenter(X);
		loadingBar.x += 70;
		add(loadingBar);

		loadText = new FlxText();
		loadText.setFormat(Paths.font('VHS-GOTHIC.TTF'), 22, RIGHT);
		loadText.text = 'Waiting for thread...';
		loadText.antialiasing = false;
		add(loadText);
		loadText.setPosition(loadingBar.x, loadingBar.y - loadText.height - 10);

		loadDisplay = new MoonSprite().loadGraphic(Paths.image('menus/loading/loadingCorner'));
		loadDisplay.screenCenter(X);
		loadDisplay.antialiasing = true;
		add(loadDisplay);
		loadDisplay.y = FlxG.height - loadDisplay.height;

		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = false;

		// We begin preloading here!!!
		new FlxTimer().start(0.4, function(_)
		{
			new lime.app.Future(() ->
			{
				try
				{
					loadText.text = 'Preloading song...';

					final d = PlayState.songData;
					var chart = new Chart(d.song, d.difficulty, d.mix);
					var conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);

					loadProgress = 15;
					var playback = new Song(d.song, d.mix, d.difficulty, conductor);
					playback.state = STOP;
					loadProgress = 30;

					loadText.text = 'Preloading Graphics...';
					preload(new HealthBar(chart.content.meta.opponents[0], chart.content.meta.players[0]));
					loadProgress = 40;

					final thing = ['opponent', 'p1'];

					for (i in 0...thing.length) preload(new Strumline(0, 68, chart.content?.meta?.noteskin ?? 'v-slice', false, thing[i], conductor));
					loadProgress = 50;

					var stage = new Stage(chart.content.meta.stage, conductor);

					final chartMeta = chart.content.meta;
					for (opp in chartMeta.opponents) stage.addCharTo(opp, stage.opponents);
					for (plyr in chartMeta.players) stage.addCharTo(plyr, stage.players);
					for (spct in chartMeta.spectators) stage.addCharTo(spct, stage.spectators);
					preload(stage);
					loadProgress = 70;

					loadText.text = 'Preloading Gameover...';

					if (Paths.exists(
						'characters/${chart.content.meta.players[0]}/gameover/data.json'
					)) preload(new Character(0, 0, '${chart.content.meta.players[0]}/gameover', null));
					else
						preload(new Character(0, 0, 'bf/gameover', null));

					if (Paths.exists(
						'characters/${chart.content.meta.players[0]}/gameover/gameOverSong.ogg'
					)) Paths.preloadSound('${chart.content.meta.players[0]}/gameover/gameOverSong.ogg', 'characters');
					else
						Paths.preloadSound('bf/gameover/gameOverSong.ogg', 'characters');

					loadText.text = 'Preloading events and such...';
					loadProgress = 80;

					// TODO: Preload events stuff.

					loadProgress = 90;
					loadText.text = 'Preloading scripts...';
					Global.scriptCall('onPreload', [this]);

					AssetManager.skipNextCleanup = true;
					Global.clearScriptList();

					loadText.text = 'Done! Press ACCEPT to continue.';
					loadProgress = 102;
					loadComplete = true;

					FlxTween.tween(loadText, {
						alpha: 0.5
					}, 1, {
						ease: FlxEase.quadInOut,
						type: PINGPONG
					});
				}
				catch (e:Dynamic)
				{
					loadError = Std.string(e) + "\n\n STACK TRACE \n" + CallStack.toString(CallStack.exceptionStack());
					trace('Crash on the loading screen!\n$loadError', "ERROR");

					failed = true;
					loadText.text = 'An error occurred. Press BACK.';
					loadText.color = FlxColor.RED;
				}

				// shit lmao
				null;
			}, true);
		});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		SongPreview.update(elapsed);

		if (loadingBar != null) loadingBar.value = FlxMath.lerp(loadingBar.value, loadProgress, elapsed * 6);

		tracker += elapsed;
		if (tracker >= 0.6)
		{
			tracker = 0;
			trackerB = !trackerB;
			loadDisplay.y += trackerB ? 5 : -5;
		}

		if (failed && (MoonInput.justPressed(ACCEPT) || MoonInput.justPressed(BACK))) FlxG.switchState(() -> new MainMenu());

		if (loadComplete && MoonInput.justPressed(ACCEPT) && !transitioning)
		{
			transitioning = true;
			Paths.playSFX('ui/confirmMenu.ogg');
			if (FlxG.sound.music != null) FlxG.sound.music.stop();

			SongPreview.destroy();
			FlxFlicker.flicker(loadText, 1.4, 0.05, true, true, (flicker) -> FlxG.switchState(() -> new PlayState()));
		}
	}

	function preload(item:FlxBasic)
	{
		preloadGrp.add(item);
		preloadGrp.remove(item);
	}
}
