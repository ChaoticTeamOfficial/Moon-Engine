package moon.dependency.scripting;

import moon.toolkit.level_editor.LevelEditor.GridType;
import moon.toolkit.level_editor.LevelEditor.EventInfo;
import moon.game.events.EventRegistry;

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
     * Whenever the event is valid as a script.
     * If false, it won't be readed as a script file.
     */
    public var valid:Bool = true;
    
    public function new(tag:String, values:Dynamic)
    {
        super();

        this.tag = tag;
        this.values = values;

        // checks if it's a hardcoded event or a script-based event
        if (!EventRegistry.isHardcoded(tag) && Paths.exists('data/events/$tag.hx'))
            load('data/events/$tag.hx');
        else if (!EventRegistry.isHardcoded(tag)) valid = false;
        else valid = false;
    }

    /**
     * Calls the "onExecute" function on events.
     */
    public function exec()
        if(valid) call('onExecute', [values]);

    public function retrieveEditorData():EventInfo
    {
        if(valid)
        {
            return (exists('editorData')) ? code.get('editorData') : {
                name: 'Unknown',
                description: 'Unknown event data.',
                category: VISUALS
            };
        }
        else if (EventRegistry.isHardcoded(tag))
        {
            return EventRegistry.getEditorData(tag) ?? {
                name: '($tag) Not Found',
                description: "If you're reading this, report this error to toffee.caramel on discord.",
                category: VISUALS
            };
        }
        
        return null;
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
