package moon.game.events.visuals;

class MoveCameraEvent extends BaseEvent
{
	override public function execute():Void
	{
		final isInstant = ((event?.values?.ease?.toUpperCase() ?? "INSTANT").contains('INSTANT') || event.values.duration == 0);
		game.setCameraFocus(
			event.values.character,
			[event?.values?.x ?? 0, event?.values?.y ?? 0],
			game.conductor.stepCrochet / 1000 * event.values.duration,
			{
				ease: TweenUtils.resolveEase(event.values.ease)
			},
			isInstant
		);

		game.rotateCamera(event?.values?.rotation ?? 0, game.conductor.stepCrochet / 1000 * event.values.duration, {
			ease: TweenUtils.resolveEase(event.values.ease)
		}, isInstant);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Move Camera',
			description: 'Move the camera to wherever you want.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'character',
				label: 'Target',
				type: DROPDOWN,
				defaultValue: 'player',
				options: ['player', 'opponent', 'spectator', 'none']
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 26,
				min: 0,
				max: 999,
				step: 1
			},
			{
				name: 'ease',
				label: 'Easing',
				type: DROPDOWN,
				defaultValue: 'expoOut',
				options: TweenUtils.easeList
			},
			{
				name: 'x',
				label: 'X Offset',
				type: NUMBER,
				defaultValue: 0,
				min: -9999,
				max: 9999,
				step: 1
			},
			{
				name: 'y',
				label: 'Y Offset',
				type: NUMBER,
				defaultValue: 0,
				min: -9999,
				max: 9999,
				step: 1
			},
			{
				name: 'rotation',
				label: 'Rotation',
				type: NUMBER,
				defaultValue: 0,
				min: -9999,
				max: 9999,
				step: 1
			}
		];
	}
}
