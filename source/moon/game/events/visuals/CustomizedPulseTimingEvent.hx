package moon.game.events.visuals;

class CustomizedPulseTimingEvent extends BaseEvent
{
    override public function execute():Void
    {
        game.bopRate = event?.values?.rate ?? Constants.DEFAULT_BOP_RATE;
        game.bopIntensity = (Constants.DEFAULT_BOP_INTENSITY - 1) * (event?.values?.intensity ?? 1) * 2;
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Customized Pulse Timing',
            description: 'Switches settings for the default camera pulse.',
            category: VISUALS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            {
                name: 'rate', label: 'Bop Rate (beats)', type: NUMBER,
                defaultValue: Constants.DEFAULT_BOP_RATE,
                min: 1, max: 32, step: 1
            },
            {
                name: 'intensity', label: 'Intensity', type: NUMBER,
                defaultValue: Constants.DEFAULT_BOP_INTENSITY,
                min: 0.0, max: 10.0, step: 0.1
            }
        ];
    }
}
