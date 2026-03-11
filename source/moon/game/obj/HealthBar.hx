package moon.game.obj;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import haxe.Json;
import flixel.ui.FlxBar;
import flixel.group.FlxSpriteGroup;

class HealthBar extends FlxSpriteGroup
{
    public var barBG:MoonSprite;
    public var bar:FlxBar;

    public var opponent(default, set):String;
    public var player(default, set):String;

    public var icons:Array<HealthIcon> = [];

    public var oppIcon:HealthIcon;
    public var playerIcon:HealthIcon;

    /**
     * The health ammount, which the healthbar tracks.
     */
    public var health(default, set):Float = 50;

    /**
     * The scale icons will have.
     */
    public var iconScale:Float = 0.8;

    /**
     * Will create a health bar instance.
     * @param opponent the opponent name.
     * @param player the player name.
     */
    public function new(opponent:String, player:String)
    {
        super();

        barBG = cast new MoonSprite().loadGraphic(Paths.image('ingame/UI/healthbar'));
        barBG.scale.set(0.9, 0.9);
        barBG.updateHitbox();

        bar = new FlxBar(RIGHT_TO_LEFT, Std.int(barBG.width - 16), Std.int(barBG.height - 8), null, null, 0, 100);
        bar.y = barBG.y + (barBG.height - bar.height) / 2;
        bar.x = barBG.x + (barBG.width - bar.width) / 2;

        add(bar);
        add(barBG);

        oppIcon = new HealthIcon();
        oppIcon.scale.set(iconScale, iconScale);
        oppIcon.y = bar.y - (oppIcon.height * 0.5);

        playerIcon = new HealthIcon();
        playerIcon.scale.set(0.5, 0.5);

        playerIcon.flipX = true;
        playerIcon.y = bar.y - (playerIcon.height * 0.5);

        add(oppIcon);
        add(playerIcon);

        icons.push(oppIcon);
        icons.push(playerIcon);

        this.opponent = opponent;
        this.player = player;

        bar.createFilledBar(getRGBData(opponent), getRGBData(player));
        health = bar.value = 50;
        playerIcon.screenCenter(X);
        oppIcon.screenCenter(X);
    }

    var count:Int = 4;
    public function performTransition(conductor:Conductor)
    {
        transitioning = true;
        count = 4;
        bar.scale.set(0, 1);
        barBG.scale.set(0, 1);
        oppIcon.scale.x = oppIcon.scale.y = playerIcon.scale.x = playerIcon.scale.y = 0;

        if(PlayField.instance.stats != null)
            PlayField.instance.stats.visible = false;

        new FlxTimer().start(conductor.crochet / 1000, _->
        {
            count--;

            switch(count)
            {
                case 3, 2: FlxTween.tween((count == 3 ? barBG : bar).scale, {x: (count == 3) ? 0.9 : 1}, conductor.crochet / 1000, {ease: FlxEase.expoOut});
                case 1: for(ico in [oppIcon, playerIcon]) FlxTween.tween(ico.scale, {x: iconScale, y: iconScale}, conductor.crochet / 1000, {ease: FlxEase.backOut});
                case 0: if(PlayField.instance.stats != null){
                        PlayField.instance.stats.scale.set(0, 0);
                        PlayField.instance.stats.visible = true;
                    }
                case -1: transitioning = false;
            }
        }, 5);
    }

    public var updateIconsPos:Bool = true;
    public var lerpPercent:Float = 0;
    public var transitioning:Bool = false;
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if(health >= 100) health = 101;
        bar.value = FlxMath.lerp(bar.value, health, elapsed * 8);

        if(updateIconsPos && MoonSettings.callSetting('Icons') == 'At Healthbar')
        {
            final percent = 1 - (health / 100);
            lerpPercent = FlxMath.lerp(lerpPercent, percent, elapsed * 16);
            final iconOffset = 16;
			
            playerIcon.x = bar.x + (bar.width * lerpPercent) + (150 * playerIcon.scale.x - 150) / 2 + iconOffset * 2;
            oppIcon.x = bar.x + (bar.width * lerpPercent) - (150 * oppIcon.scale.x) / 2 - iconOffset * 2;

            oppIcon.y = bar.y - (oppIcon.height * 0.5);
            playerIcon.y = bar.y - (playerIcon.height * 0.5);
        }
        
        if(!transitioning)
        {
            final scaleSpeed = elapsed * 18;
            oppIcon.scale.x = oppIcon.scale.y = FlxMath.lerp(oppIcon.scale.x, iconScale, scaleSpeed);
            playerIcon.scale.x = playerIcon.scale.y = FlxMath.lerp(playerIcon.scale.x, iconScale, scaleSpeed);
        }
    }

    public function updateBarStats()
    {
        playerIcon.icon = player;
        oppIcon.icon = opponent;

        playerIcon.antialiasing = getData(player)?.antialiasing ?? true;
        oppIcon.antialiasing = getData(opponent)?.antialiasing ?? true;
    }

    public function bump()
    {
        if(transitioning) return;
        oppIcon.scale.set(iconScale + 0.15, iconScale + 0.15);
        playerIcon.scale.set(iconScale + 0.15, iconScale + 0.15);
    }

    public function getRGBData(character:String)
    {
        final data:Character.CharacterData = getData(character);
        final c = (data != null) ? data.healthbarColors : [80, 80, 80];
        return FlxColor.fromRGB(c[0], c[1], c[2]);
    }

    public function getData(character:String):Character.CharacterData
        return (Paths.exists('characters/${character}/data.json')) ? Paths.JSON('characters/${character}/data') : null;

    @:noCompletion public function set_opponent(val:String)
    {
        this.opponent = val;
        updateBarStats();
        return val;
    }

    @:noCompletion public function set_player(val:String)
    {
        this.player = val;
        updateBarStats();
        return val;
    }

    @:noCompletion public function set_health(ammount:Float)
    {
        this.health = ammount;
        playerIcon.updateAnim(ammount);
        oppIcon.updateAnim(100 - ammount);
        return ammount;
    }
}