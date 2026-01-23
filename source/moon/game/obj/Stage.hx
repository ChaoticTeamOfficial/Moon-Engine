package moon.game.obj;

import moon.backend.gameplay.InputHandler;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import openfl.display.BlendMode;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;

import moon.dependency.scripting.*;

/**
 * The background for songs.
 */
class Stage extends FlxTypedGroup<FlxBasic>
{
    /**
     * The stage name itself, name must match the folder it's in.
     */
    public var stage(default, set):String;

    /**
     * All the camera settings.
     */
    public var cameraSettings:{?zoom:Float, ?startX:Float, ?startY:Float};

    /**
     * Background's spectators.
     */
    public var spectators:FlxSpriteGroup = new FlxSpriteGroup();

    /**
     * Background's opponents.
     */
    public var opponents:FlxSpriteGroup = new FlxSpriteGroup();

    /**
     * Background's players.
     */
    public var players:FlxSpriteGroup = new FlxSpriteGroup();

    /**
     * An array containing every character in the stage.
     */
    public var chars:Array<Character> = [];

    /**
     * Conductor used for calling beat hit and amongst other stuff.
     */
    public var conductor:Conductor;

    /**
     * The stage script.
     */
    public var script:MoonScript;

    public function new(stage:String = 'stage', conductor:Conductor)
    {
        super();
        this.conductor = conductor;

        script = new MoonScript();
        Global.registerScript('stageScript', script);
        this.stage = stage;
    }

    @:noCompletion public function set_stage(stg:String):String
    {
        if (!Paths.exists('images/ingame/stages/$stg/script.hx'))
        {
            trace('The specified stage "$stg" does not have an hx file at "assets/images/ingame/stages/$stg". Loading default...', "WARNING");
            stg = 'void';
        }

        this.stage = stg;
        script.load('images/ingame/stages/$stg/script.hx');
        script.set("background", this);
        script.call('onCreate');

        return stg;
    }

    var index:Int = 0;

    /**
     * Adds a char to a specific group.
     * @param charName The name of the character (e.g. darnell)
     * @param group The group in which the character will be added to.
     * @param attachedInputs The input handler for the character (necessary if you want it to sing when a note is hit.)
     */
    public function addCharTo(charName:String, group:FlxSpriteGroup, ?attachedInputs:InputHandler)
    {
        group.recycle(Character, function():Character
        {
            var char = new Character(0 + (900 * group.members.length), 0, charName, conductor);
            char.ID = index;
            chars.push(char);
            
            if(attachedInputs != null) attachedInputs.attachedChar = char;
            index++;
            return char;
        });
    }

    public function adjustGroupColor(group:FlxSpriteGroup, values:{?hue:Float, ?saturation:Float, ?brightness:Float, ?contrast:Float})
    {
        var shader = new MoonShader('AdjustColor');
        shader.script.call("setValues", [values?.hue ?? 0, values?.saturation ?? 0,values?.brightness ?? 0, values?.contrast ?? 0]);

        for(i in 0...group.members.length) group.members[i].shader = shader;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }
}
