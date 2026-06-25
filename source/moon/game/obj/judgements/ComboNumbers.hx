package moon.game.obj.judgements;

import moon.backend.gameplay.Timings;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

using StringTools;

@:publicFields
class ComboNumbers extends FlxSpriteGroup
{
	var skin(default, set):String;
	var data:JudgementsCombo;

	public function new(skin:String)
	{
		super();
		this.skin = skin;
	}

	function pop(comboStr:String, color:FlxColor, notAnimated:Bool = false)
	{
		if (this.members.length > 0) clear();

		for (i in 0...comboStr.length)
		{
			final digit = comboStr.charAt(i);
			final number = retrieveComboGraphic();

			number.playAnim(digit);
			number.antialiasing = data?.antialiasing ?? true;
			number.scale.set(data?.comboSize ?? 1, data?.comboSize ?? 1);
			number.updateHitbox();
			number.color = color;
			add(number);

			var thisTwn:FlxTween = null;
			number.setPosition(this.x + (number.width * i), this.y);

			if (!notAnimated)
			{
				final appear = MoonSettings.callSetting(
					'Combo Spawn Animation'
				) == 'Noteskin Default' ? (data?.judgementAnims?.appear ?? JUMP_IN) : MoonSettings.callSetting('Combo Spawn Animation');
				final disappear = MoonSettings.callSetting(
					'Combo Despawn Animation'
				) == 'Noteskin Default' ? (data?.judgementAnims?.disappear ?? FADE) : MoonSettings.callSetting('Combo Despawn Animation');
				SpriteUtils.doAppearAnim(number, appear, disappear, function(t) thisTwn = t);
			}
		}

		final st = MoonSettings.callSetting('ComboPos');
		this.setPosition(st[0], st[1]);
	}

	/**
	 * Makes a 'roll' animation for the combos (if it exists).
	 * @param toNumber The number it will roll to. (IT WILL CHANGE THE COMBO VALUE!!)
	 * @param totalRolls Total rolls the combo will do before revealing the combo.
	 * @param fadeOut Whether the numbers should fade out after reveal
	 */
	function comboRoll(toNumber:Int = 0, ?totalRolls:Int = 5, fadeOut:Bool = false)
	{
		// TODO
	}

	function retrieveComboGraphic():MoonSprite
	{
		var newSpr = new MoonSprite();

		for (file in Paths.readDir('images/combo_judgements/$skin')) if (file.startsWith('combo'))
		{
			final resolution = file.split('-')[1].split('x');
			newSpr.loadGraphic(Paths.image('combo_judgements/$skin/${file.split(".png")[0]}'), true, Std.parseInt(resolution[0]), Std.parseInt(resolution[1]));

			final wow = [
				'-',
				'x',
				'0',
				'1',
				'2',
				'3',
				'4',
				'5',
				'6',
				'7',
				'8',
				'9'
			];
			for (i in 0...wow.length) newSpr.animation.add(wow[i], [i], 0, false);

			final rolls = data?.comboRolls ?? false;
			if (rolls) newSpr.animation.add('roll', [12, 13, 14], 8, true);
		}

		newSpr.centerAnimations = true;
		return newSpr;
	}

	function set_skin(skin:String):String
	{
		this.skin = skin;

		data = JudgementsCombo.getData(skin);

		return this.skin;
	}
}
