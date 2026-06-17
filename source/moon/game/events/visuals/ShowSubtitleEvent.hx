package moon.game.events.visuals;

class ShowSubtitleEvent extends BaseEvent
{
    override public function execute():Void
    {
        // I love script suport :)
        //TODO: SHOW SUBTITLES INGAME
        trace(event.values.text);
        Global.scriptCall('onShowSubtitle', [event.values.text, event.values.duration]);
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Show Subtitle',
            description: 'Displays a subtitle line for a given duration in steps.',
            category: VISUALS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            { name: 'text', label: 'Text', type: TEXT, defaultValue: '' },
            { name: 'duration', label: 'Duration (steps)', type: NUMBER, defaultValue: 8.0, min: 0, max: 9999, step: 0.5 }
        ];
    }
}