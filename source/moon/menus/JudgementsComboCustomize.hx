package moon.menus;

import moon.game.*;
import moon.game.obj.*;
import moon.game.obj.notes.*;
import moon.game.obj.judgements.*;

class JudgementsComboCustomize extends FlxSubState
{
	var strumlines:Array<Strumline> = [];
	var healthBar:HealthBar;
	var stats:FlxText;

	var judgements:JudgementSprite;
	var combo:ComboNumbers;
	var dragGraphic:MoonSprite;
	public function new()
	{
		super();

		if(PlayState.instance != null)
			this.camera = PlayState.instance.camALT;

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/background'));
		add(bg);
		bg.alpha = 0.0001;
		FlxTween.tween(bg, {alpha: 1}, 0.9);

       	judgements = new JudgementSprite('moon-engine');
       	add(judgements);
       	add(judgements.extra);

       	combo = new ComboNumbers('moon-engine');
       	add(combo);

        for (i in 0...2)
        {
            var strumline = new Strumline(0, 0, 'v-slice', true, 'opponent', null);
            add(strumline.strumBG);
            add(strumline);

            strumlines.push(strumline);
        }

        healthBar = new HealthBar('dummy', 'dummy');
        healthBar.screenCenter(X);
        add(healthBar);

        stats = new FlxText();
        stats.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 24, CENTER);
        stats.text = 'Score: ${FlxG.random.int(1000, 9999)} • Misses: 0 • Acc: ${FlxG.random.int(10, 100)}%';
        stats.antialiasing = true;
        add(stats);
        stats.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
        stats.screenCenter();

       	dragGraphic = new MoonSprite().makeGraphic(1, 1, FlxColor.WHITE);
       	add(dragGraphic);
       	dragGraphic.alpha = 0.00001;

       	judgements.pop('sick', true, true);
       	final neg = FlxG.random.bool(50) ? '-' : 'x';
       	combo.pop('${neg}${FlxG.random.int(100, 9999)}', judgements.color, true);

       	//judgements.screenCenter();
       	//combo.screenCenter();
       	//combo.y += 64;

        updateStrums();
	}

	function updateStrums()
	{
		final downscroll = MoonSettings.callSetting('Downscroll');
        for (strum in strumlines)
        {
            strum.y = (!downscroll) ? 80 : FlxG.height - strum.height - 80;

            final mid = (FlxG.width * 0.5);
            final xAddition = (FlxG.width * 0.25);
            final strumXs = [-xAddition, xAddition];

            final playerStrum = strumlines[1];
            final oppStrum = strumlines[0];

            playerStrum.x = (MoonSettings.callSetting('Middlescroll')) ? mid : mid + strumXs[1];
            oppStrum.x = mid + strumXs[0];
            oppStrum.visible = oppStrum.strumBG.visible = !MoonSettings.callSetting('Middlescroll');

            strum.strumBG.setPosition(strum.x - (strum.strumBG.width / 2), 0);
            strum.strumBG.alpha = MoonSettings.callSetting('Lane Background Visibility');
        }

        healthBar.y = (downscroll) ? 64 : FlxG.height - healthBar.height + 32;
        stats.y = healthBar.y + stats.height + 8;
	}

	var currentDragOBJ:FlxObject;
	var objOffset:FlxPoint = FlxPoint.get();
	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		updateTo(FlxG.mouse.overlaps(judgements) ? judgements : (FlxG.mouse.overlaps(combo)) ? combo : null);

		if(currentDragOBJ != null)
			currentDragOBJ.setPosition(FlxG.mouse.x - objOffset.x, FlxG.mouse.y - objOffset.y);

		if(FlxG.mouse.justReleased && currentDragOBJ != null){
			final dr = (currentDragOBJ == judgements) ? 'Judge' : 'Combo';
			MoonSettings.setSetting('${dr}Pos', [currentDragOBJ.x, currentDragOBJ.y]);
			currentDragOBJ = null;
		}

		if(MoonInput.justPressed(BACK)) {
			FlxG.state.openSubState(new Settings(true));
			Paths.clearUnusedAssets();
		}
	}

	function updateTo(sprite:FlxObject)
	{
		if(sprite == null){
			dragGraphic	.alpha = 0.00001;
			return;
		}

		dragGraphic.alpha = 0.6;
		if(dragGraphic.width != sprite.width || dragGraphic.height != sprite.height)
		{
			dragGraphic.setGraphicSize(sprite.width, sprite.height);
			dragGraphic.updateHitbox();
		}

		dragGraphic.setPosition(sprite.x + sprite.width / 2 - dragGraphic.width / 2, sprite.y + sprite.height / 2 - dragGraphic.height / 2);
		if(FlxG.mouse.justPressed)
		{
			currentDragOBJ = sprite;
			objOffset.set(FlxG.mouse.x - sprite.x, FlxG.mouse.y - sprite.y);
		}
	}
}