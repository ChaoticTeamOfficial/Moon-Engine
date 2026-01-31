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
            description: "Allows you to change the BPM and Time Signature.",
            category: SOUNDS
        };
    }
}
