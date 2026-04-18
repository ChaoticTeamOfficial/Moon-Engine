package moon.game.obj;

import moon.backend.gameplay.InputHandler;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import openfl.display.BlendMode;
import flixel.addons.display.FlxBackdrop;
import moon.dependency.scripting.*;
import moon.game.obj.Character.CharacterType;

using StringTools;

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

    public var json:StageJSONStructure;

    var objMap:Map<String, MoonSprite> = [];
    var dancingSprites:Array<MoonSprite> = [];

    var opponentCharData:StageCharacter;
    var playerCharData:StageCharacter;
    var spectatorCharData:StageCharacter;

    // sucks to be me
    private var blendModes:Map<String, BlendMode> = [
        "ADD" => ADD,
        "ALPHA" => ALPHA,
        "DARKEN" => DARKEN,
        "DIFFERENCE" => DIFFERENCE,
        "ERASE" => ERASE,
        "HARDLIGHT" => HARDLIGHT,
        "INVERT" => INVERT,
        "LAYER" => LAYER,
        "LIGHTEN" => LIGHTEN,
        "MULTIPLY" => MULTIPLY,
        "NORMAL" => NORMAL,
        "OVERLAY" => OVERLAY,
        "SCREEN" => SCREEN,
        "SHADER" => SHADER,
        "SUBTRACT" => SUBTRACT
    ];

    public function new(stage:String = 'stage', conductor:Conductor)
    {
        super();
        this.conductor = conductor;
        
        script = new MoonScript();
        Global.registerScript('stageScript', script);
        this.stage = stage;

        script.set('add', this.add);
        script.set('insert', this.insert);
        script.set('getObject', this.getObject);
        script.set('members', this.members);

        if(conductor != null) conductor.onBeat.add(onStageBeat);
    }

    private function setType(group:FlxSpriteGroup, type:CharacterType)
    {
        for(member in group.members)
            if(Std.isOfType(member, Character))
                cast(member, Character).type = type;
    }

    @:noCompletion public function set_stage(stg:String):String
    {
        //if (!Paths.exists('images/ingame/stages/$stg/script.hx'))
        //    trace('The specified stage "$stg" does not have an hx file at "assets/images/ingame/stages/$stg"!', "WARNING");
        script.load('stages/$stg/script.hx');
        script.set("background", this);

        this.stage = stg;

        // nice lil fallback if theres no json
        json = cast Paths?.JSON('stages/$stg/data') ?? cast {
            camSettings: {
                zoom: 1,
                startX: 751.5,
                startY: 300
            },
            characters: [
                {
                    type: "opponent",
                    position: [64.0, 396.0],
                    objectBehind: null
                },
                {
                    type: "player",
                    position: [916.0, 396.0],
                    objectBehind: null
                },
                {
                    type: "spectator",
                    position: [296.0, 374.0],
                    objectBehind: null
                }
            ]
        };

        //trace(json);

        cameraSettings = json.camSettings;

        if(json.objects != null && json.objects.length > 0)
        {
            for (objData in json.objects)
            {
                var sprite = new MoonSprite(objData.position[0], objData.position[1]);
                sprite.strID = objData.name;

                final assetPath = '$stg/${objData.name}';
                switch (objData.type)
                {
                    case SPARROW:
                        sprite.frames = Paths.getSparrowAtlas(assetPath, 'stages');
                    case PACKED:
                        sprite.frames = Paths.getPackerAtlas(assetPath, 'stages');
                    default: sprite.loadGraphic(Paths.image(assetPath, 'stages'));
                }

                if (objData.scale != null) sprite.scale.set(objData.scale[0], objData.scale[1]);
                if (objData.scroll != null) sprite.scrollFactor.set(objData.scroll[0], objData.scroll[1]);

                sprite.angle = objData?.angle ?? 0;
                sprite.alpha = objData?.alpha ?? 1;
                sprite.antialiasing = objData?.antialiasing ?? true;
                sprite.flipX = objData?.flipX ?? false;
                sprite.flipY = objData?.flipY ?? false;
                if (objData.blend != null) sprite.blend = blendModes.get(objData.blend.toUpperCase());

                if(objData.animations != null && objData.animations.length > 0)
                    sprite.idleAnims = sprite.loadAnimations(objData.animations);

                if (objData.startAnim != null)
                    sprite.playAnim(objData.startAnim);

                if (objData.animBehavior != null && objData.type != NONE)
                {
                    switch (objData.animBehavior)
                    {
                        case ONBEAT: dancingSprites.push(sprite);
                        case ONCE: if (objData.startAnim != null) sprite.playAnim(objData.startAnim, true);
                    }
                }

                add(sprite);
                objMap.set(objData.name, sprite);
            }
        }

        if(script != null && script.exists('onCreate'))
			script.call('onCreate');

        return stg;
    }

    public function getObject(name:String):MoonSprite
    {
        if(objMap.exists(name)) return objMap.get(name);

        trace('[STAGE] $name wasn\'t found in the stage objects!', "WARNING");
        return null;
    }

    public function updatePositioning()
    {
        if (json == null) return;
        for (i in 0...json.characters.length)
		{
			final character = json.characters[json.characters.length - 1 - i];

			switch (character.type)
			{
				case OPPONENT:
					opponentCharData = character;
					addGroupAtLayer(opponents, opponentCharData, objMap);
					opponents.origin.set(opponents.width / 2, opponents.height);
					setType(opponents, OPPONENT);

				case PLAYER:
					playerCharData = character;
					addGroupAtLayer(players, playerCharData, objMap);
					players.origin.set(players.width / 2, players.height);
					setType(players, PLAYER);

				case SPECTATOR:
					spectatorCharData = character;
					addGroupAtLayer(spectators, spectatorCharData, objMap);
					spectators.origin.set(spectators.width / 2, spectators.height);
					setType(spectators, SPECTATOR);
			}
		}
    }

    private function addGroupAtLayer(group:FlxSpriteGroup, charData:StageCharacter, objMap:Map<String, MoonSprite>)
    {
        if (charData == null) return;

        group.x = charData?.position[0] ?? 0.0;
        group.y = charData?.position[1] ?? 0.0;
        group.angle = charData?.angle ?? 0.0;
        if (charData.scale != null) group.scale.set(charData?.scale[0] ?? 1, charData?.scale[1] ?? 1);

        for(obj in group.members)
            if(Std.isOfType(obj, Character))
                if (charData.camOffsets != null) cast(obj, Character).camOffsets = charData.camOffsets;

        var insertIndex:Int = length;
        if (charData.objectBehind != null)
        {
            final behindSprite = objMap.get(charData.objectBehind);
            if (behindSprite != null)
                insertIndex = members.indexOf(behindSprite) + 1;
        }
        insert(insertIndex, group);
        //add(group);
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
            var char = new Character(0, 0, charName, conductor);
            char.ID = index;
            chars.push(char);

            if(char.data.extraOffsets != null)
            {
                char.x += char?.data?.extraOffsets[0] ?? 0;
                char.y += char?.data?.extraOffsets[1] ?? 0;
            }
            
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

    public function onStageBeat(curBeat:Float)
    {
        for (sprite in dancingSprites)
        {
            if (sprite.animation.curAnim == null) continue;

            final beatInt = Std.int(curBeat);
            if ((sprite.animation.curAnim.name.startsWith("idle") || sprite.animation.curAnim.name.startsWith("dance")) && (beatInt != sprite.lastDanceBeat))
            {
                sprite.lastDanceBeat = beatInt;
                sprite.dance(true);
            }
        }
    }
}

typedef StageJSONStructure = {
    var camSettings:{?zoom:Float, ?startX:Float, ?startY:Float};
    var objects:Array<StageObject>;
    var characters:Array<StageCharacter>;
}

typedef StageObject = {
    //TODO: ADD A COLOR FIELD

    var name:String;
    var position:Array<Float>;
    var ?type:AtlasType;
    var ?scale:Array<Float>;
    var ?scroll:Array<Float>;
    var ?angle:Float;
    var ?alpha:Float;
    var ?antialiasing:Bool;
    var ?flipX:Bool;
    var ?flipY:Bool;

    var ?blend:String;
    var ?animations:Array<AnimationData>;
    var ?animBehavior:AnimBehavior;
    var ?startAnim:String;
}

typedef StageCharacter = {
    var type:CharacterType;
    var position:Array<Float>;
    var objectBehind:String;
    var ?camOffsets:Array<Float>;
    var ?scale:Array<Float>;
    var ?angle:Float;
}