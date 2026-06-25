package moon.game.events.visuals;

class SetZoomEvent extends BaseEvent
{
	override public function execute():Void
	{
		final baseZoom = game.stage?.cameraSettings?.zoom ?? 1;
		var targetZoom:Float = baseZoom;
		targetZoom = (event.values.mode == 'stage') ? baseZoom + (event.values.zoom - 1) : event.values.zoom;

		game.setCameraZoom(targetZoom, game.conductor.stepCrochet / 1000 * event.values.duration, {
			ease: TweenUtils.resolveEase(event.values.ease)
		}, ((event?.values?.ease?.toUpperCase() ?? "INSTANT").contains('INSTANT') || event.values.duration <= 0));
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Set Zoom',
			description: "Set a zoom in the game's camera.",
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'zoom',
				label: 'Zoom',
				type: NUMBER,
				defaultValue: 1.0,
				min: 0.01,
				max: 100.0,
				step: 0.05
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 8,
				min: 0,
				max: 999,
				step: 1
			},
			{
				name: 'ease',
				label: 'Easing',
				type: DROPDOWN,
				defaultValue: 'circOut',
				options: TweenUtils.easeList
			},
			{
				name: 'mode',
				label: 'Mode',
				type: DROPDOWN,
				defaultValue: 'stage',
				options: ['absolute', 'stage']
			}
		];
	}
}
