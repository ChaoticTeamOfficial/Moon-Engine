package moon.game.obj.judgements;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

@:publicFields
class JudgementSprite extends MoonSprite
{
    /**
     * The judgement's skin display.
     */
    var skin(default, set):String = '';

     /**
      * All the data for this.
      */
    var data:JudgementsJSON;

    var yTwn:FlxTween;
    var fadeTwn:FlxTween;

    /**
     * Displays the judgement on screen
     * @param judgement The judgement name
     * @param animate Whether it should do a 'jump' animation or not.
     * @param fade Whether it should do a fade out or not.
     */
    function showJudgement(judgement:String = 'sick', animate:Bool = true, fade:Bool = true)
    {

    }

    @:noCompletion public function set_skin(skin:String):String
    {
        this.skin = skin;

        if(Paths.exists('images/ingame/UI/judgements_combo/$skin/config.json'))
            data = Paths.JSON('images/ingame/UI/judgements_combo/$skin/config');

        return this.skin;
    }
}