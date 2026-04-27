package moon.game.events.visuals;

class SetCameraMode extends BaseEvent
{
    override public function execute():Void
    {
        //TODO
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Set Camera Mode',
            description: 'Switches how dynamic the camera can be.',
            category: VISUALS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        //TODO
        return [
            {
                name: 'dynamicSinging', label: 'Dynamic Singing', type: DROPDOWN,
                defaultValue: 'none',
                options: ['opponent', 'player', 'both', 'none']
            }
        ];
    }
}
