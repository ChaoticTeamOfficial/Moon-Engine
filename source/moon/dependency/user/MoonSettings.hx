package moon.dependency.user;

import moon.menus.Settings;
import openfl.system.Capabilities;
import lime.app.Application;
import openfl.filters.BitmapFilter;
import openfl.filters.ColorMatrixFilter;

using StringTools;

enum abstract SettingType(String) to String
{
    var CHECKMARK = 'checkmark';        // for boolean options (true or false most likely)
    var SELECTOR = 'selector';          // for multiple choices
    var SLIDER = 'slider';              // for a numeric slider option
    var UNCAP_SLIDER = 'uncap_slider';  // for a numeric slider option, but uncapped
    var INFO = 'info';                  // for a non selectable option
    var SELECTABLE = 'selectable';      // for a option that you can press enter and be redirected to somewhere.
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
     * For a SELECTOR, options is an Array<String> (or Array<Int> if numeric choices).
     * For SLIDER, options is a two-element Array representing [min, max].
     * For CHECKMARK, this can be ignored. (set to null!)
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
     * Creates a new setting.
     * @param name          The setting's name, which'll be displayed in the options menu, and also needed for when calling it.
     * @param type          The setting's type. Allowed types are: CHECKMARK, SELECTOR, SLIDER.
     * @param description   The description of this setting, shown in the settings menu.
     * @param options       The setting's options, slider = [minVal, maxVal], selector = [values], checkmark = null.
     * @param defaultValue  The setting's default value.
     */
    public function new(name:String, type:SettingType, options:Dynamic, defaultValue:Dynamic)
    {
        this.name = name;
        this.type = type;
        this.description = 'No description found.';
        this.options = options;
        this.defaultValue = defaultValue;
        this.value = defaultValue;

        if(type == INFO) reset(); //so its always updated.
    }

    public function reset():Void
        this.value = defaultValue;
}

@:publicFields
class MoonSettings
{
    /**
     * Settings organized by category.
     * Each key is a category (e.g., "Sound Settings"), and its value is an array of Setting objects.
     */
    static var categories:Map<String, Array<Setting>> = new Map();

    /**
     * This FlxSave instance used to persist data.
     */
    static var save:FlxSave = new FlxSave();

    /**
     * Initialize the settings by binding the save data and populating categories.
     * Call this at game start.
     */
    static function init():Void
    {
        save.bind(Constants.SETTINGS_SAVE_BIND);
        buildSettings();
        loadSettings();
        MoonInput.loadControls();
    }

    /**
     * Every category in order, just for the Settings Menu. :P
     */
    static final categoryOrder:Array<String> = [
        "Video Settings", "Sound Settings", "Gameplay Settings",
        "Interface Settings", "Graphic Settings", "Engine Settings"
    ];

    /**
     * Build all the engine settings.
     */
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
            //new Setting("Editor Sounds", SLIDER, "Changes the volume for editor sound effects.", [0, 100], 100),
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
            new Setting("Ghost Tapping", CHECKMARK, null, true),
            new Setting("Mechanics", CHECKMARK, null, true),
            new Setting("Modchart", CHECKMARK, null, true)
        ]);

        categories.set("Graphic Settings",
        [
            // removing for now.
            //new Setting("V-Sync", CHECKMARK, "Uncaps the FPS and removes horizontal cuts on the screen (may increase input delay).", null, false),
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
            new Setting("Experimental Features", CHECKMARK, null, false),
            new Setting("Modding Tools", CHECKMARK, null, false),
            new Setting("Moon Engine Version", INFO, null, 'v.${Application.current.meta.get('version')}')
        ]);

        // A category that's not visible on the settings, it's mostly just for internal use
        categories.set("Internal", [
            new Setting("Game Character", SELECTOR, ['bf'], 'bf'),
            new Setting("JudgePos", SELECTOR, [], [500, 270]),
            new Setting("ComboPos", SELECTOR, [], [500, 340])
        ]);
    }

    /**
     * The game's color filters for people with color blindness!
     * kinda stole from flixel demos lol
     */
    public static var colorFilters:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}> = [
        "Deutran" => {
            var matrix:Array<Float> = [
                0.43, 0.72, -.15, 0, 0,
                0.34, 0.57, 0.09, 0, 0,
                -.02, 0.03,    1, 0, 0,
                   0,    0,    0, 1, 0,
            ];
            {filter: new ColorMatrixFilter(matrix)}
        },
        "Protan" => {
            var matrix:Array<Float> = [
                0.20, 0.99, -.19, 0, 0,
                0.16, 0.79, 0.04, 0, 0,
                0.01, -.01,    1, 0, 0,
                   0,    0,    0, 1, 0,
            ];
            {filter: new ColorMatrixFilter(matrix)}
        },
        "Tritan" => {
            var matrix:Array<Float> = [
                0.97, 0.11, -.08, 0, 0,
                0.02, 0.82, 0.16, 0, 0,
                0.06, 0.88, 0.18, 0, 0,
                   0,    0,    0, 1, 0,
            ];
            {filter: new ColorMatrixFilter(matrix)}
        }
    ];

    /**
     * Update global options.
     */
    static function updateGlobalSettings():Void
    {
        FlxG.sound.volume = callSetting("Master Volume") / 100;

        if(FlxG.sound.music != null) FlxG.sound.music.volume = callSetting('Music Volume') / 100;

        //TODO: vsync setting
        if (Main.fps != null) Main.fps.visible = callSetting("Show FPS");
        //FlxG.updateFramerate = FlxG.drawFramerate = (!callSetting('V-Sync')) ? callSetting('FPS Cap') : 999;
        FlxG.updateFramerate = FlxG.drawFramerate = callSetting('FPS Cap');
        //trace("Monitor resolution: " + Capabilities.screenResolutionX + " x " + Capabilities.screenResolutionY);

        //apply color-blind filters.
        FlxG.game.setFilters([]);

        final f = colorFilters.get(callSetting('Colorblind Filters'));
        if (f != null)
            FlxG.game.setFilters([f.filter]);
    }

    // actually shortens (isBorderlessFullscreen) LOL
    static var isBF:Bool = false;
    static function updateWindow()
    {
        FlxG.fullscreen = (callSetting('Screen Mode') == 'Fullscreen');
        //Resolutions depending on the current, this is the best way I could think of.
        // yea biggie map
        final resolutions:Map<String, Array<Int>> = [
            "800x600"     => [800, 600],
            "1024x768"    => [1024, 768],
            "1280x720"    => [1280, 720],
            "1280x800"    => [1280, 800],
            "1366x768"    => [1366, 768],
            "1440x900"    => [1440, 900],
            "1600x900"    => [1600, 900],
            "1680x1050"   => [1680, 1050],
            "1920x1080"   => [1920, 1080],
            "2560x1440"   => [2560, 1440],
            "3840x2160"   => [3840, 2160]
        ];

        var curRes = callSetting("Window Resolution");
        var resArr = resolutions.get(curRes);
        final screenX = FlxG.stage.window.display.bounds.x;
        final screenY = FlxG.stage.window.display.bounds.y;
        final screenW = Capabilities.screenResolutionX;
        final screenH = Capabilities.screenResolutionY;
        if (resArr[0] > screenW || resArr[1] > screenH)
        {
            //trace('Selected resolution ${resArr[0]}x${resArr[1]} exceeds monitor resolution ${screenW}x${screenH}. Resetting to 800x600.', "DEBUG");
            setSetting("Window Resolution", "800x600");
            curRes = "800x600";
            resArr = resolutions.get(curRes);
        }

        // very neat borderless fullscreen workaround by tracedinpurple (A.K.A Tiago.hx, thanks man!!)
        final window = Application.current.window;
        final bounds = window.display.bounds;

        isBF = callSetting('Screen Mode') == 'Borderless Fullscreen';
        if(!isBF)
        {
            FlxG.fullscreen = (callSetting('Screen Mode') == 'Fullscreen');
            window.borderless = false;
        }
        else
        {
            window.borderless = true;
            window.x = Std.int(screenX + bounds.x);
            window.y = Std.int(screenY + bounds.y);
            window.width = Std.int(bounds.width);
            window.height = Std.int(bounds.height + 1);
        }

        final curWidth = resArr[0];
        final curHeight = resArr[1];
        if(callSetting('Screen Mode') == "Windowed")
        {
            window.width = curWidth;
            window.height = curHeight;
            window.x = Std.int(screenX + (Capabilities.screenResolutionX - curWidth) / 2);
            window.y = Std.int(screenY + (Capabilities.screenResolutionY - curHeight) / 2);
        }
    }

    /**
     * Returns the value of a setting with the given name.
     */
    static function callSetting(name:String):Dynamic
    {
        var s:Setting = findSetting(name);
        
        if(s == null) trace('[SETTINGS] Setting $name was not found when calling for it!', "ERROR");
        return s != null ? s.value : null;
    }

    /**
     * Sets the value of a setting with the given name.
     * Updates the setting and immediately saves.
     */
    static function setSetting(name:String, value:Dynamic):Void
    {
        var s:Setting = findSetting(name);
        if(s != null)
        {
            s.value = value;
            updateGlobalSettings();
            saveSettings();

            if (name == 'Language')
            {
                final code = MoonLang.getCodes()[MoonLang.getDisplayNames().indexOf(value)];
                if (code != null) MoonLang.load(code);
            }
        }
    }

    /**
     * Iterates over all settings, then returns a setting.
     */
    private static function findSetting(name:String):Null<Setting>
    {
        // haha cat :3
        for (cat in categories.keys())
            for (s in categories.get(cat))
                if(s.name.trim() == name.trim())
                    return s;
        
        return null;
    }

    /**
     * Saves settings using the FlxSave system.
     */
    static function saveSettings():Void
    {
        var settingsToSave:Map<String, Dynamic> = new Map();

        // Flatten setting by its name
        for (cat in categories.keys())
            for (s in categories.get(cat))
                settingsToSave.set(s.name, { type: s.type, value: s.value });

        save.data.settings = settingsToSave;
        save.flush();
    }

    /**
     * Loads settings from the FlxSave system.
     */
     static function loadSettings():Void
    {
        if (save.data.settings != null)
        {
            var loadedSettings:Map<String, Dynamic> = cast save.data.settings;
            for (key in loadedSettings.keys())
            {
                var loaded = loadedSettings.get(key);
                var s:Setting = findSetting(key);
                if (s != null)
                    s.value = loaded.value;
            }
        }
    }

    /**
     * Resets all settings to their default values.
     */
    public static function resetAllSettings():Void
    {
        for (cat in categories.keys())
            for (s in categories.get(cat))
                s.reset();

        saveSettings();
        updateGlobalSettings();
    }
}
