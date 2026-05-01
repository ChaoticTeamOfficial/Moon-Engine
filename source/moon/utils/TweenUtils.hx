package moon.utils;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxG;

using StringTools;

@:publicFields

/**
 * A class meant for tween utilities.
 */
class TweenUtils
{
    /**
     * An array containing all the available easings.
     */
    @:isVar static var easeList(get, default):Array<String>;
    @:noCompletion static function get_easeList():Array<String>
    {
        // we dont want these
        // since uhh when getting fields using reflect, it returns some stuffies we dont want
        final excluded = [
            'PI2', 'EL', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'ELASTIC_AMPLITUDE', 'ELASTIC_PERIOD',
            '__name__', '__constructor__', '__type__', '__meta__', '__implementedBy__'
        ];

        easeList = Reflect.fields(FlxEase).filter(field -> return !excluded.contains(field));
        //easeList = Reflect.fields(FlxEase);
        easeList.push('INSTANT');

        return easeList;
    }

    /**
     * Function that resolve an ease string to a FlxEase.
     * @param easeName the ease name.
     */
    static function resolveEase(easeName:String):EaseFunction
    {
        if(easeName == null || easeName == "" || easeName.toLowerCase().contains('linear'))
            return FlxEase.linear; //safechecks are nice!

        var name:String = easeName;
        switch(name.toLowerCase())
        {
            case "instant": return null;
            default: 
                if(name.toLowerCase() != "linear" && !StringTools.endsWith(name, "In") && !StringTools.endsWith(name, "Out") && !StringTools.endsWith(name, "InOut"))
                    name += "InOut";

            var func = Reflect.field(FlxEase, name);

            //just some last failsafes
            if(func == null)
            {
                name = StringTools.replace(name, "InOut", "Out");
                func = Reflect.field(FlxEase, name);
            }

            if(func == null)
                func = FlxEase.expoInOut;

            //trace('resolved ease: $name', "DEBUG");

            return func;
        }
    }

    /**
     * Cancels a tween that's active, preventing overlapping tweens if you're going to play another.
     * @param tween The active tween.
     */
    static function cancelTwn(tween:FlxTween)
        if (tween != null && tween.active) tween.cancel();

    /**
     * Cancels a timer that's active, preventing overlapping timers if you're going to play another.
     * @param timer The active timer.
     */
    static function cancelTmr(timer:FlxTimer)
        if (timer != null && timer.active) timer.cancel();
}