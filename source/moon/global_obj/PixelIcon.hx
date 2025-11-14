package moon.global_obj;

class PixelIcon extends MoonSprite
{
    public var character(default, set):String;

    public function new(?x:Float = 0, ?y:Float = 0, chara:String = 'dummy')
    {
        super(x, y);
        this.character = chara;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }
    
    var data:Dynamic;
    @:noCompletion public function set_character(iconName:String):String
    {
        this.origin.x = 100;
        this.scale.set(2, 2);

        final actualIcon = (Paths.exists('characters/$iconName/ui_icon.png')) ? iconName : 'dummy';
        this.character = actualIcon;

        this.frames = Paths.getSparrowAtlas('$actualIcon/ui_icon', 'characters');
        this.centerAnimations = true;
        this.animation.addByPrefix('idle', 'idle0', 12, true);
        this.animation.addByPrefix('select', 'confirm0', 12, false);
        this.animation.addByPrefix('select-hold', 'confirm-hold0', 12, true);
  
        this.animation.onFinish.add((name) -> this.playAnim((name == 'select') ? 'select-hold' : null));
        this.playAnim('idle');

        return this.character;
    }
}