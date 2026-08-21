package moon.game.events;

import moon.dependency.scripting.MoonEvent;
import moon.game.PlayState;

/**
 * Base class for all hardcoded events.
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
	{
	}

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

	/**
	 * Returns the interactive field definitions shown in the Level Editor's Library panel.
	 */
	public function getEditorFields():Array<EventFieldDef> return [];

	/**
	 * Optional provider for fields that depend on a controlling dropdown
	 * (marked with `controlsDynamicFields`).
	 */
	public function getDynamicFieldsProvider():Null<String->Array<EventFieldDef>> return null;

	/**
	 * Converts the flat values object produced by `EventFormUI.getValues()` into the
	 * format expected by `execute()` (i.e. `event.values`).
	 */
	public function processValues(raw:Dynamic):Dynamic return raw;
}
