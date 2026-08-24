package moon.game.submenus;

import moon.game.PlayState;
import moon.game.obj.*;
import moon.backend.gameplay.*;
import flixel.group.FlxGroup;

/**
 * The Gameover sub state! Everything Gameover-wise is handled in here.
 * TODO: Custom camera offsets for gameovers since vslice has those.
 * TODO: properly get the current character stuff from a gameover field in the json!
 */
class Gameover extends FlxSubState
{
	public static var instance:Gameover;

	/**
	 * The background gradient sprite.
	 */
	public var backGradient:FlxSprite;

	/**
	 * The character sprite.
	 */
	public var charSpr:Character;

	/**
	 * The player icon that shows on the left.
	 */
	public var playerIcon:HealthIcon;

	/**
	 * The stats text that shows the stats P1 had before dying.
	 */
	public var stats:HTMLText = new HTMLText();

	public var loss:MoonSprite = new MoonSprite().loadGraphic(Paths.image('menus/gameover/lose'));
	public var restart:MoonSprite = new MoonSprite().loadGraphic(Paths.image('menus/gameover/restart'));

	/**
	 * The song that plays. (wow!)
	 */
	public var music:MoonSound;

	/**
	 * The conductor.
	 */
	public var conductor:Conductor;

	/**
	 * The selectable buttons.
	 */
	public var buttons:FlxTypedGroup<UIButton> = new FlxTypedGroup<UIButton>();

	final items:Array<String> = ['Retry Track', 'Exit'];

	// TODO: hmm... maybe make a way to have more than one character game over?
	// yeah I'll have to figure this out later for P2 support.
	/**
	 * The character string.
	 */
	// final char:String = Shortcuts.getChart().meta.players[0];

	/**
	 * Whether or not to force the fakeout. Set this to true if you're simply messing around, or testing it!
	 * Don't forget that it must be set before the Gameover SubState is opened.
	 */
	public static var forceFakeout:Bool = false;

	/**
	 * The default color scheme used for most objects. Defaults to BF's color.
	 */
	public var colorScheme:FlxColor = FlxColor.WHITE;

	/**
	 * Whether or not has the player pressed the button.
	 */
	public var pressed:Bool = false;

	public var curSelected:Int = 0;

	// just to shorten some code because I'm a lazy fuck!
	final cg = PlayState.instance.camGAME;
	final ch = PlayState.instance.camHUD;

	public function new()
	{
		super();
		instance = this;
		// trace('yes we are at gameover.');

		PlayState.instance.persistentDraw = false;

		// We must disable inputs just in case we get the fakeout!
		Global.allowInputs = false;

		// fakeout thing = FlxG.random.bool((1 / 4096) * 100)

		// now we load the song.
		final songStr = (Paths.exists('characters/bf/gameover/gameOverSong.ogg')) ? 'bf/gameover/gameOverSong.ogg' : 'bf/gameover/gameOverSong.ogg';
		music = new MoonSound().loadSoundAndMeta(songStr, 'characters', false);
		music.volume = MoonSettings.callSetting('Music Volume') / 100;
		FlxG.sound.list.add(music);

		conductor = new Conductor(music?.metadata?.bpm ?? 100, music?.metadata?.timeSignature[0] ?? 4, music?.metadata?.timeSignature[1] ?? 4);

		backGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00000000, FlxColor.WHITE], 1, 180);
		backGradient.alpha = 0.00001;
		backGradient.scrollFactor.set();
		add(backGradient);

		charSpr = Shortcuts.getPlayer();
		add(charSpr);

		backGradient.color = colorScheme = charSpr.gameoverColorScheme;

		playerIcon = new HealthIcon();
		playerIcon.scale.set(0.5, 0.5);
		playerIcon.icon = 'bf';
		playerIcon.updateAnim(0);
		playerIcon.camera = ch;
		playerIcon.alpha = 0.00001;
		add(playerIcon);

		// now we setup the lil stats that show
		stats.setFormat(Paths.font('phantomuff/full.ttf'), 58, CENTER);
		stats.antialiasing = true;
		add(stats);
		stats.camera = ch;
		stats.alpha = 0.00001;
		stats.letterSpacing = 2;

		final stat = Shortcuts.getStats();
		final rank = Timings.getRank(stat.accuracy);
		// stats.fieldHeight = FlxG.height; // text is cutting for some reason, so this should fix it. nvm it didnt :(
		// gonna do a janky workaround, whatever. :T
		stats.text =
			'<font size="24px"><font color="#ffffff">-- Track Stats --\n'
			+
			'<font size="14px"><font color="#728096">Score: ${MoonUtils.formatNumber(stat.score)} // Misses: ${stat.misses} // Acc: ${stat.accuracy}% (${rank.short})';
		stats.screenCenter(X);
		stats.x -= 296;
		stats.y = FlxG.height - stats.height - 164;

		playerIcon.setPosition(stats.x + stats.width / 2 - playerIcon.width / 2, stats.y - playerIcon.height + 16);

		// now we setup the selecatblehh items,
		buttons.camera = ch;
		add(buttons);

		loss.camera = restart.camera = ch;
		loss.alpha = restart.alpha = 0.00001;
		add(loss);
		add(restart);
		loss.scale.set(0.5, 0.5);
		restart.scale.set(0.45, 0.45);

		loss.angle = 6;
		FlxTween.tween(loss, {
			angle: -6
		}, 2, {
			ease: FlxEase.quadInOut,
			type: PINGPONG
		});
		FlxTween.tween(loss, {
			y: loss.y + 16
		}, 2.5, {
			ease: FlxEase.quadInOut,
			type: PINGPONG
		});

		loss.color = restart.color = colorScheme;

		loss.setPosition(stats.x + stats.width / 2 - loss.width / 2, -8);
		restart.setPosition(stats.x + stats.width / 2 - restart.width / 2, 64);

		for (i in 0...items.length)
		{
			final item = items[i];
			buttons.recycle(UIButton, function():UIButton
			{
				var hi = new UIButton(0, 0, item);
				hi.scale.set(0, 0);
				hi.selected = false;
				hi.screenCenter(Y);
				hi.x = stats.x + stats.width / 2 - hi.width / 2;
				hi.y += (i == 0) ? -32 : 32; // I should change this lolol
				hi.alpha = 0.00001;
				return hi;
			});
		}

		changeSelection(0);

		// and lastly, we setup the animations and the actions, such as the fakeout.
		if (forceFakeout || FlxG.random.bool((1 / 4096) * 100))
		{
			charSpr.playAnim('gameover-fakeout', true);
			sfx('fakeout');

			Global.scriptCall('onGameOverFakeout', [instance]);
		}
		else
			triggerDeath();

		charSpr.animation.onFinish.add(anim ->
		{
			switch (anim)
			{
				case 'gameover-fakeout':
					triggerDeath();
				case 'gameover':
					music.play();
			}
		});

		conductor.onBeat.add(beat ->
		{
			// charSpr.dance(true);
			charSpr.playAnim('gameover-loop');
			playerIcon.scale.set(0.6, 0.6);
		});

		Global.scriptCall('onGameOver', [instance]);
	}

	public function triggerDeath()
	{
		// cool shake and loss sfx, as long as the playAnim AND the screen flash
		sfx('lossSFX');
		cg.flash(FlxColor.RED, 0.38);
		cg.shake(0.025, 0.24);
		charSpr.playAnim('gameover', true);

		// now we allow inputs
		Global.allowInputs = true;

		// then we want the hud stuff to be visible now.
		hudAlpha = 1;

		// lets tween some shii because why not,,
		for (i in 0...buttons.members.length)
		{
			buttons.members[i].x += 96;
			FlxTween.tween(buttons.members[i], {
				x: buttons.members[i].x - 96
			}, 0.9, {
				ease: FlxEase.expoOut
			});
		}

		for (obj in [stats, playerIcon])
		{
			obj.x += 96;
			FlxTween.tween(obj, {
				x: obj.x - 96
			}, 1.2, {
				ease: FlxEase.expoOut
			});
		}

		Global.scriptCall('onGameOverTrigger', [instance]);
	}

	var hudAlpha:Float = 0.00001;

	override public function update(elapsed)
	{
		super.update(elapsed);

		conductor.time = music.time;

		loss.alpha = restart.alpha = playerIcon.alpha = stats.alpha = FlxMath.lerp(stats.alpha, hudAlpha, elapsed * 2);
		backGradient.alpha = stats.alpha - 0.6;
		for (btn in buttons.members) btn.alpha = stats.alpha;

		playerIcon.scale.x = playerIcon.scale.y = FlxMath.lerp(playerIcon.scale.x, 0.5, elapsed * 6);

		if (MoonInput.justPressed(UI_DOWN) && !pressed) changeSelection(1);
		if (MoonInput.justPressed(UI_UP) && !pressed) changeSelection(-1);
		if (MoonInput.justPressed(ACCEPT) && !pressed)
		{
			if (items[curSelected].toLowerCase() == 'exit')
			{
				FlxTween.globalManager.cancelTweensOf(loss);
				PlayState.instance.exit();
			}
			else
			{
				pressed = true;
				music.stop();

				charSpr.playAnim('death-confirm', true);
				sfx('gameOverSongEnd');
				hudAlpha = 0;

				// Not using the camera focus function because it uses offsets.
				// in here, we want to CENTER the camera.
				TweenUtils.cancelTwn(PlayState.instance.camMov);
				final char = PlayState.instance.getChar('player');
				PlayState.instance.camMov = FlxTween.tween(PlayState.instance.camFollower, {
					x: char.x + char.width / 2,
					y: char.y + char.height / 2 - 48
				}, 2, {
					ease: FlxEase.expoOut
				});

				Global.scriptCall('onGameOverRetry', [instance]);
				new FlxTimer().start(1.5, _ ->
				{
					ch.fade(FlxColor.BLACK, 1.45, false, () ->
					{
						// PlayState.instance.persistentDraw = true;
						// PlayState.instance.gameOverRestart();

						// ch.fade(FlxColor.BLACK, 1.5, true);
						FlxG.sound.list.remove(music);

						Global.clearScriptList();
						AssetManager.skipNextCleanup = true;
						FlxG.resetState();
						close();
					});

					// PlayState.instance.setCameraFocus('player', [0, -164], 1.5, {ease: FlxEase.expoIn, startDelay: 0.01, onComplete: _->{

					// }});
				});
			}
		}
	}

	override public function close()
	{
		super.close();
		FlxTween.globalManager.cancelTweensOf(loss);
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, buttons.members.length - 1);

		for (i in 0...buttons.members.length) buttons.members[i].selected = i == curSelected;

		if (change != 0) Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true);
	}

	private function sfx(audio:String)
	{
		if (Paths.exists('characters/bf/gameover/$audio.ogg')) Paths.playSFX('bf/gameover/$audio.ogg', 'characters', true);
		else
			Paths.playSFX('bf/gameover/$audio.ogg', 'characters', true);
	}
}
