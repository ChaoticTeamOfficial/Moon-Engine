package moon.game.obj.judgements;

import moon.backend.gameplay.Timings;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

@:publicFields
class ComboNumbers extends FlxSpriteGroup
{
    /**
     * The combo's numbers. Always remember to update this before displaying it.
     */
    var combo:Int = 0;

    /**
     * The combo's skin display.
     */
    var skin(default, set):String = '';

    /**
     * All the data for this.
     */
    var data:JudgementsJSON;

    /**
     * The color for all the alive numbers;
     */
    var numsColor(default, set):FlxColor;

    var xSep:Float = 0;

    /**
     * Displays the combo numbers on screen
     * @param animate Whether it should do a 'jump' animation or not.
     * @param fade Whether it should do a fade out or not.
     */
    function displayCombo(animate:Bool = true, fade:Bool = true)
    {
    }

    /**
     * Makes a 'roll' animation for the combos (if it exists).
     * @param toNumber The number it will roll to. (IT WILL CHANGE THE COMBO VALUE!!)
     * @param totalRolls Total rolls the combo will do before revealing the combo.
     * @param fadeOut Whether the numbers should fade out after reveal
     */
    function comboRoll(toNumber:Int = 0, ?totalRolls:Int = 5, fadeOut:Bool = false)
    {
    }

    @:noCompletion public function set_skin(skin:String):String
    {
        this.skin = skin;

        if(Paths.exists('images/ingame/UI/judgements_combo/$skin/config.json'))
            data = Paths.JSON('images/ingame/UI/judgements_combo/$skin/config');
        else throw 'The data .JSON file for the combo and judgements were not found!';

        return this.skin;
    }

    @:noCompletion public function set_numsColor(color:FlxColor):FlxColor
    {
        this.numsColor = color;
        
        return this.numsColor;    
    }
}