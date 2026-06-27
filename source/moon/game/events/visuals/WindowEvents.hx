package moon.game.events.visuals;

import moon.utils.WindowUtils.MonitorAxes;
import moon.utils.WindowUtils.WindowAxes;

class WindowMoveEvent extends BaseEvent
{
	override public function execute():Void
	{
		final duration = game.conductor.stepCrochet / 1000 * event.values.duration;
		final isInstant = (duration <= 0 || (event?.values?.ease?.toUpperCase() ?? 'INSTANT').contains('INSTANT'));

		WindowUtils.moveTo(
			event?.values?.x ?? 0,
			event?.values?.y ?? 0,
			event?.values?.monitorAxes ?? MonitorAxes.CENTER,
			event?.values?.windowAxes ?? WindowAxes.CENTER,
			isInstant ? null : duration,
			isInstant ? null : {
				ease: TweenUtils.resolveEase(event.values.ease)
			}
		);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Window Movement',
			description: 'Moves the game window to a position on screen.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'x',
				label: 'X',
				type: NUMBER,
				defaultValue: 0,
				min: -9999,
				max: 9999,
				step: 1
			},
			{
				name: 'y',
				label: 'Y',
				type: NUMBER,
				defaultValue: 0,
				min: -9999,
				max: 9999,
				step: 1
			},
			{
				name: 'monitorAxes',
				label: 'Monitor Origin',
				type: DROPDOWN,
				defaultValue: 'Center',
				options: ['Center', 'Corner']
			},
			{
				name: 'windowAxes',
				label: 'Window Anchor',
				type: DROPDOWN,
				defaultValue: 'Center',
				options: [
					'Top Left',
					'Top Center',
					'Top Right',
					'Middle Left',
					'Center',
					'Middle Right',
					'Bottom Left',
					'Bottom Center',
					'Bottom Right'
				]
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 0,
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
			}
		];
	}
}

class WindowResizeEvent extends BaseEvent
{
	override public function execute():Void
	{
		final duration = game.conductor.stepCrochet / 1000 * event.values.duration;
		final isInstant = (duration <= 0 || (event?.values?.ease?.toUpperCase() ?? 'INSTANT').contains('INSTANT'));

		WindowUtils.resizeTo(event?.values?.width ?? 1280, event?.values?.height ?? 720, isInstant ? null : duration, isInstant ? null : {
			ease: TweenUtils.resolveEase(event.values.ease)
		}, event?.values?.anchor ?? WindowAxes.CENTER);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Window Resize',
			description: 'Resizes the game\'s window.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'width',
				label: 'Width',
				type: NUMBER,
				defaultValue: 1280,
				min: 1,
				max: 9999,
				step: 1
			},
			{
				name: 'height',
				label: 'Height',
				type: NUMBER,
				defaultValue: 720,
				min: 1,
				max: 9999,
				step: 1
			},
			{
				name: 'anchor',
				label: 'Anchor Point',
				type: DROPDOWN,
				defaultValue: 'Center',
				options: [
					'Top Left',
					'Top Center',
					'Top Right',
					'Middle Left',
					'Center',
					'Middle Right',
					'Bottom Left',
					'Bottom Center',
					'Bottom Right'
				]
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 0,
				min: 0,
				max: 999,
				step: 1
			},
			{
				name: 'ease',
				label: 'Easing',
				type: DROPDOWN,
				defaultValue: 'linear',
				options: TweenUtils.easeList
			}
		];
	}
}

class WindowOpacityEvent extends BaseEvent
{
	override public function execute():Void
	{
		final duration = game.conductor.stepCrochet / 1000 * event.values.duration;
		final isInstant = (duration <= 0 || (event?.values?.ease?.toUpperCase() ?? 'INSTANT').contains('INSTANT'));

		WindowUtils.fadeWindow(event?.values?.opacity ?? 1.0, isInstant ? null : duration, isInstant ? null : {
			ease: TweenUtils.resolveEase(event.values.ease)
		});
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Window Opacity',
			description: 'Fades the game window to a target opacity.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'opacity',
				label: 'Opacity',
				type: NUMBER,
				defaultValue: 1.0,
				min: 0.0,
				max: 1.0,
				step: 0.05
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 0,
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
			}
		];
	}
}

class WindowPropertiesEvent extends BaseEvent
{
	override public function execute():Void
	{
		final val = event.values;

		if (val?.title != null && cast(val.title, String).length > 0) WindowUtils.setTitle(val.title);

		if (val?.borderless != null) WindowUtils.setBorderless(val.borderless);

		if (val?.resizable != null) WindowUtils.setResizable(val.resizable);

		switch ((val?.windowState ?? 'none') : String)
		{
			case 'fullscreen':
				WindowUtils.setFullscreen(true);
			case 'minimize':
				WindowUtils.minimize();
			case 'maximize':
				WindowUtils.maximize();
			case 'restore':
				WindowUtils.restoreWindow();
			case 'focus':
				WindowUtils.focusWindow();
			case 'center':
				WindowUtils.centerWindow();
			default: // nothing!!!!!
		}
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Window Properties',
			description: 'Tweaks window properties like title, borders, resizability, and state.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'title',
				label: 'Title',
				type: TEXT,
				defaultValue: ''
			},
			{
				name: 'borderless',
				label: 'Borderless',
				type: CHECKBOX,
				defaultValue: false
			},
			{
				name: 'resizable',
				label: 'Resizable',
				type: CHECKBOX,
				defaultValue: true
			},
			{
				name: 'windowState',
				label: 'Window State',
				type: DROPDOWN,
				defaultValue: 'none',
				options: [
					'none',
					'fullscreen',
					'minimize',
					'maximize',
					'restore',
					'focus',
					'center'
				]
			}
		];
	}
}
