package moon.menus.obj.freeplay;

import moon.dependency.scripting.MoonScript;
import flixel.group.*;

/**
 * Class used for freeplay's background, used for every DJ.
 */
class FreeplayBG extends FlxGroup
{
    /**
     * The background behind everything, even the display bg that shows the current week.
     */
    public var behindBG:FlxSpriteGroup = new FlxSpriteGroup();

    /**
     * The front bg, everything in it will be shown in front of the current week bg.
     */
    public var frontBG:FlxSpriteGroup = new FlxSpriteGroup();

    /**
     * The foreground BG, it is shown in front of everything.
     */
    public var foreground:FlxSpriteGroup = new FlxSpriteGroup();

    /**
     * This class' script.
     */
    public var script:MoonScript = new MoonScript();

    /**
     * Initiates this class, mostly just the script.
     * @param character The character folder's name.
     */
    public function new(character:String = 'bf')
    {
        super();
        script = new MoonScript();
        script.load('images/menus/freeplay/$character/scripts/BG.hx');
        Global.registerScript('freeplayBG', script);
    }
}