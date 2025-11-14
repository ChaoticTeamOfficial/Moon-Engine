package moon.game.obj;

import flixel.FlxG;

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
     * @param x         X Position.
     * @param y         Y Position.
     * @param character The character name.
     * @param conductor The conductor instance.
     */
    public function new(?x:Float = 0, ?y:Float = 0, ?character:String = 'dad', conductor:Conductor)
    {
        super(x, y);
        this.conductor = conductor;
        this.character = character;
        conductor.onBeat.add(checkDance);
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
        var beatInt = Std.int(curBeat);
        if ((animation.curAnim.name.startsWith("idle") || animation.curAnim.name.startsWith("dance"))
            && (beatInt % data.danceFrequency == 0) && (beatInt != lastDanceBeat))
        {
            lastDanceBeat = beatInt;
            this.dance(true);
        }
    }
        
    override public function update(elapsed:Float)
    {        
        if (animationHold >= conductor.stepCrochet * 3) 
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

        for (i in 0...data.animations.length)
        {
            final anim = data.animations[i];
            (anim.indices != null)
            ? this.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.fps ?? 24, anim.looped ?? false)
            : this.animation.addByPrefix(anim.name, anim.prefix, anim.fps ?? 24, anim.looped ?? false);
            this.addOffset(anim.name, anim.x ?? 0, anim.y ?? 0);
            
            if(anim.name.startsWith("idle-"))
                idleAnims.push(anim.name);
        }

        this.antialiasing = data?.antialiasing ?? true;
        this.scale.set(data?.scale ?? 0, data?.scale ?? 0);

        this.updateHitbox();
        this.playAnim("idle-0");

        animation.onFinish.add((anim)->
        {
            if(anim == 'comboBreak' || anim == 'combo50' || anim == 'combo200') dance(true);
        });
		
		this.flipX = data?.flipX ?? false;
        return char;
    }
}