package moon.game.submenus;

import moon.menus.*;
import moon.menus.obj.freeplay.*;
import moon.backend.gameplay.*;
import moon.game.obj.*;

class PauseMenu extends FlxSubState
{
	public var slideToRight:Array<MoonSprite> = [];
	public var slideToLeft:Array<MoonSprite> = [];

	final options:Array<String> = ['resume', 'restart', 'settings', 'quit'];
	var curSelected:Int = 0;

	public var pf(get, never):PlayField;

	public function new(camera:FlxCamera)
	{
		this.camera = camera;
		super();
	}

	var bgFill:MoonSprite;
	var mainTV:MoonSprite;

	override public function create()
	{
		super.create();

		// Global.allowInputs = false;

		bgFill = new MoonSprite().makeGraphic(FlxG.width + 4, FlxG.height + 4, FlxColor.BLACK);
		bgFill.screenCenter();
		bgFill.alpha = 0.00001;
		add(bgFill);

		FlxTween.tween(bgFill, {
			alpha: 0.6
		}, 0.2);

		var leftTVs = new MoonSprite().loadGraphic(Paths.image('menus/pause/leftSideTVs'));
		leftTVs.scale.set(0.67, 0.67);
		leftTVs.updateHitbox();
		leftTVs.x = -leftTVs.width;
		add(leftTVs);
		slideToLeft.push(leftTVs);
		FlxTween.tween(leftTVs, {
			x: 0
		}, 0.6, {
			startDelay: 0.12,
			framerate: 24,
			ease: FlxEase.expoOut
		});

		var rightSideTVs = new MoonSprite().loadGraphic(Paths.image('menus/pause/rightSideTVs'));
		rightSideTVs.scale.set(0.67, 0.67);
		rightSideTVs.updateHitbox();
		add(rightSideTVs);
		rightSideTVs.x = FlxG.width + rightSideTVs.width;
		FlxTween.tween(rightSideTVs, {
			x: FlxG.width - rightSideTVs.width + 1
		}, 0.6, {
			ease: FlxEase.expoOut,
			startDelay: 0.3,
			framerate: 24
		});
		slideToRight.push(rightSideTVs);

		mainTV = new MoonSprite(0, -164);
		mainTV.frames = Paths.getSparrowAtlas('menus/pause/pauseTV');
		for (option in options) mainTV.animation.addByPrefix(option, option, 24, false);
		mainTV.animation.addByPrefix('static', 'static', 24, true);
		mainTV.scale.set(0.67, 0.67);
		mainTV.updateHitbox();
		mainTV.x = -mainTV.width;
		add(mainTV);
		slideToLeft.push(mainTV);
		FlxTween.tween(mainTV, {
			x: -316
		}, 0.3, {
			framerate: 24,
			ease: FlxEase.expoOut,
			onComplete: _ ->
			{
				// Global.allowInputs = true;
				changeSelection(0);
			}
		});

		mainTV.playAnim('static');

		Paths.playSFX('game/pause/onPause${FlxG.random.bool(5) ? "-PVZ" : ""}.ogg');
		DiscordRPC.updatePresence(AWAY, "Paused!", "Taking a break.", false);
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		mainTV.playAnim(options[curSelected]);

		if (change != 0) Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true, FlxG.random.float(0.9, 1.1));
	}

	override public function update(elapsed:Float)
	{
		if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
		if (MoonInput.justPressed(UI_UP)) changeSelection(-1);

		if (MoonInput.justPressed(BACK)) prepareToClose();

		super.update(elapsed);

		if (MoonInput.justPressed(ACCEPT))
		{
			Paths.playSFX('ui/confirmMenu.ogg', 'sounds', true, FlxG.random.float(0.95, 1.05));
			switch (options[curSelected])
			{
				case 'resume':
					prepareToClose();
				case 'restart':
					Global.clearScriptList();
					AssetManager.skipNextCleanup = true;
					FlxG.resetState();
					close();
				case 'settings':
					close();
					FlxG.state.openSubState(new Settings());
				case 'quit':
					PlayState.instance.exit();
			}
		}
	}

	var counter:Int = 3;

	function prepareToClose()
	{
		if (!MoonSettings.callSetting('Pause Countdown'))
		{
			close();
			return;
		}

		var sprite = new MoonSprite();
		add(sprite);
		sprite.alpha = 0.00001;

		Global.allowInputs = false;

		mainTV.playAnim('static');

		new FlxTimer().start(0.2, _ ->
		{
			slideItems(slideToLeft, true);
			slideItems(slideToRight, false);

			new FlxTimer().start(0.28, _ ->
			{
				new FlxTimer().start(pf.conductor.crochet / 1000, function(_)
				{
					if (counter == -1)
					{
						PlayState.instance.resumeGame();
						close();
					}
					else
					{
						FlxTween.cancelTweensOf(sprite.scale);
						sprite.loadGraphic(Paths.image('menus/pause/countdown/$counter'));
						sprite.screenCenter();
						sprite.alpha = 1;

						sprite.scale.set(1.15, 1.15);

						FlxTween.tween(sprite.scale, {
							x: 1,
							y: 1
						}, 0.6, {
							ease: FlxEase.elasticOut,
							framerate: 24
						});

						Paths.playSFX((counter == 0) ? 'game/pause/pausecountdown-end.ogg' : 'game/pause/pausecountdown-normal.ogg');
					}
					counter--;
				}, 5);
			});
		});
	}

	function slideItems(items:Array<MoonSprite>, toLeft:Bool)
	{
		for (item in items)
		{
			FlxTween.cancelTweensOf(item);
			FlxTween.tween(item, {
				x: toLeft ? item.x - item.width - 300 : item.x + item.width + 300
			}, 0.65, {
				ease: FlxEase.expoIn,
				framerate: 24
			});
		}
	}

	function get_pf():PlayField return PlayField.instance;
}
