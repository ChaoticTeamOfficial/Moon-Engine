package moon.menus.obj.freeplay;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import moon.backend.data.SongLibrary;
import flixel.group.FlxGroup;

class FreeplayDifficultySelector extends FlxTypedGroup<Dynamic>
{
    public var leftArrow:MoonSprite;
    public var rightArrow:MoonSprite;
    public var text:FlxText;

    public var difficulties:Array<String> = [];
    public var curDifficulty:Int = 2;

    public var centerX:Float = 0;
    public var centerY:Float = 0;

    public function new()
    {
        super();

        loadDifficulties();

        leftArrow = new MoonSprite(0, 0);
        leftArrow.loadGraphic(Paths.image('menus/freeplay/arrow'));
        leftArrow.flipX = true;
        leftArrow.antialiasing = true;
        leftArrow.scale.set(0.6, 0.6);
        add(leftArrow);

        rightArrow = new MoonSprite(0, 0);
        rightArrow.loadGraphic(Paths.image('menus/freeplay/arrow'));
        rightArrow.antialiasing = true;
        rightArrow.scale.set(0.6, 0.6);
        add(rightArrow);

        text = new FlxText(0, 0, 0, "", 48);
        text.setFormat(Paths.font('phantomuff/difficulty.ttf'), 48, FlxColor.WHITE, CENTER);
        text.bold = true;
        text.antialiasing = true;
        text.alpha = 0.0001;
        add(text);

        updateUI(true);
    }

    function loadDifficulties()
    {
        difficulties = [for(d in SongLibrary.getDifficultyList()) d.name];
        if (difficulties.length == 0) difficulties = ['easy', 'normal', 'hard'];
        
        var hardIdx = difficulties.indexOf('hard');
        curDifficulty = hardIdx >= 0 ? hardIdx : 0;
    }

    public function change(delta:Int)
    {
        curDifficulty = FlxMath.wrap(curDifficulty + delta, 0, difficulties.length - 1);
        updateUI(false);
        Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true, FlxG.random.float(0.9, 1.2));
    }

    public function getSelected():String
    {
        return difficulties[curDifficulty];
    }

    public function setPos(x:Float, y:Float)
    {
        centerX = x;
        centerY = y;
    }

    public function updateUI(instant:Bool = false)
    {
        final diff = SongLibrary.getDifficulty(getSelected());
        final newName = diff?.displayName?.toUpperCase() ?? getSelected().toUpperCase();
        final newColor = diff?.color != null ? FlxColor.fromString(diff.color) : FlxColor.WHITE;

        if (instant)
        {
            text.text = newName;
            text.color = newColor;
            text.fieldWidth = 0;
            text.updateHitbox();
            text.alpha = 1;
        }
        else
        {
            FlxTween.cancelTweensOf(text);

            FlxTween.tween(text, {alpha: 0, y: centerY - text.height / 2 - 20}, 0.15, {ease: FlxEase.cubeIn, onComplete: _-> {
                text.text = newName;
                text.color = newColor;
                text.fieldWidth = 0;
                text.updateHitbox();
                text.y = centerY - text.height / 2 + 20;

                FlxTween.tween(text, {alpha: 1, y: centerY - text.height / 2}, 0.2, {ease: FlxEase.cubeOut});
            }});
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        final lerpSpeed = 10.0 * elapsed;
        text.y = FlxMath.lerp(text.y, centerY - text.height / 2, lerpSpeed);
        text.x = FlxMath.lerp(text.x, centerX - text.width / 2, lerpSpeed);

        leftArrow.x = FlxMath.lerp(leftArrow.x, text.x - leftArrow.width - 15, lerpSpeed);
        leftArrow.y = FlxMath.lerp(leftArrow.y, centerY - leftArrow.height / 2, lerpSpeed);

        rightArrow.x = FlxMath.lerp(rightArrow.x, text.x + text.width + 15, lerpSpeed);
        rightArrow.y = FlxMath.lerp(rightArrow.y, centerY - rightArrow.height / 2, lerpSpeed);
    }
}