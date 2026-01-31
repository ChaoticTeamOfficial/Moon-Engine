package moon.game.events;

import moon.dependency.scripting.MoonEvent;
import moon.game.PlayState;

/**
 * Base class for all hardcoded events.
 * Each event type should extend this class and implement the execute method.
 */
class BaseEvent
{
    public var game:PlayState;
    public var event:MoonEvent;

    public function new(game:PlayState, event:MoonEvent)
    {
        this.game = game;
        this.event = event;
    }

    /**
     * Execute the event logic.
     */
    public function execute():Void
    {}

    /**
     * Get editor metadata for this event.
     */
    public function getEditorData():EventInfo
    {
        return {
            name: 'Unknown Event',
            description: 'No description available.',
            category: VISUALS
        };
    }
}