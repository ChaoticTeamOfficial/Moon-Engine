package moon.utils;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
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
     * Formats a number's decimals. (E.G. 1000 -> 1.000)
     * @param num The number to be formatted.
     */
    inline static function formatNumber(num:Int):String
    {
        final str:String = '$num';
        var formatted:String = "";
        var i:Int = str.length - 1;
        var count:Int = 0;
        while (i >= 0)
        {
            formatted = str.charAt(i) + formatted;
            count++;
            if (count % 3 == 0 && i > 0)
                formatted = "." + formatted;
            
            i--;
        }
        return formatted;
    }

    public static inline function spaceToDash(s:String):String 
        return s.replace(" ", "-");

    public static inline function dashToSpace(s:String):String 
        return s.replace("-", " ");
    
    public static inline function swapSpaceDash(s:String):String 
        return s.contains('-') ? dashToSpace(s) : spaceToDash(s);

    private static var symbols:String = "!@#$%^&*()1234567890?";
    private static var timer:FlxTimer;

    /*
     * Scrambles a FlxText, revealing all the characters in it 1 by 1.
     * @param text The FlxText instance.
     */
    static function scrambleText(text:FlxText):Void
    {
        // You probably noticed at this point that I reaaaally like messing with strings hahahah
        final original:String = text.text;
        text.text = generateScramble(original);

        var revealed:Array<Bool> = [for (i in 0...original.length) false];

        if(timer != null && timer.active)
        {
            timer.cancel();
            timer.destroy();
        }

        timer = new FlxTimer();
        timer.start(0.05, function(t:FlxTimer)
        {
            var done:Bool = true;
            var newText:String = "";

            for (i in 0...original.length)
            {
                final c:String = original.charAt(i);
                if (~/\s/.match(c))
                {
                    newText += c;
                    revealed[i] = true;
                }
                else if (revealed[i])
                    newText += c;
                else
                {
                    if (Math.random() < 0.2) // probability to reveal!
                    {
                        newText += c;
                        revealed[i] = true;
                    }
                    else
                    {
                        newText += symbols.charAt(Std.random(symbols.length));
                        done = false;
                    }
                }
            }

            text.text = newText;

            if (done)
                t.cancel();
        }, 0);
    }

    private static function generateScramble(original:String):String
    {
        var result:String = "";
        for (i in 0...original.length)
        {
            final c:String = original.charAt(i);

            result += (~/\s/.match(c)) ? c : symbols.charAt(Std.random(symbols.length));
        }
        return result;
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
            trace('[UTILS] File at $path not found!', "ERROR");
        return null;
    }

    /**
     * Starts a song upon calling, does nothing if already playing.
     * @param song The song's path.
     * @param fade Whether or not should the song fade in.
     */
    static function playGlobalMusic(song:String, fade:Bool = false)
    {
        if ((FlxG.sound.music != null && !FlxG.sound.music.playing ) || (FlxG.sound.music == null))
        {
            FlxG.sound.playMusic(Paths.sound('$song.ogg'), (fade) ? 0 : MoonSettings.callSetting('Music Volume') / 100, true);
            if (fade) FlxG.sound.music.fadeIn(3, 0, MoonSettings.callSetting('Music Volume') / 100);
        }
    }
}