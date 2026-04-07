package moon.game.events;

import moon.dependency.scripting.MoonEvent;
import moon.game.PlayState;

/**
 * Registry for managing hardcoded event types.
 * This class maps event tags to their corresponding event classes.
 */
class EventRegistry
{
    private static var eventMap:Map<String, Class<BaseEvent>>;

    /**
     * Initialize the event registry with all hardcoded event types.
     */
    public static function init():Void
    {
        eventMap = [
            // VISUALS
            'Move Camera' => MoveCameraEvent,
            'Set Zoom' => SetZoomEvent,
            'Customized Pulse Timing' => CustomizedPulseTimingEvent,
            
            // CHARACTERS
            'Play Character Animation' => PlayCharacterAnimEvent,
            
            // SOUNDS
            'Change Playback Settings' => ChangePlaybackSettingsEvent,

            // GIMMICKS
            'Set Lane Scroll Speed' => SetScrollSpeedEvent
        ];
    }

    /**
     * Check if an event tag is hardcoded.
     */
    public static function isHardcoded(tag:String):Bool
        return eventMap.exists(tag);

    /**
     * Get all hardcoded event tags.
     */
    public static function getHardcodedTags():Array<String>
        return [for (key in eventMap.keys()) key];

    /**
     * Create and execute a hardcoded event.
     */
    public static function executeEvent(game:PlayState, event:MoonEvent):Void
    {
        if (eventMap == null) init();
        
        var eventClass = eventMap.get(event.tag);
        if (eventClass != null)
        {
            var eventInstance = Type.createInstance(eventClass, [game, event]);
            eventInstance.execute();
        }
        else trace('[EVENT-REGISTRY] Unknown event: ${event.tag}', "WARNING");
    }

    /**
     * Get editor data for a hardcoded event.
     */
    public static function getEditorData(tag:String):Null<{name:String, description:String, category:GridType}>
    {
        if (eventMap == null) init();
        
        final eventClass = eventMap.get(tag);
        if (eventClass != null)
            return Type.createInstance(eventClass, [null, new MoonEvent(tag, {})]).getEditorData();
        
        return null;
    }

    /**
     * Returns the field definitions for a hardcoded event.
     */
    public static function getEditorFields(tag:String):Array<EventFieldDef>
    {
        if (eventMap == null) init();

        final cls = eventMap.get(tag);
        if (cls != null)
            return Type.createInstance(cls, [null, new MoonEvent(tag, {})]).getEditorFields();

        return [];
    }

    /**
     * Runs `processValues()` on the event class for `tag`, remapping the flat form
     * output into the structure expected by `execute()`.
     */
    public static function processEventValues(tag:String, raw:Dynamic):Dynamic
    {
        if (eventMap == null) init();

        final cls = eventMap.get(tag);
        if (cls != null)
            return Type.createInstance(cls, [null, new MoonEvent(tag, {})]).processValues(raw);

        return raw;
    }
}
