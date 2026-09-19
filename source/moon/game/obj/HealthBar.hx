package moon.game.obj;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.group.FlxSpriteGroup;

/**
 * A type for icon layouts.
 */
enum abstract IconLayout(String) from String to String
{
	/**
	 * Vertical stack with slight horizontal stagger. Usually works well for 2-3 icons.
	 */
	var STACK = "stack";

	/**
	 * Slight diagonal fan.
	 */
	var FAN = "fan";

	/**
	 * Diagonal row.
	 */
	var ROW = "row";
}

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
	 * Primary opponent name (first in the opponents list).
	 */
	public var opponent(default, set):String;

	/**
	 * Primary player name (first in the players list).
	 */
	public var player(default, set):String;

	/**
	 * Full list of opponent character names.
	 */
	public var opponents(default, set):Array<String> = [];

	/**
	 * Full list of player character names.
	 */
	public var players(default, set):Array<String> = [];

	/**
	 * All icons currently managed by this healthbar.
	 */
	public var icons:Array<HealthIcon> = [];

	/**
	 * Opponent-side icons only.
	 */
	public var oppIcons:Array<HealthIcon> = [];

	/**
	 * Player-side icons only.
	 */
	public var playerIcons:Array<HealthIcon> = [];

	/**
	 * Convenience reference to the first opponent icon.
	 */
	public var oppIcon:HealthIcon;

	/**
	 * Convenience reference to the first player icon.
	 */
	public var playerIcon:HealthIcon;

	/**
	 * The health amount, which the healthbar tracks.
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
	 * The distance between the opponent cluster and the player cluster around the health division.
	 */
	public var iconDistance:Float = 44;

	/**
	 * Horizontal offset applied between icons of the same side when laid out side-by-side.
	 */
	public var iconSpreadX:Float = 64;

	/**
	 * Vertical offset applied between icons of the same side when stacked.
	 */
	public var iconSpreadY:Float = 64;

	/**
	 * How multi-icon groups are arranged.
	 */
	public var iconLayout:IconLayout = STACK;

	/**
	 * The conductor driving this healthbar's icon bops and transitions.
	 */
	public var conductor:Conductor;

	/**
	 * Creates a healthbar.
	 * @param opponent single opponent name, or array of opponent names.
	 * @param player single player name, or array of player names.
	 */
	public function new(opponent:Dynamic, player:Dynamic, ?conductor:Conductor)
	{
		super();

		this.conductor = conductor;

		barBG = cast new MoonSprite();
		barBG.scale.set(0.9, 0.9);
		barBG.updateHitbox();

		bar = new FlxBar(RIGHT_TO_LEFT, 0, 0, null, null, 0, 100);
		bar.y = barBG.y + (barBG.height - bar.height) / 2;
		bar.x = barBG.x + (barBG.width - bar.width) / 2;

		add(bar);
		add(barBG);

		// ok so, we need to ormalize inputs to arrays so single-strings keep working as well!
		final oppList:Array<String> = (Std.isOfType(opponent, Array)) ? cast opponent : [Std.string(opponent)];
		final plyList:Array<String> = (Std.isOfType(player, Array)) ? cast player : [Std.string(player)];

		rebuildIcons(oppList, plyList);

		bar.createFilledBar(getRGBData(this.opponent), getRGBData(this.player));
		health = bar.value = 50;

		if (this.conductor != null)
		{
			this.conductor.onStep.add(step ->
			{
				for (ico in icons) ico.onStepHit(step, iconScale + ico.extraScale);
			});
		}

		updateBarStats();
		updateBarPos(true);
	}

	public function applyUISkin(uiSkin:UISkinData):Void
	{
		if (uiSkin == null) return;

		final hb = uiSkin.healthBar;
		
		if(hb.barBG == null) hb.barBG = 'healthbar';

		barBG.loadGraphic(Paths.image('uiSkins/${uiSkin.name}/${hb?.barBG}'));
		final s = hb?.scale ?? 1;
		barBG.scale.set(s, s);
		barBG.updateHitbox();

		final dir = switch ((hb?.fillDirection ?? "RIGHT_TO_LEFT").toUpperCase())
		{
			case "LEFT_TO_RIGHT":
				FlxBarFillDirection.LEFT_TO_RIGHT;
			case "TOP_TO_BOTTOM":
				FlxBarFillDirection.TOP_TO_BOTTOM;
			case "BOTTOM_TO_TOP":
				FlxBarFillDirection.BOTTOM_TO_TOP;
			default:
				FlxBarFillDirection.RIGHT_TO_LEFT;
		};

		final vertical = hb?.vertical ?? false;
		final padX = hb?.paddingX ?? 8;
		final padY = hb?.paddingY ?? 3;

		remove(bar, true);
		bar.destroy();

		bar = new FlxBar(
			dir,
			vertical ? Std.int(barBG.width - padX * 2) : Std.int(barBG.width - padX * 2),
			vertical ? Std.int(barBG.height - padY * 2) : Std.int(barBG.height - padY * 2),
			null,
			null,
			0,
			100
		);
		bar.x = barBG.x + (barBG.width - bar.width) * 0.5;
		bar.y = barBG.y + (barBG.height - bar.height) * 0.5;
		insert(0, bar);

		if (opponent != null && player != null) bar.createFilledBar(getRGBData(opponent), getRGBData(player));

		bar.value = health;

		if (hb?.iconScale != null) iconScale = hb.iconScale;
		if (hb?.iconDistance != null) iconDistance = hb.iconDistance;
		if (hb?.iconSpreadX != null) iconSpreadX = hb.iconSpreadX;
		if (hb?.iconSpreadY != null) iconSpreadY = hb.iconSpreadY;
		if (hb?.iconLayout != null) iconLayout = hb.iconLayout;

		// TODO:
		// iconsFollowHealth = hb?.iconsFollowHealth ?? true;

		updateBarStats();
		updateBarPos(true);
	}

	/**
	 * Rebuilds all icons from the given character name lists.
	 */
	public function rebuildIcons(oppNames:Array<String>, plyNames:Array<String>):Void
	{
		for (ico in icons)
		{
			remove(ico, true);
			ico.destroy();
		}
		icons = [];
		oppIcons = [];
		playerIcons = [];
		oppIcon = null;
		playerIcon = null;

		final safeOpp = (oppNames != null && oppNames.length > 0) ? oppNames.copy() : ['dad'];
		final safePly = (plyNames != null && plyNames.length > 0) ? plyNames.copy() : ['bf'];

		// I'm assigning backing fields directly to avoid setter recursion...
		// yes I like reflect ok I know it kills android or phones in general but I just cant help it,,
		Reflect.setField(this, 'opponents', safeOpp);
		Reflect.setField(this, 'players', safePly);
		Reflect.setField(this, 'opponent', safeOpp[0]);
		Reflect.setField(this, 'player', safePly[0]);

		for (name in safeOpp)
		{
			final ico = createIcon(name, false);
			oppIcons.push(ico);
			icons.push(ico);
			add(ico);
		}

		for (name in safePly)
		{
			final ico = createIcon(name, true);
			playerIcons.push(ico);
			icons.push(ico);
			add(ico);
		}

		oppIcon = oppIcons[0];
		playerIcon = playerIcons[0];
	}

	function createIcon(charName:String, isPlayerSide:Bool):HealthIcon
	{
		final ico = new HealthIcon();
		ico.scale.set(iconScale, iconScale);
		ico.baseFlipX = isPlayerSide;
		ico.icon = charName;
		ico.updateHitbox();
		ico.y = bar.y - (ico.height * 0.5);
		return ico;
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
		for (ico in icons) ico.scale.x = ico.scale.y = 0;

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
					for (ico in icons) FlxTween.tween(ico.scale, {
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
		bar.value = FlxMath.lerp(bar.value, health, 0.2);

		updateBarPos();

		if (FlxG.keys.justPressed.NINE)
		{
			for (ico in playerIcons)
			{
				ico.useOldIcon = !ico.useOldIcon;
				ico.onStepHit(ico.bopEvery, iconScale + ico.extraScale);
			}
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
						layoutIconCluster(playerIcons, pf.playerStrum.x + d, pf.playerStrum.y, true, true);
						layoutIconCluster(oppIcons, pf.oppStrum.x - d, pf.oppStrum.y, false, true);
					}

				default:
					final divisionX = bar.x + (bar.width * (1 - (bar.value / 100)));

					layoutIconCluster(oppIcons, divisionX - iconDistance, bar.y, false, false);
					layoutIconCluster(playerIcons, divisionX + iconDistance, bar.y, true, false);
			}
		}

		barBG.alpha = bar.alpha = instant ? targetAlpha : FlxMath.lerp(bar.alpha, targetAlpha, 0.2);

		final iconAlpha = (MoonSettings.callSetting('Icons') == 'At Healthbar') ? bar.alpha : 1;
		final iconVisible = MoonSettings.callSetting('Icons') != 'Off';
		for (ico in icons)
		{
			ico.alpha = iconAlpha;
			ico.visible = iconVisible;
		}

		barBG.screenCenter(X);
		bar.screenCenter(X);
	}

	/**
	 * Positions a group of icons around an anchor point using the current layout mode.
	 * @param cluster the icons to position.
	 * @param anchorX reference X.
	 * @param anchorY reference Y.
	 * @param isPlayerSide whether is a player or not.
	 * @param onLanes when true, treats anchor as a fixed world position.
	 */
	function layoutIconCluster(cluster:Array<HealthIcon>, anchorX:Float, anchorY:Float, isPlayerSide:Bool, onLanes:Bool):Void
	{
		if (cluster == null || cluster.length == 0) return;

		final n = cluster.length;

		// default layout with only one icon per side
		if (n == 1)
		{
			final ico = cluster[0];
			if (onLanes)
			{
				if (isPlayerSide) ico.setPosition(anchorX, anchorY);
				else
					ico.setPosition(anchorX - ico.width, anchorY);
			}
			else
			{
				ico.x = isPlayerSide ? (anchorX - ico.width / 2) : (anchorX - ico.width / 2);
				ico.y = anchorY - (ico.height * 0.5);
			}
			return;
		}

		// multi-icon layouts! offsets are relative to the "main" slot so we can still track the health division the same way
		// a single icon would!
		for (i in 0...n)
		{
			final ico = cluster[i];
			final t = (n == 1) ? 0.0 : (i / (n - 1) - 0.5);

			var ox:Float = 0;
			var oy:Float = 0;

			switch (iconLayout)
			{
				case ROW:
					ox = t * iconSpreadX * (n - 1);
					oy = 0;

				case FAN:
					final dir = isPlayerSide ? 1 : -1;
					ox = t * iconSpreadX * (n - 1) * dir;
					oy = t * iconSpreadY * (n - 1);

				default:
					final dir = isPlayerSide ? 1 : -1;
					ox = (i % 2 == 0 ? -1 : 1) * (iconSpreadX * 0.35) * dir;
					oy = t * iconSpreadY * (n - 1);
			}

			if (onLanes)
			{
				if (isPlayerSide) ico.setPosition(anchorX + ox, anchorY + oy);
				else
					ico.setPosition(anchorX - ico.width + ox, anchorY + oy);
			}
			else
			{
				ico.x = anchorX + ox - ico.width / 2;
				ico.y = anchorY + oy - (ico.height * 0.5);
			}
		}
	}

	public function updateBarStats()
	{
		for (i in 0...oppIcons.length)
		{
			if (i < opponents.length) oppIcons[i].icon = opponents[i];
			oppIcons[i].updateHitbox();
			oppIcons[i].onStepHit(conductor?.curStep ?? 0, iconScale + oppIcons[i].extraScale);
		}

		for (i in 0...playerIcons.length)
		{
			if (i < players.length) playerIcons[i].icon = players[i];
			playerIcons[i].updateHitbox();
			playerIcons[i].onStepHit(conductor?.curStep ?? 0, iconScale + playerIcons[i].extraScale);
		}

		// Bar colors follow the primary characters.
		// so...
		// TODO: figure out a way to... enhance the bar itself? idk...
		if (opponent != null && player != null) bar.createFilledBar(getRGBData(opponent), getRGBData(player));
	}

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
		if (opponents.length == 0) opponents = [val];
		else
			opponents[0] = val;

		if (oppIcons.length > 0) updateBarStats();
		return val;
	}

	@:noCompletion
	public function set_player(val:String)
	{
		this.player = val;
		if (players.length == 0) players = [val];
		else
			players[0] = val;

		if (playerIcons.length > 0) updateBarStats();
		return val;
	}

	@:noCompletion
	public function set_opponents(val:Array<String>)
	{
		this.opponents = (val != null && val.length > 0) ? val.copy() : ['dad'];
		this.opponent = this.opponents[0];

		if (oppIcons.length != this.opponents.length || playerIcons.length != players.length) rebuildIcons(this.opponents, this.players);
		else
			updateBarStats();

		return this.opponents;
	}

	@:noCompletion
	public function set_players(val:Array<String>)
	{
		this.players = (val != null && val.length > 0) ? val.copy() : ['bf'];
		this.player = this.players[0];

		if (oppIcons.length != opponents.length || playerIcons.length != this.players.length) rebuildIcons(this.opponents, this.players);
		else
			updateBarStats();

		return this.players;
	}

	@:noCompletion
	public function set_health(ammount:Float)
	{
		this.health = ammount;
		for (ico in playerIcons) ico.updateAnim(ammount);
		for (ico in oppIcons) ico.updateAnim(100 - ammount);
		return ammount;
	}
}
