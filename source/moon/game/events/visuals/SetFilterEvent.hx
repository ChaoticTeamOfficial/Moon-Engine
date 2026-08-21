package moon.game.events.visuals;

import openfl.display.Shader;
import moon.dependency.MoonShaderHandler;
import moon.game.events.ShaderFilterRegistry;
import moon.game.events.EventFieldDef;
import moon.toolkit.level_editor.LevelEditor.EventInfo;

class SetFilterEvent extends BaseEvent
{
	override public function execute():Void
	{
		final values = event.values;
		final def = ShaderFilterRegistry.getByLabel(values.filter) ?? ShaderFilterRegistry.get(values.filter);
		if (def == null)
		{
			trace('[Camera Shader] Unknown filter: ${values.filter}', "WARNING");
			return;
		}

		final target:String = values.target ?? 'camGAME';
		final handler = game.getCameraShaderHandler(target);
		if (handler == null) return;

		var shader:Shader = handler.getShader(def.id);
		if (shader == null)
		{
			shader = def.create();
			handler.add(def.id, shader, false);
		}

		def.apply(shader, values);
		handler.setEnabled(def.id, values.enabled != false);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Set Filter',
			description: 'Add, remove, or toggle a shader filter on a camera.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		ShaderFilterRegistry.init();
		final labels = ShaderFilterRegistry.getLabels();

		return [
			{
				name: 'target',
				label: 'Target',
				type: DROPDOWN,
				defaultValue: 'camGAME',
				options: ['camGAME', 'camHUD', 'camALT']
			},
			{
				name: 'filter',
				label: 'Filter',
				type: DROPDOWN,
				defaultValue: labels.length > 0 ? labels[0] : '',
				options: labels,
				controlsDynamicFields: true
			},
			{
				name: 'enabled',
				label: 'Enabled',
				type: CHECKBOX,
				defaultValue: true
			}
		];
	}

	override public function getDynamicFieldsProvider():Null<String->Array<EventFieldDef>>
	{
		return (selectedLabel:String) ->
		{
			final def = ShaderFilterRegistry.getByLabel(selectedLabel);
			return def != null ? def.fields : [];
		};
	}
}
