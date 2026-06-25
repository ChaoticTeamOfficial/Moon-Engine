package moon.game.events.visuals;

class ShowSubtitleEvent extends BaseEvent
{
	override public function execute():Void
	{
		game.showCaptions(
			event?.values?.text ?? '',
			(event?.values?.duration ?? 5) * (game.conductor.crochet / 1000) * 0.25,
			Std.int(event?.values?.size ?? 24),
			event?.values?.boxType ?? 'Rounded',
			event?.values?.textfont ?? 'vcr.ttf',
			event?.values?.textCol ?? "#FFFFFF",
			event?.values?.outlineCol ?? "#FFFFFF",
			event?.values?.outline ?? 'None'
		);

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
			{
				name: 'text',
				label: 'Text',
				type: TEXT,
				defaultValue: ''
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 8.0,
				min: 0,
				max: 9999,
				step: 0.5
			},
			{
				name: 'size',
				label: 'Text Size',
				type: NUMBER,
				defaultValue: 24,
				min: 1,
				max: 200,
				step: 1
			},
			{
				name: 'boxType',
				label: 'Box Type',
				type: DROPDOWN,
				defaultValue: 'Rounded',
				options: ['Rounded', 'Rectangle', 'Noteskin', 'None']
			},
			{
				name: 'textfont',
				label: 'Text Font',
				type: DROPDOWN,
				defaultValue: 'vcr.ttf',
				options: ['vcr.ttf'] // TODO: get font list from the fonts directory
			},
			{
				name: 'outline',
				label: 'Outline Type',
				type: DROPDOWN,
				defaultValue: 'None',
				options: ['None', 'Shadow', 'Outline']
			},
			{
				name: 'textCol',
				label: 'Text Color',
				type: COLOR,
				defaultValue: 0xFFFFFFFF
			},
			{
				name: 'outlineCol',
				label: 'Outline Color',
				type: COLOR,
				defaultValue: 0xFFFFFFFF
			}
		];
	}
}
