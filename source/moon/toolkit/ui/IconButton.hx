package moon.toolkit.ui;

class IconButton extends FlxSpriteGroup
{
    public var callback:Void->Void;
    public var isPressed(default, set):Bool = false;
    public var invertShader:InvertColor;

    var bg:MoonSprite;
    var icon:MoonSprite;
    public function new(x:Float, y:Float, width:Int, height:Int, iconName:String, color:FlxColor = FlxColor.BLACK)
    {
        super(x, y);

        //THIS DOESNT BATCHHH AAUUGHHHH!!!

        bg = new MoonSprite().makeGraphic(width, height, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRoundRect(bg, 0, 0, width, height, 16, 16, color);
        bg.antialiasing = true;
        bg.active = false;
        add(bg);

        icon = new MoonSprite();
        icon.frames = Tilemap.getAtlasFrames("btnIcons");
        icon.frame = Tilemap.getFrame(iconName, 'btnIcons');
        icon.active = false;
        icon.antialiasing = true;
        add(icon);

        icon.setGraphicSize(32, 32);
        icon.updateHitbox();
        icon.setPosition(x + bg.width / 2 - icon.width / 2, y + bg.height / 2 - icon.height / 2);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.mouse.overlaps(bg, camera))
            if (FlxG.mouse.justPressed)
            {
                isPressed = !isPressed;
                if (isPressed)
                    if (callback != null) callback();
            }
    }

    @:noCompletion public function set_isPressed(isPressed:Bool):Bool
    {
        this.isPressed = isPressed;
        bg.shader = icon.shader = (isPressed) ? invertShader : null;
        return this.isPressed;
    }
}