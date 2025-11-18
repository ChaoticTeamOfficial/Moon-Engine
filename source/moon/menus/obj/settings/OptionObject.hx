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

        final fontSize = 28;
        final totalWidth:Float = 850;
        final halfWidth:Float = totalWidth * 0.5;

        name = new FlxText(0, 0, halfWidth, setting.name);
        name.setFormat(Paths.font("vcr.ttf"), fontSize, FlxColor.WHITE, LEFT);
        name.textField.antiAliasType = ADVANCED;
        name.antialiasing = false;
        name.textField.sharpness = Settings.textSharpness;
        add(name);

        value = new FlxText(halfWidth, 0, halfWidth, (setting.type != SELECTABLE) ? Std.string(setting.value) : '');
        value.setFormat(Paths.font("vcr.ttf"), fontSize, FlxColor.WHITE, RIGHT);
        value.textField.antiAliasType = ADVANCED;
        value.antialiasing = false;
        value.textField.sharpness = Settings.textSharpness;
        add(value);

        changeValue(0);
    }

    private var holdTimer:Float = 0;
    private var holdDelay:Float = 0.40;
    private final holdThreshold:Float = 0.04;
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
                {
                    Paths.playSFX('menus/settings/configClick.ogg');
                    changeValue(direction);
                }

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
                case 'Keybinds...': FlxG.state.openSubState(new Keybinds(this.camera));
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
            case SLIDER:
                var filledLength:Int = Math.round((setting.value - setting.options[0]) / (setting.options[1] - setting.options[0]) * 10);
                var filled:String = "";
                var unfilled:String = "";
                for (i in 0...filledLength) filled += "|";
                for (i in filledLength...10) unfilled += "-";

                setting.value = FlxMath.wrap(setting.value + amount, setting.options[0], setting.options[1]);
                value.text = '< ${setting.value}% > [$filled$unfilled]';
            case UNCAP_SLIDER:
                setting.value += amount;
                value.text = '< ${setting.value} >';
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
        this.color = (selected) ? ((setting.type == INFO) ? 0xff947642 : 0xFFfea711) : 0xffffffff;
        return selected;
    }
}
