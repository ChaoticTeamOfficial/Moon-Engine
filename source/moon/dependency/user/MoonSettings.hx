package moon.dependency.user;

import moon.menus.Settings;
import openfl.system.Capabilities;
import lime.app.Application;
import openfl.filters.ColorMatrixFilter;

using StringTools;

/**
 * An Enum that holds all the setting types.
 */
enum abstract SettingType(String) to String
{
    /**
     * For a setting that's either true or false.
     */
    var CHECKMARK = 'checkmark';

    /**
     * For a setting that holds multiple choices.
     */
    var SELECTOR = 'selector';

    /**
     * For a setting that goes from 0 to 100.
     */
    var SLIDER = 'slider';

    /**
     * For a numeric setting that can be any number value.
     */
    var UNCAP_SLIDER = 'uncap_slider';

    /**
     * For a visual setting.
     */
    var INFO = 'info';

    /**
     * For a setting that can redirect to somewhere else.
     */
    var SELECTABLE = 'selectable';
}

/**
 * Class that represents a single setting.
 */
class Setting
{
    /**
     * The setting's name, which'll be displayed in the options menu, and also needed for when calling it.
     */
    public var name:String;

    /**
     * The setting type. Allowed types are: CHECKMARK, SELECTOR, SLIDER.
     */
    public var type:SettingType;

    /**
     * The description of this setting, shown in the settings menu.
     */
    public var description:String;

    /**
     * For SELECTOR: Array<String> or Array<Int>.
     * For SLIDER: [min, max].
     * For CHECKMARK: null.
     */
    public var options:Dynamic;

    /**
     * The default value for this setting, useful for when resetting settings.
     */
    public var defaultValue:Dynamic;

    /**
     * The value of this setting.
     */
    public var value:Dynamic;

    /**
     * If true and changed during gameplay, the player is prompted to restart the song.
     */
    public var forceRestart:Bool;

    /**
     * Creates a new setting.
     * @param name          The setting's name, which'll be displayed in the options menu, and also needed for when calling it.
     * @param type          The setting's type. Allowed types are: CHECKMARK, SELECTOR, SLIDER.
     * @param options       The setting's options, slider = [minVal, maxVal], selector = [values], checkmark = null.
     * @param defaultValue  The setting's default value.
     */
    public function new(name:String, type:SettingType, options:Dynamic, defaultValue:Dynamic, forceRestart:Bool = false)
    {
        this.name = name;
        this.type = type;
        this.description = 'No description found.';
        this.options = options;
        this.defaultValue = defaultValue;
        this.value = defaultValue;
        this.forceRestart = forceRestart;
    }

    public function reset():Void
        value = defaultValue;
}

@:publicFields
class MoonSettings
{
    /**
     * Settings organized by category.
     */
    static var categories:Map<String, Array<Setting>> = new Map();

    static var save:FlxSave = new FlxSave();

    /**
     * Set to true when a forceRestart setting is changed during gameplay.
     * The pause menu reads this to prompt the player to restart.
     */
    static var restartPending:Bool = false;

    static function init():Void
    {
        save.bind(Constants.SETTINGS_SAVE_BIND);
        buildSettings();
        loadSettings();
        MoonInput.loadControls();
    }

    static final categoryOrder:Array<String> = [
        "Video Settings", "Sound Settings", "Gameplay Settings",
        "Interface Settings", "Graphic Settings", "Engine Settings"
    ];

    private static function buildSettings():Void
    {
        categories.set("Video Settings",
        [
            new Setting("Screen Mode", SELECTOR, ["Windowed", "Fullscreen", "Borderless Fullscreen"], "Windowed"),
            new Setting("Window Resolution", SELECTOR,
            ["800x600", "1024x768", "1280x720", "1280x800", "1366x768", "1440x900",
            "1600x900", "1680x1050", "1920x1080", "2560x1440", "3840x2160"], "1280x720")
        ]);

        categories.set("Sound Settings",
        [
            new Setting("Master Volume", SLIDER, [0, 100], 100),
            new Setting("Instrumental Volume", SLIDER, [0, 100], 100),
            new Setting("Voices Volume", SLIDER, [0, 100], 100),
            new Setting("Music Volume", SLIDER, [0, 100], 60),
            new Setting("SFX Volume", SLIDER, [0, 100], 80),
            new Setting("Ranking Sound", CHECKMARK, null, false),
            new Setting("Mute Voices on Miss", CHECKMARK, null, true)
        ]);

        categories.set("Gameplay Settings",
        [
            new Setting("Keybinds...", SELECTABLE, null, null),
            new Setting("Note Offset", UNCAP_SLIDER, null, 0),
            new Setting("Calculate Offset...", SELECTABLE, null, null),
            new Setting("Downscroll", CHECKMARK, null, false),
            new Setting("Middlescroll", CHECKMARK, null, false),
            new Setting("HUD Customization...", SELECTABLE, null, null),
            new Setting("Note Splashes", CHECKMARK, null, true),
            new Setting("Hold Note Splashes", CHECKMARK, null, true),
            new Setting("Lane Background Visibility", SELECTOR, [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1], 0),
            new Setting("Ghost Tapping", CHECKMARK, null, true, true),
            new Setting("Mechanics", CHECKMARK, null, true, true),
            new Setting("Modchart", CHECKMARK, null, true, true)
        ]);

        categories.set("Graphic Settings",
        [
            new Setting("FPS Cap", SELECTOR, [30, 60, 120, 144, 240, 360], 60),
            new Setting("Shaders", CHECKMARK, null, true),
            new Setting("Flashing Lights", CHECKMARK, null, true),
            new Setting("Colorblind Filters", SELECTOR, ["Off", "Tritan", "Protan", "Deutran"], "Off")
        ]);

        categories.set("Interface Settings",
        [
            new Setting("Language", SELECTOR, MoonLang.getDisplayNames(), MoonLang.getDisplayNames()[0]),
            new Setting("Healthbar Visibility", SELECTOR, ["On", "Below 100%", "Off"], "On"),
            new Setting("Show Accuracy", SELECTOR, ["Off", "Approximate", "Full"], "Full"),
            new Setting("Stats Position", SELECTOR, ["On HP-Bar", "On Player Lane"], "On HP-Bar"),
            new Setting("Icons", SELECTOR, ["Off", "At Healthbar", "On Lanes"], "At Healthbar"),
            new Setting("Show FPS", CHECKMARK, null, false)
        ]);

        categories.set("Engine Settings",
        [
            new Setting("Auto-Updates", SELECTOR, ["Off", "In-Game", "Redirect"], "In-Game"),
            new Setting("Experimental Features", CHECKMARK, null, false, true),
            new Setting("Modding Tools", CHECKMARK, null, false),
            new Setting("Moon Engine Version", INFO, null, 'v.${Application.current.meta.get('version')}')
        ]);

        // ----------- INTERNAL STUFF!!! 
        categories.set("Internal",
        [
            new Setting("Game Character", SELECTOR, ['bf'], 'bf'),
            new Setting("JudgePos", SELECTOR, [], [500, 270]),
            new Setting("ComboPos", SELECTOR, [], [500, 340])
        ]);

        categories.set("Judgement Customization",
        [
            new Setting('Judgement Custom Position', SELECTOR, ["On", "Track-Based", "Center"], 'Center'),
            new Setting('Judgement Spawn Animation', SELECTOR, JudgementsCombo.getSpawnList(), 'jump-in'),
            new Setting('Judgement Despawn Animation', SELECTOR, JudgementsCombo.getDespawnList(), 'fade')
        ]);

        categories.set("Combo Customization",
        [
            new Setting('Combo Custom Position', SELECTOR, ["On", "Track-Based", "Center"], 'Center'),
            new Setting('Combo Spacing', SELECTOR, [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1], 0.5),
            new Setting('Combo Spawn Animation', SELECTOR, JudgementsCombo.getSpawnList([LIGHT]), 'jump-in'),
            new Setting('Combo Despawn Animation', SELECTOR, JudgementsCombo.getDespawnList(), 'fade'),
            new Setting('Combo Rolls', CHECKMARK, null, true)
        ]);
    }

    /**
     * The game's color filters for people with color blindness!
     * kinda stole from flixel demos lol
     */
    public static var colorFilters:Map<String, ColorMatrixFilter> = [
        "Deutran" => new ColorMatrixFilter([
            0.43, 0.72, -.15, 0, 0,
            0.34, 0.57, 0.09, 0, 0,
            -.02, 0.03,    1, 0, 0,
               0,    0,    0, 1, 0,
        ]),
        "Protan" => new ColorMatrixFilter([
            0.20, 0.99, -.19, 0, 0,
            0.16, 0.79, 0.04, 0, 0,
            0.01, -.01,    1, 0, 0,
               0,    0,    0, 1, 0,
        ]),
        "Tritan" => new ColorMatrixFilter([
            0.97, 0.11, -.08, 0, 0,
            0.02, 0.82, 0.16, 0, 0,
            0.06, 0.88, 0.18, 0, 0,
               0,    0,    0, 1, 0,
        ])
    ];

    static function updateGlobalSettings():Void
    {
        FlxG.sound.volume = callSetting("Master Volume") / 100;

        if (FlxG.sound.music != null)
            FlxG.sound.music.volume = callSetting('Music Volume') / 100;

        //TODO: vsync setting...
        if (Main.fps != null)
            Main.fps.visible = callSetting("Show FPS");

        FlxG.updateFramerate = FlxG.drawFramerate = callSetting('FPS Cap');

        final f = colorFilters.get(callSetting('Colorblind Filters'));
        FlxG.game.setFilters(f != null ? [f] : []);
    }

    static function updateWindow():Void
    {
        //Resolutions depending on the current, this is the best way I could think of.
        // yea biggie map
        final resolutions:Map<String, Array<Int>> = [
            "800x600"   => [800,  600],  "1024x768"  => [1024, 768],
            "1280x720"  => [1280, 720],  "1280x800"  => [1280, 800],
            "1366x768"  => [1366, 768],  "1440x900"  => [1440, 900],
            "1600x900"  => [1600, 900],  "1680x1050" => [1680, 1050],
            "1920x1080" => [1920, 1080], "2560x1440" => [2560, 1440],
            "3840x2160" => [3840, 2160]
        ];

        var curRes = callSetting("Window Resolution");
        var resArr = resolutions.get(curRes);

        final screenW = Capabilities.screenResolutionX;
        final screenH = Capabilities.screenResolutionY;
        if (resArr[0] > screenW || resArr[1] > screenH)
        {
            setSetting("Window Resolution", "800x600");
            curRes = "800x600";
            resArr = resolutions.get(curRes);
        }

        // very neat borderless fullscreen workaround by tracedinpurple (A.K.A Tiago.hx, thanks man!!)
        final window = Application.current.window;
        final bounds = window.display.bounds;
        final screenX = FlxG.stage.window.display.bounds.x;
        final screenY = FlxG.stage.window.display.bounds.y;

        final isBorderless = callSetting('Screen Mode') == 'Borderless Fullscreen';
        if (isBorderless)
        {
            window.borderless = true;
            window.x = Std.int(screenX + bounds.x);
            window.y = Std.int(screenY + bounds.y);
            window.width = Std.int(bounds.width);
            window.height = Std.int(bounds.height + 1);
        }
        else if (callSetting('Screen Mode') == "Windowed")
        {
            FlxG.fullscreen = window.borderless = false;
            window.width = resArr[0];
            window.height = resArr[1];
            window.x = Std.int(screenX + (screenW - resArr[0]) / 2);
            window.y = Std.int(screenY + (screenH - resArr[1]) / 2);
        }
        else
        {
            FlxG.fullscreen = true;
            window.borderless = false;
        }
    }

    static function callSetting(name:String):Dynamic
    {
        final s = findSetting(name);
        if (s == null) trace('[SETTINGS] Setting "$name" was not found!', "ERROR");
        return s != null ? s.value : null;
    }

    /**
     * Sets a setting value, saves, and updates global state.
     */
    static function setSetting(name:String, value:Dynamic):Void
    {
        final s = findSetting(name);
        if (s == null) return;

        s.value = value;
        updateGlobalSettings();
        saveSettings();

        if (s.forceRestart && moon.game.PlayState.instance != null)
            restartPending = true;

        if (name == 'Language')
        {
            final code = MoonLang.getCodes()[MoonLang.getDisplayNames().indexOf(value)];
            if (code != null) MoonLang.load(code);
        }
    }

    private static function findSetting(name:String):Null<Setting>
    {
        for (cat in categories.keys())
            for (s in categories.get(cat))
                if (s.name.trim() == name.trim())
                    return s;

        return null;
    }

    static function saveSettings():Void
    {
        var toSave:Map<String, Dynamic> = new Map();
        for (cat in categories.keys())
            for (s in categories.get(cat))
                if (s.type != INFO)
                    toSave.set(s.name, {type: s.type, value: s.value});

        save.data.settings = toSave;
        save.flush();
    }

    static function loadSettings():Void
    {
        if (save.data.settings == null) return;

        final loaded:Map<String, Dynamic> = cast save.data.settings;
        for (key in loaded.keys())
        {
            final s = findSetting(key);
            if (s != null && s.type != INFO)
                s.value = loaded.get(key).value;
        }
    }

    static function resetAllSettings():Void
    {
        for (cat in categories.keys())
            for (s in categories.get(cat))
                s.reset();

        saveSettings();
        updateGlobalSettings();
    }
}