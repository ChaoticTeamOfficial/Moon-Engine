package moon.game.events.visuals;

class PulseCameraEvent extends BaseEvent
{
	override public function execute():Void
	{
		if (game.allowGameBop) game.camGAME.zoom += (Constants.DEFAULT_BOP_INTENSITY - 1) * (event?.values?.gameInt ?? 1);
		game.camHUD.zoom += (Constants.DEFAULT_BOP_INTENSITY - 1) * (event?.values?.hudInt ?? 1);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Pulse Camera',
			description: 'Pulses each of the cameras.',
			category: VISUALS,
			canRunOnCreate: false
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'gameInt',
				label: 'Game Intensity',
				type: NUMBER,
				defaultValue: Constants.DEFAULT_BOP_INTENSITY,
				min: 0.0,
				max: 10.0,
				step: 0.05
			},
			{
				name: 'hudInt',
				label: 'HUD Intensity',
				type: NUMBER,
				defaultValue: Constants.DEFAULT_BOP_INTENSITY,
				min: 0.0,
				max: 10.0,
				step: 0.05
			}
		];
	}
}
