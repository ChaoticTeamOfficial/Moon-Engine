package moon.game.obj;

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

    public var idleAnims:Array<String>;
    public var conductor:Conductor;
    public var character(default, set):String;
    public var animationHold:Float = 0;

    var danceIndex:Int = 0;
    var lastDanceBeat:Int = -1;

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
            && (beatInt % data.danceFrequency == 0) && (beatInt != lastDanceBeat))
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

    public function dance(?force:Bool = false)
    {
        if (idleAnims != null && idleAnims.length > 0)
        {
            playAnim(idleAnims[danceIndex], force);
            danceIndex = (danceIndex + 1) % idleAnims.length;
        }
        else
        {
            if(animation.exists("idle-0"))
            {
                playAnim("idle-0", force);
                danceIndex = 0;
            }
        }
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
        if(!Paths.exists('characters/$char/data.json'))
        {
            trace('Specified character "$char" does not exist. Loading default...', "ERROR");
            char = 'darnell';
        }
       
        this.character = char;
        data = cast Paths.JSON('characters/$character/data');
        this.frames = Paths.getSparrowAtlas('$character/$character', 'characters');
        idleAnims = [];

        overrideAnims = data?.overrideAnims ?? [];
        for (i in 0...data.animations.length)
        {
            final anim:Paths.AnimationData = data.animations[i];
            (anim.indices != null)
            ? this.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.fps ?? 24, anim.looped ?? false)
            : this.animation.addByPrefix(anim.name, anim.prefix, anim.fps ?? 24, anim.looped ?? false);
            this.addOffset(anim.name, anim.x ?? 0, anim.y ?? 0);
           
            if(anim.name.startsWith("idle-"))
                idleAnims.push(anim.name);

            // aa
            if(anim.finishAnim != null)
                animation.onFinish.add((anim) -> {
                    if(animation.curAnim != null && animation.curAnim.name == data.animations[i].name)
                        playAnim(data.animations[i].finishAnim, true); //compiler being ass moment
                });
        }

        this.antialiasing = data?.antialiasing ?? true;
        this.scale.set(data?.scale ?? 0, data?.scale ?? 0);
        this.updateHitbox();
        this.playAnim("idle-0");

        /*animation.onFinish.add((anim)->
        {
            //TODO: 'Softcode' this :3
            // DONE!
            //if(conductor != null && (anim == 'comboBreak' || anim == 'combo50' || anim == 'combo200')) dance(true);
        }); */

        this.flipX = data?.flipX ?? false;

        return char;
    }
}