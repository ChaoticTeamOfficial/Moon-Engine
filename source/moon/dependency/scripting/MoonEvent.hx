package moon.dependency.scripting;

import moon.toolkit.level_editor.LevelEditor.GridType;

/**
 * A class for handling in-game events.
 */
class MoonEvent extends MoonScript
{
    /**
     * The event's time in milliseconds.
     */
    public var time:Float;

    /**
     * The event's tag.
     */
    public var tag:String;

    /**
     * The event's values.
     */
    public var values:Dynamic;
    
    /**
     * Variables map for the script.
     */
    public var PRESET_VARIABLES(default, set):Map<String, Dynamic>;

    /**
     * A list of hardcoded events (by tag) that won't be handled from a script, but by code instead.
     */
    public var HARDCODED_EVENTS:Array<String> = [
        'Move Camera', 'Set Zoom', 'Change Playback Settings',

        'Play Character Animation'
    ];

    /**
     * Whenever the event is valid as a script.
     * If false, it won't be readed as a script file.
     */
    public var valid:Bool = true;
    public function new(tag:String, values:Dynamic)
    {
        super();

        this.tag = tag;
        this.values = values;

        (!HARDCODED_EVENTS.contains(tag) && Paths.exists('data/events/$tag.hx')) ? load('data/events/$tag.hx') : valid = false;
    }

    public function exec()
        if(valid) call('onExecute', [values]);

    public function preloadEditor():{name:String, description:String, category:GridType}
    {
        if(valid) return (exists('editorData')) ? code.get('editorData') : {name: 'Unknown', description: 'Unknown event data.', category: VISUALS};
        else return switch(tag){
            // VISUALS
            case 'Move Camera': {name: 'Move Camera', description: "Move the camera to wherever you want.", category: VISUALS};
            case 'Set Zoom': {name: 'Set Zoom', description: "Set a zoom in the game's camera.", category: VISUALS};
            case 'Customized Pulse Timing': {name: 'Customized Pulse Timing', description: "Switches settings for the default camera pulse.", category: VISUALS};

            // CHARACTERS
            case 'Play Character Animation': {name: 'Play Character Animation', description: "Plays a selected Character animation.", category: CHARACTERS};

            // SOUNDS
            case 'Change Playback Settings': {name: 'Change Playback Settings', description: "Allows you to change the BPM and Time Signature.", category: SOUNDS};
            default: {name: '($tag) Not Found', description: "If you're reading this, report this error to toffee.caramel on discord.", category: VISUALS};
        }
    }

    @:noCompletion public function set_PRESET_VARIABLES(vars)
    {
        PRESET_VARIABLES = vars;

        if(valid)
            for(variableName => variableValue in PRESET_VARIABLES)
                code.set(variableName, variableValue);

        return vars;
    }
}