package moon.menus.obj.settings;

import flixel.math.FlxMath;
import moon.dependency.user.MoonSettings.Setting;
import moon.game.obj.*;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;

class OptionObject extends FlxSpriteGroup
{
    public static var separationWidth:Int = 596;
    public var setting:Setting;
    public var category:String;
    
    public var name:FlxText;
    public var value:FlxText;

    public var selected(default, set):Bool = false;

    public function new(?x:Float = 0, ?y:Float = 0, setting:Setting, category:String)
    {
        super(x, y);
        this.setting = setting;
        this.category = category;

        final font = Paths.font("phantomuff/full.ttf");
        final fontSize = 24;
        final halfWidth = separationWidth * 0.5;

        name = new FlxText(0, 0, separationWidth, setting.name);
        name.setFormat(font, fontSize, FlxColor.WHITE, LEFT);
        name.antialiasing = true;
        add(name);

        value = new FlxText(halfWidth, 0, halfWidth, (setting.type != SELECTABLE) ? Std.string(setting.value) : '');
        value.setFormat(font, fontSize, FlxColor.WHITE, RIGHT);
        value.antialiasing = true;
        add(value);

        changeValue(0);
    }

    private var holdTimer:Float = 0;
    private var holdDelay:Float = 0.40;
    private final holdThreshold:Float = 0.035;
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (selected && setting.type != INFO && (MoonInput.pressed(UI_LEFT) || MoonInput.pressed(UI_RIGHT)))
        {
            holdTimer -= elapsed;

            if (holdTimer <= 0)
            {
                var direction:Int = 0;

                if (MoonInput.pressed(UI_LEFT)) direction--;
                if (MoonInput.pressed(UI_RIGHT)) direction++;

                if (direction != 0)
                    changeValue(direction);

                holdDelay = Math.max(holdDelay * 0.9, holdThreshold);
                holdTimer = holdDelay;
            }
        }
        else
        {
            holdTimer = 0;
            holdDelay = 0.25;
        }

        if(FlxG.keys.justPressed.ANY && Global.allowInputs && setting.type != SELECTABLE) changeValue(0);

        if(MoonInput.justPressed(ACCEPT) && setting.type == SELECTABLE && selected)
        {
            // IF YOUR OPTION IS SELECTABLE YOU MUST ADD WHAT IT DOES HERE!@!@
            switch(setting.name)
            {
                case 'Keybinds...': FlxG.state.openSubState(new Keybinds());
                case 'HUD Customization...': FlxG.state.openSubState(new JudgementsComboCustomize());
                case "Calculate Offset...": FlxG.state.openSubState(new Offset());
            }
        } 
    }

    public function changeValue(amount:Int)
    {
        switch(setting.type)
        {
            case CHECKMARK:
                if(amount != 0)
                    setting.value = !setting.value;

                value.text = (setting.value) ? "< On >" : "< Off >";

                if(amount != 0)
                    Paths.playSFX('menus/settings/settings${setting.value ? "ON" : "OFF"}.wav');
            
            case SELECTOR:
                final opts:Array<Dynamic> = setting.options;
                if(opts != null && opts.length > 0)
                {
                    var idx:Int = opts.indexOf(setting.value);
                    if (idx < 0) idx = 0;
                    
                    idx = FlxMath.wrap(idx + amount, 0, opts.length - 1);                    
                    setting.value = opts[idx];
                }

                value.text = '< ${setting.value} >';

                final str = value.text.toLowerCase() == '< on >' ? "ON" : value.text.toLowerCase() == '< off >' ? "OFF" : 'Selection';
                if(amount != 0)
                    Paths.playSFX('menus/settings/settings$str.wav');

            case SLIDER:
                var filledLength:Int = Math.round((setting.value - setting.options[0]) / (setting.options[1] - setting.options[0]) * 10);
                var filled:String = "";
                var unfilled:String = "";
                for (i in 0...filledLength) filled += "| ";
                for (i in filledLength...10) unfilled += "-";

                setting.value = FlxMath.wrap(setting.value + amount, setting.options[0], setting.options[1]);
                value.text = '< ${setting.value}% > [$filled$unfilled]';

                if(amount != 0)
                    Paths.playSFX('menus/settings/settingsMeterChange.wav');

            case UNCAP_SLIDER:
                setting.value += amount;
                value.text = '< ${setting.value} >';

                if(amount != 0)
                    Paths.playSFX('menus/settings/settingsMeterChange.wav');

            case INFO: value.text = '( ${setting.defaultValue} )';

            case SELECTABLE: return;
        }

        if(amount != 0)
        {
            MoonSettings.setSetting(setting.name, setting.value);
            MoonSettings.updateGlobalSettings();

            if(setting.name == 'Window Resolution' || setting.name == 'Screen Mode')
                MoonSettings.updateWindow();

            if(PlayField.instance != null)
               PlayField.instance.settingsUpdate(); 
        }
    }

    @:noCompletion public function set_selected(value:Bool):Bool
    {
        this.selected = value;
        this.color = (selected) ? ((setting.type == INFO) ? FlxColor.GRAY : FlxColor.BLACK) : 0xffffffff;
        return selected;
    }
}
