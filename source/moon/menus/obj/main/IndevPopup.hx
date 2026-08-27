package moon.menus.obj.main;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

using StringTools;

class IndevPopup extends FlxSubState
{
	static inline final PANEL_WIDTH:Int = 800;
	static inline final PANEL_HEIGHT:Int = 680;
	static inline final PANEL_PADDING:Int = 24;
	static inline final SCROLL_SPEED:Float = 32;

	var panelBg:FlxSprite;
	var contentText:FlxText;
	var understoodBtn:FlxSprite;
	var understoodLabel:FlxText;
	var scrollY:Float = 0;
	var maxScroll:Float = 0;
	var panelX:Float;
	var panelY:Float;

	public function new()
	{
		super();
	}

	var stateTwns:Array<FlxTween> = [];

	override public function create()
	{
		super.create();

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		panelX = (FlxG.width - PANEL_WIDTH) / 2;
		panelY = (FlxG.height - PANEL_HEIGHT) / 2;

		bgColor = 0xB7000000;

		panelBg = new FlxSprite(panelX, panelY).makeGraphic(PANEL_WIDTH, PANEL_HEIGHT, FlxColor.fromRGB(24, 24, 28));
		add(panelBg);

		var title = new FlxText(panelX, panelY + 12, PANEL_WIDTH, 'INDEV ${Constants.INDEV_VERSION} — CHANGELOG');
		title.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 38, CENTER);
		title.color = 0xFFffd863;
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(title);

		contentText = new FlxText(panelX + PANEL_PADDING, panelY + 60, PANEL_WIDTH - PANEL_PADDING * 2, buildChangelogString());
		contentText.setFormat(Paths.font('phantomuff/full.ttf'), 24, LEFT);
		contentText.color = FlxColor.WHITE;
		add(contentText);

		final bodyHeight = PANEL_HEIGHT - 60 - 70;
		contentText.clipRect = new flixel.math.FlxRect(0, 0, contentText.frameWidth, bodyHeight);
		maxScroll = Math.max(0, contentText.height - bodyHeight);

		understoodBtn = new FlxSprite(panelX + PANEL_WIDTH / 2 - 100, panelY + PANEL_HEIGHT - 56).makeGraphic(200, 40, 0xFF3a3a42);
		add(understoodBtn);

		understoodLabel = new FlxText(understoodBtn.x, understoodBtn.y + 10, 200, 'UNDERSTOOD!');
		understoodLabel.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 18, CENTER);
		understoodLabel.color = FlxColor.WHITE;
		add(understoodLabel);

		for (i in 0...2)
		{
			var arrow = new MoonSprite().loadGraphic(Paths.image('menus/story/belowind'));
			arrow.flipY = (i == 0);
			add(arrow);
			arrow.y = (i == 0) ? contentText.y - arrow.height - 16 : understoodBtn.y;
			arrow.x = contentText.x + contentText.width - arrow.width;
			arrow.alpha = 0.00001;
			FlxTween.tween(arrow, {
				alpha: 1
			}, 1, {
				startDelay: 0.5
			});

			FlxTween.tween(arrow, {
				y: (i == 0) ? arrow.y - 16 : arrow.y + 16
			}, 2, {
				ease: FlxEase.quadInOut,
				type: PINGPONG,
				framerate: 24
			});
		}

		panelBg.scale.set(2, 0);
		stateTwns.push(FlxTween.tween(panelBg.scale, {
			x: 1,
			y: 1
		}, 0.6, {
			ease: FlxEase.elasticOut
		}));

		contentText.alpha = title.alpha = 0.0001;
		for (txt in [contentText, title]) stateTwns.push(FlxTween.tween(txt, {
			alpha: 1
		}, 0.4, {
			startDelay: 0.6
		}));

		Paths.playSFX('ui/popup.wav', 'sounds', true, FlxG.random.float(0.8, 1.3));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (MoonInput.justPressed(UI_DOWN)) scroll(SCROLL_SPEED);
		if (MoonInput.justPressed(UI_UP)) scroll(-SCROLL_SPEED);

		if (FlxG.mouse.wheel != 0) scroll(-FlxG.mouse.wheel * SCROLL_SPEED);

		final hoveringButton = FlxG.mouse.overlaps(understoodBtn);
		understoodBtn.color = hoveringButton ? 0xFF72728D : 0xFF3a3a42;

		if ((hoveringButton && FlxG.mouse.justPressed) || MoonInput.justPressed(ACCEPT)) close();
	}

	function scroll(amount:Float):Void
	{
		FlxTween.cancelTweensOf(contentText);
		FlxTween.cancelTweensOf(contentText.clipRect);
		scrollY = FlxMath.bound(scrollY + amount, 0, maxScroll);
		FlxTween.tween(contentText, {
			y: panelY + 60 - scrollY
		}, 0.5, {
			ease: FlxEase.expoOut
		});
		contentText.alpha = 1;
		contentText.clipRect.y = scrollY;
		contentText.clipRect = contentText.clipRect;
	}

	function buildChangelogString():String
	{
		final entry = IndevChangelogs.get(Constants.INDEV_VERSION);
		if (entry == null) return 'No changelog found for this version.';

		var lines:Array<String> = [];

		function section(label:String, items:Array<String>):Void
		{
			if (items == null || items.length == 0) return;
			lines.push('$label:');
			for (item in items) lines.push('  - $item');
			lines.push('');
		}

		section('Additions', entry.additions);
		section('Changes', entry.changes);
		section('Fixes', entry.fixes);
		section('Removals', entry.removals);

		return lines.join('\n').trim();
	}

	override public function close():Void
	{
		// FlxG.save.bind(SAVE_BIND);
		///FlxG.save.data.lastSeenIndevVersion = Constants.INDEV_VERSION;
		// FlxG.save.flush();

		FlxG.mouse.visible = false;

		for (twn in stateTwns) TweenUtils.cancelTwn(twn);

		super.close();
	}
}
