package moon.game.events.sounds;

import moon.game.obj.Countdown;

class CountdownEvent extends BaseEvent
{
    override public function execute():Void
        Countdown.perform(); //ez

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Countdown',
            description: 'Performs the in-game countdown.',
            category: SOUNDS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            {
                name: 'playSnd', label: 'Play Countdown Sounds', type: CHECKBOX,
                defaultValue: true
            }
        ];
    }
}
