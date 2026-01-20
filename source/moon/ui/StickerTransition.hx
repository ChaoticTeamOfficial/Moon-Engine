package moon.ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import moon.backend.Paths;
import openfl.Lib;

using StringTools;

//TODO: Documment these classes properly some time.

class StickerSubState extends FlxSubState
{
    var nextState:FlxState;
    var transition:StickerTransition;
    var switchingState:Bool = false;

    public function new(nextState:FlxState)
    {
        super();
        this.nextState = nextState;

        transition = new StickerTransition();
        FlxG.game.addChild(transition);

        transition.createStickers();
        transition.startInAnimation(this);
    }

    public function onInComplete():Void
    {
        switchingState = true;
        FlxG.switchState(() -> nextState);
        FlxG.signals.postStateSwitch.addOnce(() -> transition.startOutAnimation(this));
    }

    public function onOutComplete():Void
    {
        switchingState = false;
        Lib.application.window.resizable = true;
        destroy();
    }

    override public function destroy():Void
    {
        if (switchingState) return;
        if (transition != null)
        {
            transition.destroy();
            FlxG.game.removeChild(transition);
        }
        super.destroy();
    }
}

// You might wonder "Why the fuck would you render stuff outside the game"
// Because I... don't wanna do like funkin did and deal with caching graphics
// and positioning them correctly :'( I'm one person coding everything
class StickerTransition extends Sprite
{
    var stickers:Array<Sprite> = [];
    var inCompleteCount:Int = 0;
    var outCompleteCount:Int = 0;
    var stickerKeys:Array<String> = [];
    var spacingFactor:Float = 0.66;

    var globalScale:Float;
    var offsetX:Float;
    var offsetY:Float;

    public function new()
    {
        super();
        final windowW = Lib.application.window.width;
        final windowH = Lib.application.window.height;
        globalScale = Math.min(windowW / FlxG.width, windowH / FlxG.height);
        offsetX = (windowW - FlxG.width * globalScale) / 2;
        offsetY = (windowH - FlxG.height * globalScale) / 2;

        stickerKeys = getStickerKeys("images/menus/transitions/stickers");
    }

    function getStickerKeys(baseDir:String, subPath:String = ""):Array<String>
    {
        var keys:Array<String> = [];
        final currentDir = baseDir + (subPath != "" ? "/" + subPath : "");

        for (file in Paths.readDir(currentDir, [".png"], true))
            keys.push("menus/transitions/stickers" + (subPath != "" ? "/" + subPath : "") + "/" + file);

        for (item in Paths.readDir(currentDir, null, false))
            if (!item.contains("."))
                keys = keys.concat(getStickerKeys(baseDir, subPath + (subPath != "" ? "/" : "") + item));

        return keys;
    }

    function createSticker(key:String, x:Float, y:Float):Sprite
    {
        final graphic = Paths.image(key);
        if (graphic == null) return null;

        if (!Paths.dumpExclusions.contains('$key.png'))
            Paths.dumpExclusions.push('$key.png');

        var sticker = new Sprite();
        var bmp = new Bitmap(graphic.bitmap);
        bmp.smoothing = true; //cant believe it took me so damn long to find ts
        bmp.x = -graphic.width / 2;
        bmp.y = -graphic.height / 2;
        sticker.addChild(bmp);

        sticker.x = x;
        sticker.y = y;
        sticker.rotation = Math.random() * 360;
        sticker.scaleX = sticker.scaleY = 0;
        sticker.alpha = 0;

        return sticker;
    }

    public function createStickers()
    {
        if (stickerKeys.length == 0)
        {
            trace("No stickers found!", "ERROR");
            return;
        }

        final offscreen = 100;

        final extraX = offsetX / globalScale;
        final extraY = offsetY / globalScale;

        var xPos:Float = -offscreen - extraX;
        var yPos:Float = -offscreen - extraY;

        // jumpscares you with 2 while cases
        while (yPos <= FlxG.height + offscreen + extraY)
        {
            xPos = -offscreen - extraX;
            while (xPos <= FlxG.width + offscreen + extraX)
            {
                final key = FlxG.random.getObject(stickerKeys);
                final screenX = xPos * globalScale + offsetX;
                final screenY = yPos * globalScale + offsetY;
                final sticker = createSticker(key, screenX, screenY);
                if (sticker == null) continue;

                addChild(sticker);
                stickers.push(sticker);

                xPos += Paths.image(key).width * spacingFactor;
            }
            yPos += FlxG.random.float(80, 120);
        }

        final centerSticker = createSticker(FlxG.random.getObject(stickerKeys), 
            (FlxG.width / 2) * globalScale + offsetX, 
            (FlxG.height / 2) * globalScale + offsetY);

        if (centerSticker != null)
        {
            centerSticker.rotation = 0;
            addChild(centerSticker);
            stickers.push(centerSticker);
        }

        FlxG.random.shuffle(stickers);
    }

    public function startInAnimation(sub:StickerSubState):Void
    {
        // just to guarantee that people wont see how crappy this code is...
        Lib.application.window.resizable = false;

        for (i in 0...stickers.length)
        {
            new FlxTimer().start(FlxMath.remapToRange(i, 0, stickers.length - 1, 0, 0.7), (_) -> {
                try {Paths.playSFX('ui/stickers/keyClick${FlxG.random.int(1, 8)}.ogg');}
                catch (e:Dynamic){}

                FlxTween.tween(stickers[i], {
                    scaleX: 1.2 * globalScale, 
                    scaleY: 1.2 * globalScale, 
                    alpha: 1, 
                    rotation: (stickers[i].rotation != 0) ? stickers[i].rotation + FlxG.random.float(-45, 45) : 0
                    }, 0.1, {ease: FlxEase.backOut, onComplete: (_) -> {
                    inCompleteCount++;
                    if (inCompleteCount >= stickers.length)
                        sub.onInComplete();
                }});
                FlxTween.tween(stickers[i], {scaleX: globalScale, scaleY: globalScale}, 0.1, {startDelay: 0.2, ease: FlxEase.backIn});
            });
        }
    }

    public function startOutAnimation(sub:StickerSubState):Void
    {
        for (i in 0...stickers.length)
        {
            FlxTween.tween(stickers[i], {
                scaleX: 0, scaleY: 0, 
                alpha: 0, 
                rotation: (stickers[i].rotation != 0) ? stickers[i].rotation + FlxG.random.float(-45, 45) : 0
                }, 0.3, {ease: FlxEase.backIn, startDelay: Math.random() * 0.5, onComplete: (_) -> {
                outCompleteCount++;
                if (outCompleteCount >= stickers.length)
                    sub.onOutComplete();
            }});
        }
    }

    public function destroy():Void
    {
        while (stickers.length > 0)
        {
            var sticker = stickers.pop();
            if (sticker.parent != null)
                sticker.parent.removeChild(sticker);
        }

        if (parent != null)
            parent.removeChild(this);
    }
}