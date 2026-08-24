package moon.global_obj;

import moon.dependency.user.MoonAchievements.AchievementData;

/**
 * Toast that slides in when an achievement is unlocked.
 */
class AchievementUnlockPopup extends FlxSpriteGroup
{
	static var queue:Array<AchievementData> = [];
	static var current:AchievementUnlockPopup;
	static inline final HOLD_TIME:Float = 4;
	static inline final ICON_SIZE:Int = 72;
	static inline final ICON_X:Float = 48;
	static inline final ICON_Y:Float = 48;
	static inline final TITLE_Y:Float = 24;
	static inline final NAME_X:Float = 132;
	static inline final NAME_Y:Float = 64;

	var bg:MoonSprite;
	var icon:MoonSprite;
	var title:FlxText;
	var nameTxt:FlxText;
	var descTxt:FlxText;

	public static function show(data:AchievementData):Void
	{
		queue.push(data);
		if (current == null || !current.exists) next();
	}

	static function next():Void
	{
		if (queue.length == 0)
		{
			current = null;
			return;
		}

		if (current != null && !current.exists) current = null;

		current = new AchievementUnlockPopup(queue.shift());
		if (FlxG.state != null) FlxG.state.add(current);
	}

	public function new(data:AchievementData)
	{
		super();

		scrollFactor.set();
		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];

		bg = new MoonSprite().loadGraphic(Paths.image('bg', 'achievements'));
		add(bg);

		icon = new MoonSprite(
			ICON_X,
			ICON_Y
		).loadGraphic(Paths.image(Paths.exists('achievements/${data.id}-icon.png') ? '${data.id}-icon' : 'placeholder-icon', 'achievements'), true, 250, 250);
		icon.animation.add('unlock', [0], 0, true);
		icon.playAnim('unlock');
		icon.setGraphicSize(ICON_SIZE, ICON_SIZE);
		icon.updateHitbox();
		add(icon);

		title = new FlxText(0, TITLE_Y, bg.width, 'Achievement Unlocked!');
		title.setFormat(Paths.font('phantomuff/full.ttf'), 14, 0xFF1a1a1a, CENTER);
		title.antialiasing = true;
		add(title);

		nameTxt = new FlxText(NAME_X, NAME_Y, bg.width - NAME_X - 24, data.name);
		nameTxt.setFormat(Paths.font('phantomuff/full.ttf'), 22, FlxColor.WHITE, LEFT);
		nameTxt.antialiasing = true;
		add(nameTxt);

		descTxt = new FlxText(NAME_X, nameTxt.y + nameTxt.height, bg.width - NAME_X - 24, data.description);
		descTxt.setFormat(Paths.font('phantomuff/full.ttf'), 14, 0xFFBBBBBB, LEFT);
		descTxt.antialiasing = true;
		add(descTxt);

		x = (FlxG.width - bg.width) * 0.5;
		y = -bg.height - 20;
		alpha = 0;

		FlxTween.tween(this, {
			y: 16,
			alpha: 1
		}, 0.45, {
			ease: FlxEase.quartOut,
			onComplete: _ -> FlxTween.tween(this, {
				y: -bg.height - 20,
				alpha: 0
			}, 0.4, {
				startDelay: HOLD_TIME,
				ease: FlxEase.quartIn,
				onComplete: _ -> finish()
			})
		});

		Paths.playSFX('ui/achievementGot.ogg', 'sounds', true, FlxG.random.float(0.92, 1.08));
	}

	function finish():Void
	{
		if (current == this) current = null;

		if (FlxG.state != null) FlxG.state.remove(this, true);
		else
			destroy();

		next();
	}

	override public function destroy():Void
	{
		FlxTween.cancelTweensOf(this);
		if (current == this)
		{
			current = null;
			next();
		}

		super.destroy();
	}
}
