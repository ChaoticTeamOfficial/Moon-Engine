package moon.game.events.visuals;

class CallMethodEvent extends BaseEvent
{
	override public function execute():Void
	{
		// TODO: make a way to have parameters
		Global.scriptCall(event.values.methodName, []);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Call Custom Method',
			description: 'Calls a function on all active scripts.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [{
			name: 'methodName',
			label: 'Function',
			type: TEXT,
			defaultValue: "myFunctionName"
		}];
	}
}
