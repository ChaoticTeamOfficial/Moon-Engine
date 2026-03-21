package moon.game.events.sounds;

class ChangePlaybackSettingsEvent extends BaseEvent
{
    override public function execute():Void
    {
        game.conductor.changeBpmAt(
            event.time,
            event.values.bpm,
            event.values.timeSignature[0],
            event.values.timeSignature[1]
        );
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Change Playback Settings',
            description: 'Allows you to change the BPM and Time Signature.',
            category: SOUNDS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            {
                name: 'bpm', label: 'BPM', type: NUMBER,
                defaultValue: 120.0, min: 1, max: 999, step: 0.5
            },
            {
                name: 'numerator', label: 'Time Sig. Num', type: NUMBER,
                defaultValue: 4, min: 1, max: 16, step: 1
            },
            {
                name: 'denominator', label: 'Time Sig. Den', type: NUMBER,
                defaultValue: 4, min: 1, max: 16, step: 1
            }
        ];
    }

    /**
     * The form produces flat `numerator` / `denominator` fields.
     * This remaps them into the `timeSignature: [n, d]` array that execute() expects.
     */
    override public function processValues(raw:Dynamic):Dynamic
    {
        return {
            bpm: raw.bpm,
            timeSignature: [Std.int(raw.numerator), Std.int(raw.denominator)]
        };
    }
}
