package moon.toolkit.ui;

class EditorPopup extends FlxSubState
{
    public var callback:String->Void;

    var bg:MoonSprite;
    var textTitle:FlxText = new FlxText();
    var textDescription:FlxText = new FlxText();
    //var button1:PopupButton;

    public function new(type:PopupType, info:{title:String, description:String, button1:String, button2:String}, coverBG:Bool = true)
    {
        super();

        bg = new MoonSprite();
        bg.frames = Tilemap.getAtlasFrames("mainUI");
        bg.frame = Tilemap.getFrame('popupBox', 'mainUI');
        bg.screenCenter();
        add(bg);

        textTitle.setFormat(Paths.font('phantomuff/difficulty.ttf'), 32, FlxColor.WHITE, CENTER);
        textTitle.fieldWidth = Std.int(bg.width / 1.5);
        textTitle.text = info.title;
        textTitle.screenCenter(X);
        textTitle.antialiasing = true;
        add(textTitle);
        textTitle.y = bg.y + 48;

        textDescription.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 20, FlxColor.WHITE, CENTER);
        textDescription.fieldWidth = textTitle.fieldWidth;
        textDescription.text = info.description;
        textDescription.screenCenter();
        textDescription.antialiasing = true;
        add(textDescription);

        textDescription.active = textTitle.active = bg.active = false;

        for(aa in this.members)
        {
            if(Std.isOfType(aa, FlxSprite))
            {
                final obj = cast(aa, FlxSprite);
                obj.scale.set(0, 0);
                FlxTween.tween(obj.scale, {x: 1, y: 1}, 0.35, {ease: FlxEase.backOut});
            }
        }

        final p = '$type'.toUpperCase();
        FlxG.sound.play(Paths.sound('toolkit/general/popup$p.wav', 'sounds'), MoonSettings.callSetting('Editor Sounds') / 100);
    }
}

enum PopupType {
    NOTICE;
    INFO;
    WARNING;
    ERROR;
    SMALL;
}