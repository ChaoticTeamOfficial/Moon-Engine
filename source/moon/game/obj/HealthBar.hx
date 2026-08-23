package moon.game.obj;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.group.FlxSpriteGroup;

class HealthBar extends FlxSpriteGroup
{
	/**
	 * The healthbar's background.
	 */
	public var barBG:MoonSprite;

	/**
	 * The healthbar itself.
	 */
	public var bar:FlxBar;

	/**
	 * The opponent's name. Will automatically update the icon if changed.
	 */
	public var opponent(default, set):String;

	/**
	 * The player's name. Will automatically update the icon if changed.
	 */
	public var player(default, set):String;

	/**
	 * An array containing all icons. There's no purpose to it for now, but will be used for a future multi-icon implementation!
	 */
	public var icons:Array<HealthIcon> = [];

	/**
	 * The opponent's icon.
	 */
	public var oppIcon:HealthIcon;

	/**
	 * The player's icon.
	 */
	public var playerIcon:HealthIcon;

	/**
	 * The health ammount, which the healthbar tracks.
	 */
	public var health(default, set):Float = 50;

	/**
	 * The scale icons will have.
	 */
	public var iconScale:Float = 0.8;

	/**
	 * Whether or not to update the icon position.
	 */
	public var updateIconsPos:Bool = true;

	/**
	 * The distance between both icons.
	 */
	public var iconDistance:Float = 44;

	/**
	 * The conductor driving this healthbar's icon bops and transitions.
	 */
	public var conductor:Conductor;

	/**
	 * Creates a healthbar.
	 * @param opponent the opponent name.
	 * @param player the player name.
	 */
	public function new(opponent:String, player:String, ?conductor:Conductor)
	{
		super();

		this.conductor = conductor;

		barBG = cast new MoonSprite().loadGraphic(Paths.image('ingame/UI/healthbar'));
		barBG.scale.set(0.9, 0.9);
		barBG.updateHitbox();

		bar = new FlxBar(RIGHT_TO_LEFT, Std.int(barBG.width - 16), Std.int(barBG.height - 6), null, null, 0, 100);
		bar.y = barBG.y + (barBG.height - bar.height) / 2;
		bar.x = barBG.x + (barBG.width - bar.width) / 2;

		add(bar);
		add(barBG);

		oppIcon = new HealthIcon();
		oppIcon.scale.set(iconScale, iconScale);
		oppIcon.y = bar.y - (oppIcon.height * 0.5);

		playerIcon = new HealthIcon();
		playerIcon.scale.set(iconScale, iconScale);
		playerIcon.baseFlipX = true;
		playerIcon.y = bar.y - (playerIcon.height * 0.5);

		add(oppIcon);
		add(playerIcon);

		icons.push(oppIcon);
		icons.push(playerIcon);

		// playerIcon.origin.set(0, playerIcon.height / 2);
		// oppIcon.origin.set(oppIcon.width, oppIcon.height / 2);

		playerIcon.updateHitbox();
		oppIcon.updateHitbox();

		this.opponent = opponent;
		this.player = player;

		bar.createFilledBar(getRGBData(opponent), getRGBData(player));
		health = bar.value = 50;
		playerIcon.screenCenter(X);
		oppIcon.screenCenter(X);

		if (this.conductor != null)
		{
			this.conductor.onStep.add(step ->
			{
				// if (transitioning) return;
				oppIcon.onStepHit(step, iconScale + oppIcon.extraScale);
				playerIcon.onStepHit(step, iconScale + playerIcon.extraScale);
			});
		}

		updateBarStats();
		updateBarPos(true);
	}

	var count:Int = 4;

	public function performTransition()
	{
		// disabled for now, sorrey :P
		return;
		if (conductor == null) return;

		transitioning = true;
		count = 4;
		bar.scale.set(0, 1);
		barBG.scale.set(0, 1);
		oppIcon.scale.x = oppIcon.scale.y = playerIcon.scale.x = playerIcon.scale.y = 0;

		if (PlayField.instance.stats != null) PlayField.instance.stats.visible = false;

		new FlxTimer().start(conductor.crochet / 1000, _ ->
		{
			count--;

			switch (count)
			{
				case 3, 2:
					final target = (count == 3) ? 0.9 : 1;
					FlxTween.tween((count == 3 ? barBG : bar).scale, {
						x: target,
						y: target
					}, conductor.crochet / 1000, {
						ease: FlxEase.expoOut
					});
				case 1:
					for (ico in [oppIcon, playerIcon]) FlxTween.tween(ico.scale, {
						x: iconScale + ico.extraScale,
						y: iconScale + ico.extraScale
					}, conductor.crochet / 1000, {
						ease: FlxEase.backOut
					});
				case 0:
					if (PlayField.instance.stats != null)
					{
						PlayField.instance.stats.scale.set(0, 0);
						PlayField.instance.stats.visible = true;
					}
				case -1:
					transitioning = false;
			}
		}, 5);
	}

	public var lerpPercent:Float = 0;
	public var transitioning:Bool = false;

	private var targetAlpha:Float = 1;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// uhmm, weird shit :(
		if (health > 98) health = 101;
		// if(bar.value != health) trace(health);
		bar.value = FlxMath.lerp(bar.value, health, 0.2);

		updateBarPos();

		if (FlxG.keys.justPressed.NINE)
		{
			playerIcon.useOldIcon = !playerIcon.useOldIcon;
			playerIcon.onStepHit(playerIcon.bopEvery, iconScale + playerIcon.extraScale);
			updateBarStats();
		}
	}

	public function updateBarPos(instant:Bool = false)
	{
		if (MoonSettings.callSetting('Healthbar Visibility') == 'Below 100%') targetAlpha = health < 100 ? 1 : 0;
		else
			targetAlpha = MoonSettings.callSetting('Healthbar Visibility') == 'On' ? 1 : 0;

		if (updateIconsPos)
		{
			switch (MoonSettings.callSetting('Icons'))
			{
				case 'On Lanes':
					final pf = PlayField.instance;
					final d = 169;
					if (pf != null)
					{
						playerIcon.setPosition(pf.playerStrum.x + d, pf.playerStrum.y);
						oppIcon.setPosition(pf.oppStrum.x - oppIcon.width - d, pf.oppStrum.y);
					}

				default:
					final divisionX = bar.x + (bar.width * (1 - (bar.value / 100)));

					playerIcon.x = divisionX + iconDistance - playerIcon.width / 2;
					oppIcon.x = divisionX - iconDistance - oppIcon.width / 2;

					oppIcon.y = bar.y - (oppIcon.height * 0.5);
					playerIcon.y = bar.y - (playerIcon.height * 0.5);
			}
		}

		barBG.alpha = bar.alpha = instant ? targetAlpha : FlxMath.lerp(bar.alpha, targetAlpha, 0.2);
		oppIcon.alpha = playerIcon.alpha = (MoonSettings.callSetting('Icons') == 'At Healthbar') ? bar.alpha : 1;

		oppIcon.visible = playerIcon.visible = (MoonSettings.callSetting('Icons') != 'Off');

		barBG.screenCenter(X);
		bar.screenCenter(X);
	}

	public function updateBarStats()
	{
		playerIcon.icon = player;
		oppIcon.icon = opponent;

		playerIcon.updateHitbox();
		oppIcon.updateHitbox();

		// playerIcon.origin.set(-8, playerIcon.height / 2);
		// oppIcon.origin.set(oppIcon.width + 8, oppIcon.height / 2);

		oppIcon.onStepHit(conductor?.curStep ?? 0, iconScale + oppIcon.extraScale);
		playerIcon.onStepHit(conductor?.curStep ?? 0, iconScale + playerIcon.extraScale);
	}

	/*public function bump()
		{
			if (transitioning) return;

			oppIcon.scale.set(iconScale + oppIcon.extraScale + 0.15, iconScale + oppIcon.extraScale + 0.15);
			playerIcon.scale.set(iconScale + playerIcon.extraScale + 0.15, iconScale + playerIcon.extraScale + 0.15);
	}*/
	public function getRGBData(character:String)
	{
		final data:Character.CharacterData = getData(character);
		final c = data?.icon?.color ?? [80, 80, 80];
		return FlxColor.fromRGB(c[0], c[1], c[2]);
	}

	public function getData(character:String):Character.CharacterData return (Paths.exists(
		'characters/${character}/data.json'
	)) ? Paths.JSON('characters/${character}/data') : null;

	@:noCompletion
	public function set_opponent(val:String)
	{
		this.opponent = val;
		updateBarStats();
		return val;
	}

	@:noCompletion
	public function set_player(val:String)
	{
		this.player = val;
		updateBarStats();
		return val;
	}

	@:noCompletion
	public function set_health(ammount:Float)
	{
		this.health = ammount;
		playerIcon.updateAnim(ammount);
		oppIcon.updateAnim(100 - ammount);
		return ammount;
	}
}
