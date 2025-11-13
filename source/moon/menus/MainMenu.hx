package moon.menus;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import moon.menus.obj.main.*;

class MainMenu extends FlxState
{
    final opt:Array<String> = ['story mode', 'freeplay', 'mods', 'toolbox', 'settings', 'exit'];
    var buttons:Array<MenuItem> = [];
    var curSelected:Int = 0;
    var maxVisible:Int = 2;

    override public function create()
    {
        super.create();
        for (i in 0...opt.length)
        {
            var btn = new MenuItem(20, 128 + 64 * i, opt[i].toUpperCase());
            add(btn);
            buttons.push(btn);
        }
        changeSelection(0);
        calculateTargets();
        for (btn in buttons)
        {
            btn.x = btn.targetX;
            btn.y = btn.targetY;
            btn.alpha = btn.targetAlpha;
            var sc = btn.targetScale;
            btn.scale.set(sc, sc);
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
        if (MoonInput.justPressed(UI_UP)) changeSelection(-1);

        if (MoonInput.justPressed(ACCEPT))
        {
            switch(opt[curSelected].toLowerCase())
			{
				case 'freeplay': openSubState(new Freeplay('bf'));
                case 'settings': openSubState(new Settings());
			}
        }

        final lerpSpeed = 10;
        for (btn in buttons)
        {
            btn.x += (btn.targetX - btn.x) * lerpSpeed * elapsed;
            btn.y += (btn.targetY - btn.y) * lerpSpeed * elapsed;
            btn.alpha += (btn.targetAlpha - btn.alpha) * lerpSpeed * elapsed;
            var targetSc = btn.targetScale;
            btn.scale.x += (targetSc - btn.scale.x) * lerpSpeed * elapsed;
            btn.scale.y += (targetSc - btn.scale.y) * lerpSpeed * elapsed;
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, opt.length - 1);
        Paths.playSFX('ui/scrollMenu');
        calculateTargets();
    }

    function calculateTargets():Void
    {
        final total = opt.length;
        final centerX = 78;
        final centerY = FlxG.height / 2;
        final radiusX = 300;
        final radiusY = 200;

        for (i in 0...total)
        {
            var diff:Float = (i - curSelected) % total;
            if (diff < 0) diff += total;
            if (diff > total / 2) diff -= total;

            final absDiff:Float = Math.abs(diff);
            final btn = buttons[i];
            btn.selected = (absDiff == 0);

            var targetAlpha:Float = 1.0;
            var targetScale:Float = 1.0;
            var angle:Float = 0.0;

            if (absDiff <= maxVisible)
            {
                angle = diff * (Math.PI / 2 / maxVisible);
                targetScale = Math.cos(angle) * 0.4 + 0.6;
            }
            else
            {
                targetAlpha = 0.0;
                targetScale = 0.5;
                btn.targetX = -btn.width - 10;
                btn.targetY = centerY + diff * radiusY;
                btn.targetAlpha = targetAlpha;
                btn.targetScale = targetScale;
                continue;
            }

            // position calculations
            btn.targetX = centerX + (Math.cos(angle) - 1) * radiusX;
            btn.targetY = centerY + Math.sin(angle) * radiusY;
            btn.targetAlpha = targetAlpha;
            btn.targetScale = targetScale;
        }
    }
}