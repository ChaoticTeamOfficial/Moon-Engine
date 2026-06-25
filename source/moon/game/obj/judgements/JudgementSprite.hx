package moon.game.obj.judgements;

import moon.backend.gameplay.Timings.Judgement;
import moon.backend.gameplay.*;

using StringTools;

@:publicFields
class JudgementSprite extends MoonSprite
{
	var extra:MoonSprite;
	var sparkle:MoonSprite;
	var skin(default, set):String;
	var data:JudgementsCombo;

	public function new(skin:String)
	{
		super();
		this.skin = skin;
		alpha = 0.00001;
		extra.visible = sparkle.visible = false;
		extra.blend = sparkle.blend = ADD;
	}

	var thisTwn:FlxTween;
	var xtraTwn:FlxTween;

	function pop(judgement:Judgement = SICK, isGold:Bool = false, notAnimated:Bool = false)
	{
		if (judgement == null) return;

		TweenUtils.cancelTwn(thisTwn);

		playAnim(judgement, true);
		extra.playAnim(judgement, true);

		this.color = (isGold) ? 0xFFfeae34 : Timings.get(judgement).color;
		scale.set(data?.judgementsSize ?? 1, data?.judgementsSize ?? 1);
		updateHitbox();
		alpha = 1;
		// screenCenter();
		final st = MoonSettings.callSetting('JudgePos');
		this.setPosition(st[0], st[1]);

		if (notAnimated) return;
		final appear = MoonSettings.callSetting(
			'Judgement Spawn Animation'
		) == 'Noteskin Default' ? (data?.judgementAnims?.appear ?? JUMP_IN) : MoonSettings.callSetting('Judgement Spawn Animation');
		final disappear = MoonSettings.callSetting(
			'Judgement Despawn Animation'
		) == 'Noteskin Default' ? (data?.judgementAnims?.disappear ?? FADE) : MoonSettings.callSetting('Judgement Despawn Animation');

		if (appear == LIGHT)
		{
			TweenUtils.cancelTwn(xtraTwn);

			if (!extra.visible) extra.visible = true;
			extra.color = this.color;
			extra.scale.set((data?.judgementsSize ?? 1) * 0.95, (data?.judgementsSize ?? 1) * 0.95);
			extra.updateHitbox();
			extra.alpha = 1;
			extra.setPosition(this.x + this.width / 2 - extra.width / 2, this.y + this.height / 2 - extra.height / 2);

			xtraTwn = FlxTween.tween(extra, {
				"scale.x": extra.scale.x * 1.35,
				"scale.y": extra.scale.y * 1.35,
				alpha: 0
			}, 0.8, {
				ease: FlxEase.expoOut
			});
		}

		if (isGold)
		{
			sparkle.playAnim('sparkle', true);
			sparkle.visible = true;
			sparkle.setPosition(this.x + FlxG.random.float(-96, this.width - 96), this.y - 64 + FlxG.random.float(0, this.width / 2));
		}

		SpriteUtils.doAppearAnim(this, appear, disappear, function(t) thisTwn = t);
	}

	function set_skin(skin:String):String
	{
		this.skin = skin;

		data = JudgementsCombo.getData(skin);
		antialiasing = data?.antialiasing ?? true;

		for (file in Paths.readDir('images/combo_judgements/$skin')) if (file.startsWith('judgements'))
		{
			final resolution = file.split('-')[1].split('x');
			loadGraphic(Paths.image('combo_judgements/$skin/${file.split(".png")[0]}'), true, Std.parseInt(resolution[0]), Std.parseInt(resolution[1]));

			final wow = [
				'sick',
				'good',
				'bad',
				'shit',
				'miss',
				'combo'
			];
			for (i in 0...wow.length) animation.add(wow[i], [i], 0, false);
		}

		extra = new MoonSprite();
		extra.loadGraphicFromSprite(this);

		sparkle = new MoonSprite();
		sparkle.frames = Paths.getSparrowAtlas('ingame/UI/sparkle');
		sparkle.centerAnimations = true;
		sparkle.animation.addByPrefix('sparkle', 'sparkleFrame', 24, false);
		sparkle.animation.onFinish.add(_ -> sparkle.visible = false);

		return skin;
	}
}
