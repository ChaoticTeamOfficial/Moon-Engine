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
}