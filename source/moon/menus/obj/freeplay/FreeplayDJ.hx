package moon.menus.obj.freeplay;

import moon.dependency.scripting.MoonScript;
import animate.FlxAnimateFrames;

class FreeplayDJ extends MoonSprite
{
    /**
     * Timer used for playing AFK Animations.
     */
    public var AFK_TIMER:Float = 0;

    /**
     * Wheter or not to allow the dj to dance on beat.
     */
    public var canDance:Bool = false;

    /**
     * Script used for this DJ.
     */
    public var script:MoonScript;

    public function new(character:String = 'bf')
    {
        super();

        script = new MoonScript();
        script.load('images/menus/freeplay/$character/scripts/DJ.hx');
        Global.registerScript('freeplayDJ', script);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        AFK_TIMER += elapsed;
    }
}