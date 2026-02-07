package moon.game.obj;

import moon.dependency.scripting.*;

using StringTools;

typedef CharacterData =
{
    var ?antialiasing:Bool;
    var ?scale:Float;
    var flipX:Bool;
    var camOffsets:Array<Float>;
    var healthbarColors:Array<Int>;
    var danceFrequency:Int;
    var animations:Array<Paths.AnimationData>;
    var ?overrideAnims:Array<String>;
}

class Character extends MoonSprite
{
    public var data:CharacterData;

    public var conductor:Conductor;
    public var character(default, set):String;
    public var animationHold:Float = 0;
    public var script:MoonScript;
    public var danceFrequency:Int = 2;

    public var camOffsets:Array<Float> = [];

    /**
     * Creates a character on the screen.
     * @param x X Position.
     * @param y Y Position.
     * @param character The character name.
     * @param conductor The conductor instance.
     */
    public function new(?x:Float = 0, ?y:Float = 0, ?character:String = 'dad', conductor:Conductor)
    {
        super(x, y);
        this.conductor = conductor;

        script = new MoonScript();

        this.character = character;

        if(conductor != null) conductor.onBeat.add(checkDance);
    }
   
    public function flipLeftRight():Void
    {
        final oldRight = animation.getByName('singRIGHT').frames;
        animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
        animation.getByName('singLEFT').frames = oldRight;
        if (animation.getByName('singRIGHTmiss') != null)
        {
            final oldMiss = animation.getByName('singRIGHTmiss').frames;
            animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
            animation.getByName('singLEFTmiss').frames = oldMiss;
        }
    }

    public function checkDance(curBeat:Float)
    {
        if (animation.curAnim == null) return;
        if (animation.curAnim.name.startsWith('sing') || animation.curAnim.name.startsWith('miss'))
            animationHold += conductor.stepCrochet;

        final beatInt = Std.int(curBeat);
        if ((animation.curAnim.name.startsWith("idle") || animation.curAnim.name.startsWith("dance"))
            && (beatInt % danceFrequency == 0) && (beatInt != lastDanceBeat))
        {
            lastDanceBeat = beatInt;
            this.dance(true);
        }
    }
       
    override public function update(elapsed:Float)
    {
        if (conductor != null && animationHold >= conductor.stepCrochet * 3)
        {
            dance(true);
            animationHold = 0;
        }
        super.update(elapsed);
    }

    override public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
    {
        super.playAnim(animName, force, reversed, frame);

        if(animation.curAnim != null)
        {
            if(animation.curAnim.name.startsWith('idle') || animation.curAnim.name.startsWith('sing'))
                animationHold = 0;
        }
    }

    @:noCompletion public function set_character(char:String):String
    {
        if(Global.scripts.exists(this.character))
            Global.unregisterScript(this.character);

        if(!Paths.exists('characters/$char/data.json'))
        {
            trace('Specified character "$char" data does not exist. Loading default...', "WARNING");
            char = 'darnell';
        }
       
        this.character = char;
        data = cast Paths.JSON('characters/$character/data');
        camOffsets = data.camOffsets;
        this.frames = Paths.getSparrowAtlas('$character/$character', 'characters');

        overrideAnims = data?.overrideAnims ?? [];
        idleAnims = loadAnimations(data.animations);
        danceFrequency = data.danceFrequency;

        this.antialiasing = data?.antialiasing ?? true;
        this.scale.set(data?.scale ?? 0, data?.scale ?? 0);
        this.updateHitbox();
        this.playAnim("idle-0");

        script.load('characters/${this.character}/script');
        if(script.code != null)
        {
            script.set('char', this);
            Global.registerScript('script-${this.character}', script);
        }

        /*animation.onFinish.add((anim)->
        {
            //TODO: 'Softcode' this :3
            // DONE!
            //if(conductor != null && (anim == 'comboBreak' || anim == 'combo50' || anim == 'combo200')) dance(true);
        }); */

        this.flipX = data?.flipX ?? false;
        origin.set(width / 2, height);

        return char;
    }
}