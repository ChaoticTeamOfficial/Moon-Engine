package moon.dependency.user;

import moon.menus.Settings;
import openfl.system.Capabilities;
import flixel.FlxG;
import flixel.util.FlxSave;
import lime.app.Application;

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
    public function new(name:String, type:SettingType, description:String, options:Dynamic, defaultValue:Dynamic)
    {
        this.name = name;
        this.type = type;
        this.description = description;
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
        "Graphic Settings", "Interface Settings", "Engine Settings"
    ];

    /**
     * Build all the engine settings.
     */
    private static function buildSettings():Void
    {
        categories.set("Video Settings",
        [
            new Setting("Screen Mode", SELECTOR, "Set your screen mode. (Borderless is not working atm! Sorry!)", ["Windowed", "Fullscreen", "Borderless Fullscreen"], "Windowed"),

            new Setting("Window Resolution", SELECTOR, "Change your window resolution. (ONLY APPLIED IF ON WINDOWED!)", 
            ["800x600", "1024x768", "1280x720", "1280x800", "1366x768", "1440x900", 
            "1600x900", "1680x1050", "1920x1080", "2560x1440", "3840x2160"], "1280x720")
        ]);

        categories.set("Sound Settings",
        [
            new Setting("Master Volume", SLIDER, "Changes the game's main volume (affects everything).", [0, 100], 100),
            new Setting("Instrumental Volume", SLIDER, "Changes the volume for in-game instrumentals.", [0, 100], 100),
            new Setting("Voices Volume", SLIDER, "Changes the volume for in-game vocals.", [0, 100], 100),
            new Setting("Music Volume", SLIDER, "Changes the volume for menu music.", [0, 100], 100),
            new Setting("SFX Volume", SLIDER, "Changes the volume for general sound effects.", [0, 100], 100),
            new Setting("Editor Sounds", SLIDER, "Changes the volume for editor sound effects.", [0, 100], 100),
            new Setting("Mute Voices on Miss", CHECKMARK, "Toggles muting the vocals when you miss. Useful if you'd like to hear uninterrupted music.", null, true)
        ]);

        categories.set("Gameplay Settings",
        [
            new Setting("Keybinds...", SELECTABLE, "Change your gameplay/menus keybinds.", null, null),
            new Setting("Note Offset", UNCAP_SLIDER, "Changes the delay of the notes. Negative: Late, Positive: Early (MUST RESTART SONG TO APPLY!)", null, 0),
            new Setting("Downscroll", CHECKMARK, "Places the judgement line at the bottom of the screen. Notes will descend into it.", null, false),
            new Setting("Middlescroll", CHECKMARK, "Positions the judgement line at the middle of the screen, hiding opponent notes.", null, false),
            new Setting("Note Splashes", CHECKMARK, "Toggles the visibility of the note splashes.", null, true),
            new Setting("Hold Note Splashes", CHECKMARK,"Toggles the visibility of the hold note splashes.", null, true),
            new Setting("Lane Background Visibility", SELECTOR, "Adds a lane behind your strumlines.", [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1], 0),
            new Setting("Ghost Tapping", CHECKMARK, "Allows tapping freely when there are no notes (hey, I don't judge).", null, true),
            new Setting("Mechanics", CHECKMARK, "Toggles song-specific mechanics (such as dodging).", null, true),
            new Setting("Modchart", CHECKMARK, "Toggles modcharts (animated/moving notes).", null, true)
        ]);

        categories.set("Graphic Settings",
        [
            // removing for now.
            //new Setting("V-Sync", CHECKMARK, "Uncaps the FPS and removes horizontal cuts on the screen (may increase input delay).", null, false),
            new Setting("FPS Cap", SELECTOR, "The maximum amount your framerate can reach.", [30, 60, 120, 144, 240, 360], 60),
            new Setting("Shaders", CHECKMARK, "Toggles shaders (may affect performance on low-end devices).", null, true),
            new Setting("Flashing Lights", CHECKMARK, "Toggles flashing effects. Recommended to turn OFF in case of high photosensitivity.", null, true),
            new Setting("Colorblind Filters", SELECTOR, "Applies filters for colorblindness.", ["Off", "T", "P", "R"], "Off")
        ]);

        categories.set("Interface Settings",
        [
            new Setting("Noteskin", SELECTOR, "Toggles your noteskins.", ["DEFAULT", "MOON"], "DEFAULT"),
            new Setting("Healthbar Visibility", SELECTOR, "Toggles whether the health bar should be visible or not.", ["On", "Below 100%", "Off"], "On"),
            new Setting("Show Accuracy", SELECTOR, "Toggles accuracy stat on the in-game HUD.", ["Off", "Approximate", "Full"], "Full"),
            new Setting("Stats Position", SELECTOR, "Changes the position of your stats HUD (misses, score, etc).", ["On HP-Bar", "On Player Lane"], "On HP-Bar"),
            new Setting("Icons", SELECTOR, "Changes where the character icons will appear.", ["Off", "At Healthbar", "On Lanes"], "At Healthbar"),
            new Setting("Show FPS", CHECKMARK, "Toggles FPS/Memory display.", null, false)
        ]);

        categories.set("Engine Settings",
        [
            new Setting("Auto-Updates", SELECTOR, "When an update is released, select whether to automatically download it, redirect you to a browser or do nothing.", ["Off", "In-Game", "Redirect"], "In-Game"),
            new Setting("Experimental Features", CHECKMARK, "Toggles features that are in a experimental phase. (SOME OF THEM MAY CRASH YOUR GAME!)", null, false),
            new Setting("Modding Tools", CHECKMARK, "Enable tools for modding (such as the chart and character editors).", null, false),
            new Setting("Moon Engine Version", INFO, "Moon Engine's current version. Thanks for using!", null, 'v.${Application.current.meta.get('version')}')
        ]);

        // A category that's not visible on the settings, it's mostly just for internal use
        categories.set("Internal", [
            new Setting("Game Character", SELECTOR, "Currently selected game character", ['bf'], 'bf')
        ]);
    }

    /**
     * Update global options.
     */
    static function updateGlobalSettings():Void
    {
        FlxG.sound.volume = callSetting("Master Volume") / 100;

        if(FlxG.sound.music != null)
        FlxG.sound.music.volume = callSetting('Music Volume') / 100;

        if (Main.fps != null) Main.fps.visible = callSetting("Show FPS");
        //FlxG.updateFramerate = FlxG.drawFramerate = (!callSetting('V-Sync')) ? callSetting('FPS Cap') : 999;
        FlxG.updateFramerate = FlxG.drawFramerate = callSetting('FPS Cap');
        //trace("Monitor resolution: " + Capabilities.screenResolutionX + " x " + Capabilities.screenResolutionY);
    }

    // actually shortens (isBorderlessFullscreen) LOL
    static var isBF:Bool = false;
    static function updateWindow()
    {
        FlxG.fullscreen = (callSetting('Screen Mode') == 'Fullscreen');

        //Resolutions depending on the current, this is the best way I could think of.
        // yea biggie map

        // uhh also, todo
        // not allow the user to go to a bigger resolution than the monitor's.
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

        // very neat borderless fullscreen workaround by tracedinpurple (A.K.A Tiago.hx, thanks man!!)
        final window = Application.current.window;
        final bounds = window.display.bounds;

        isBF = callSetting('Screen Mode') == 'Borderless Fullscreen';
        if(!isBF)
            window.borderless = false;
        else
        {
            window.borderless = true;
            window.x = Std.int(bounds.x);
            window.y = Std.int(bounds.y);
            window.width = Std.int(bounds.width);
            window.height = Std.int(bounds.height + 1);
        }

        final curWidth = resolutions.get(callSetting("Window Resolution"))[0];
        final curHeight = resolutions.get(callSetting("Window Resolution"))[1];
        if(callSetting('Screen Mode') == "Windowed")
        {
            window.width = curWidth;
            window.height = curHeight;
            window.x = Std.int((Capabilities.screenResolutionX - curWidth) / 2);
            window.y = Std.int((Capabilities.screenResolutionY - curHeight) / 2);
        }

    }

    /**
     * Returns the value of a setting with the given name.
     */
    static function callSetting(name:String):Dynamic
    {
        var s:Setting = findSetting(name);
        
        if(s == null) trace('Setting $name was not found when calling for it!', "ERROR");
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
