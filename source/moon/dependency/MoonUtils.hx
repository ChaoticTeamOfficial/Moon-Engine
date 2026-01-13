package moon.dependency;
import flixel.tweens.FlxTween;
import flixel.FlxG;
using StringTools;

@:publicFields

/**
 * A class meant for utilities, there's a buncha cool helpful stuff here :3
 */
class MoonUtils
{
    /**
     * Returns a integer number to a arrow direction.
     * @param int The number in which will be used for getting the direction.
     */
    inline static function intToDir(int:Int)
    {
        // Repeat 2 times 'cause theres 4 more, usually for opponent.
        final directions = ['left', 'down', 'up', 'right', 'left', 'down', 'up', 'right'];
        return directions[int];
    }

    /**
     * Returns an array from a file, which breaks per line.
     * @param path the file path.
     */
    static function getArrayFromFile(path:String)
    {
        if (Paths.exists(path))
            return Paths.getFileContent(path).split("\n").map((line) -> return line.trim());
        else 
            trace('File at $path not found!', "ERROR");
        return null;
    }

    /**
     * Cancels a tween that's active, preventing overlapping tweens if you're going to play another.
     * @param tween The active tween.
     */
    static function cancelActiveTwn(tween:FlxTween)
        if (tween != null && tween.active) tween.cancel();

    /**
     * Starts a song upon calling, does nothing if already playing.
     * @param song The song's path.
     * @param fade Whether or not should the song fade in.
     */
    static function playGlobalMusic(song:String, fade:Bool = false)
    {
        if ((FlxG.sound.music != null && !FlxG.sound.music.playing ) || (FlxG.sound.music == null))
        {
            FlxG.sound.playMusic(Paths.sound('$song.ogg'), (fade) ? 0 : MoonSettings.callSetting('Music Volume'), true);
            if (fade) FlxG.sound.music.fadeIn(140, 0, MoonSettings.callSetting('Music Volume'));
        }
    }

    ////////////////////////////////////////////

    /**
     * Starts the appear animation and chains to disappear. Don't use it on sprites with offsets, as this messes with them.
     * @param sprite The sprite to animate.
     * @param anim The appear animation type (e.g. 'jump-in').
     * @param outAnim The disappear animation type (e.g. 'fade').
     * @param setTween A function that updates the caller's tween reference.
     */
    static function doSpriteAnim(sprite:MoonSprite, anim:String, outAnim:String, setTween:FlxTween->Void)
    {
        var tween:FlxTween = null;
        final duration = 0.32;
        sprite.skew.set(0, 0);
        switch(anim)
        {
            case 'jump-in', 'jump-out':
                final ogOffset = sprite.offset.y;
                sprite.offset.y = (anim == 'jump-in') ? -14 : 14;
                tween = FlxTween.tween(sprite, {"offset.y": ogOffset}, duration, {
                    ease: FlxEase.expoOut,
                    onComplete: _ -> getOutAnim(sprite, outAnim, setTween)
                });

            case 'scale', 'pulse':
                final resizeTo = anim == 'pulse' ? 1.25 : 0.75;
                final ogScaleX = sprite.scale.x;
                final ogScaleY = sprite.scale.y;

                sprite.scale.set(ogScaleX * resizeTo, ogScaleY * resizeTo);

                tween = FlxTween.tween(sprite.scale, {x: ogScaleX, y: ogScaleY}, duration, {
                    ease: FlxEase.expoOut,
                    onComplete: _ -> getOutAnim(sprite, outAnim, setTween)
                });

            case 'skewX', 'skewY', 'skewBoth':
                final n = (FlxG.random.bool(50)) ? -24 : 24;
                sprite.skew.set((anim == 'skewX' || anim == 'skewBoth') ? n : 0, (anim == 'skewY' || anim == 'skewBoth') ? n : 0);
                tween = FlxTween.tween(sprite.skew, {x: 0, y: 0}, duration, {
                    ease: FlxEase.circOut,
                    onComplete: _ -> getOutAnim(sprite, outAnim, setTween)
                });

            case 'slide', 'slide&skew':
                final ogOffset = sprite.offset.x;
                sprite.offset.x = ogOffset + 20;
                if(anim.contains('skew')) sprite.skew.x = 22;
                tween = FlxTween.tween(sprite, {"offset.x": ogOffset, "skew.x": 0}, duration + 0.3, {
                    ease: FlxEase.expoOut,
                    onComplete: _ -> getOutAnim(sprite, outAnim, setTween)
                });

            case 'light':
                final ogScaleX = sprite.scale.x;
                final ogScaleY = sprite.scale.y;

                sprite.scale.set(ogScaleX * 0.85, ogScaleY * 0.85);

                tween = FlxTween.tween(sprite.scale, {x: ogScaleX, y: ogScaleY}, duration, {
                    ease: FlxEase.expoOut,
                    onComplete: _ -> getOutAnim(sprite, outAnim, setTween)
                });

            case 'angle':
                sprite.angle = FlxG.random.int(-15, 15);
                tween = FlxTween.tween(sprite, {angle: 0}, duration, {
                    ease: FlxEase.expoOut,
                    onComplete: _ -> getOutAnim(sprite, outAnim, setTween)
                });

            case 'laser':
                final ogCol = sprite.color;
                tween = FlxTween.color(sprite, duration, FlxColor.WHITE, ogCol, {ease: FlxEase.circOut, onComplete: _-> getOutAnim(sprite,outAnim,setTween)});

            case 'shake':
                tween = FlxTween.shake(sprite, 0.03, duration - 0.16, XY, {ease: FlxEase.expoOut, onComplete: _ -> getOutAnim(sprite,outAnim,setTween)});

            default:
                trace('Unknown appear anim: $anim', "ERROR");
                getOutAnim(sprite, outAnim, setTween);
        }

        setTween(tween);
    }

    /**
     * Starts the disappear animation.
     * @param sprite The sprite to animate.
     * @param anim The disappear animation type.
     * @param setTween A function that updates the caller's tween reference.
     */
    static function getOutAnim(sprite:MoonSprite, anim:String, setTween:FlxTween->Void)
    {
        final duration = 0.8;
        final delay = 0.2;

        var tween:FlxTween = null;
        switch(anim)
        {
            case 'fade':
                tween = FlxTween.tween(sprite, {alpha: 0.0001}, duration, {startDelay: delay});

            case 'scale', 'scale&fade':
                tween = FlxTween.tween(sprite, {"scale.x": 0, "scale.y": 0, alpha: anim.contains('fade') ? 0.0001 : 1}, duration, {startDelay: delay, ease: FlxEase.circIn, onComplete: _->sprite.alpha = 0.0001});

            case 'bounce', 'bounce&fade':
                tween = FlxTween.tween(sprite, {"scale.x": sprite.scale.x * 1.6, "scale.y": sprite.scale.y * 1.6, alpha: (anim.contains('fade')) ? 0.0001 : 1}, duration, {startDelay: delay, ease: FlxEase.circIn, onComplete: _->sprite.alpha = 0.0001});

            case 'skewX', 'skewY', 'skewBoth', 'skewX&fade', 'skewY&fade', 'skewBoth&fade':
                tween = FlxTween.tween(sprite, {
                    "skew.x": (anim.contains('skewX') || anim.contains('skewBoth')) ? 100 : 0, 
                    "skew.y": (anim.contains('skewY') || anim.contains('skewBoth')) ? 100 : 0,
                    alpha: (anim.contains('fade')) ? 0.0001 : 1
                    }, duration, {
                    ease: FlxEase.expoIn,
                    startDelay: delay,
                    onComplete: _-> sprite.alpha = 0.0001
                });

            case 'squishX', 'squishY':
                final curScale = sprite.scale;
                final squishX = (anim == 'squishX') ? sprite.scale.x * 1.4 : 0;
                final squishY = (anim == 'squishY') ? sprite.scale.y * 1.4 : 0;
                tween = FlxTween.tween(sprite.scale, {x: squishX, y: squishY}, duration - 0.3, {startDelay: delay, ease: FlxEase.circIn, onComplete: _->sprite.alpha = 0.0001});

            default:
                trace('Unknown disappear anim: $anim', "ERROR");
                sprite.alpha = 0.0001;
        }

        setTween(tween);
    }
}