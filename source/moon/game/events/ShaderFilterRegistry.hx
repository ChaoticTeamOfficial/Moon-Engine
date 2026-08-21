package moon.game.events;

import moon.hardcoded_shaders.ColorSwap.ColorSwapShader;
import openfl.display.Shader;
import moon.hardcoded_shaders.*;
import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxCamera;
import flixel.FlxG;

/**
 * Descriptor for a camera filter that can be driven by the Set Filter event.
 */
typedef ShaderFilterDef =
{
	/**
	 * Unique id stored in event.values.filter
	 */
	var id:String;

	/**
	 * Label shown in the editor dropdown
	 */
	var label:String;

	/**
	 * Creates a fresh shader instance
	 */
	var create:Void->Shader;

	/**
	 * Editor fields shown when this filter is selected
	 */
	var fields:Array<EventFieldDef>;

	/**
	 * Applies form values onto the shader instance
	 */
	var apply:Shader->Dynamic->Void;

	/**
	 * Optional per-frame update.
	 */
	var ?update:Shader->Float->Null<FlxCamera>->Void;
}

/**
 * Central registry of camera filters available to the Camera Shader event.
 */
class ShaderFilterRegistry
{
	private static var _filters:Map<String, ShaderFilterDef>;
	private static var _order:Array<String>;

	public static function init():Void
	{
		if (_filters != null) return;

		_filters = [];
		_order = [];

		// now we initialize the default slash hardcoded shaders
		register({
			id: 'gaussianBlur',
			label: 'Gaussian Blur',
			create: () -> new GaussianBlurShader(1.0),
			fields: [{
				name: 'intensity',
				label: 'Amount',
				type: NUMBER,
				defaultValue: 1.0,
				min: 0,
				max: 10,
				step: 0.05
			}],
			apply: (shader, values) -> cast(shader, GaussianBlurShader).setAmount(values.intensity ?? 1.0)
		});

		register({
			id: 'mosaic',
			label: 'Mosaic',
			create: () -> new MosaicShader(),
			fields: [{
				name: 'intensity',
				label: 'Block Size',
				type: NUMBER,
				defaultValue: 8,
				min: 1,
				max: 64,
				step: 1
			}],
			apply: (shader, values) -> cast(shader, MosaicShader).bSize = values.intensity ?? 8
		});

		register({
			id: 'grayscale',
			label: 'Grayscale',
			create: () -> new GrayscaleShader(),
			fields: [],
			apply: (shader, values) -> {
			}
		});

		register({
			id: 'invert',
			label: 'Invert Color',
			create: () -> new InvertColor(),
			fields: [],
			apply: (shader, values) -> {
			}
		});

		register({
			id: 'wiggle',
			label: 'Wiggle',
			create: () -> new WiggleEffect(1.0, 1.0, 0.1),
			fields: [
				{
					name: 'effectType',
					label: 'Wiggle Type',
					type: DROPDOWN,
					defaultValue: 'Dreamy',
					options: [
						'Dreamy',
						'Wavy',
						'Horizontal Heat Wave',
						'Vertical Heat Wave',
						'Flag'
					]
				},
				{
					name: 'intensity',
					label: 'Amplitude',
					type: NUMBER,
					defaultValue: 0.1,
					min: 0,
					max: 2,
					step: 0.01
				},
				{
					name: 'speed',
					label: 'Speed',
					type: NUMBER,
					defaultValue: 1.0,
					min: 0,
					max: 10,
					step: 0.05
				},
				{
					name: 'frequency',
					label: 'Frequency',
					type: NUMBER,
					defaultValue: 1.0,
					min: 0,
					max: 20,
					step: 0.1
				}
			],
			apply: (shader, values) ->
			{
				final w:WiggleEffect = cast shader;
				w.waveAmplitude = values.intensity ?? 0.1;
				w.waveSpeed = values.speed ?? 1.0;
				w.waveFrequency = values.frequency ?? 1.0;
				w.effectType = w.byString(values.effectType);
			},
			update: (shader, elapsed, _) -> cast(shader, WiggleEffect).update(elapsed)
		});

		register({
			id: 'rain',
			label: 'Rain',
			create: () -> new RainShader(),
			fields: [
				{
					name: 'intensity',
					label: 'Intensity',
					type: NUMBER,
					defaultValue: 0.5,
					min: 0,
					max: 1,
					step: 0.01
				},
				{
					name: 'scale',
					label: 'Scale',
					type: NUMBER,
					defaultValue: 1.0,
					min: 0.1,
					max: 5,
					step: 0.05
				},
				{
					name: 'puddleY',
					label: 'Puddle Y',
					type: NUMBER,
					defaultValue: 0,
					min: -2000,
					max: 2000,
					step: 10
				},
				{
					name: 'puddleScaleY',
					label: 'Puddle Scale Y',
					type: NUMBER,
					defaultValue: 0,
					min: 0,
					max: 5,
					step: 0.05
				}
			],
			apply: (shader, values) ->
			{
				final r:RainShader = cast shader;
				r.intensity = values.intensity ?? 0.5;
				r.scale = values.scale ?? 1.0;
				r.puddleY = values.puddleY ?? 0;
				r.puddleScaleY = values.puddleScaleY ?? 0;
			},
			update: (shader, elapsed, camera) ->
			{
				final r:RainShader = cast shader;
				r.update(elapsed);
				if (camera != null) r.updateViewInfo(FlxG.width, FlxG.height, camera);
			}
		});

		// ColorSwap is a wrapper; the actual filter is ColorSwapShader.
		register({
			id: 'colorSwap',
			label: 'Color Swap',
			create: () ->
			{
				final s = new ColorSwapShader();
				s.uTime.value = [0];
				s.money.value = [1.0];
				s.awesomeOutline.value = [false];
				return s;
			},
			fields: [
				{
					name: 'hueSpeed',
					label: 'Hue Speed',
					type: NUMBER,
					defaultValue: 1.0,
					min: 0,
					max: 10,
					step: 0.05
				},
				{
					name: 'hasOutline',
					label: 'Outline',
					type: CHECKBOX,
					defaultValue: false
				}
			],
			apply: (shader, values) ->
			{
				final s:ColorSwapShader = cast shader;
				// money stores hue speed for the update callback
				// wait why is it called money :sob:
				s.money.value = [values.hueSpeed ?? 1.0];
				s.awesomeOutline.value = [values.hasOutline == true];
			},
			update: (shader, elapsed, _) ->
			{
				final s:ColorSwapShader = cast shader;
				final speed = (s.money.value != null && s.money.value.length > 0) ? s.money.value[0] : 1.0;
				s.uTime.value[0] += elapsed * speed;
			}
		});
	}

	/**
	 * Register (or replace) a filter. Safe to call from mod scripts.
	 */
	public static function register(def:ShaderFilterDef):Void
	{
		if (_filters == null) init();

		if (!_filters.exists(def.id)) _order.push(def.id);
		_filters.set(def.id, def);
	}

	public static function unregister(id:String):Void
	{
		if (_filters == null) return;
		_filters.remove(id);
		_order.remove(id);
	}

	public static function get(id:String):Null<ShaderFilterDef>
	{
		if (_filters == null) init();
		return _filters.get(id);
	}

	public static function getByLabel(label:String):Null<ShaderFilterDef>
	{
		if (_filters == null) init();
		for (def in _filters) if (def.label == label) return def;
		return null;
	}

	public static function getLabels():Array<String>
	{
		if (_filters == null) init();
		return[for (id in _order) _filters.get(id).label];
	}

	public static function getIds():Array<String>
	{
		if (_filters == null) init();
		return _order.copy();
	}

	/**
	 * Advances time on an enabled shader.
	 * @param camera Optional camera from the handler (used by Rain for view bounds).
	 */
	public static function updateShader(id:String, shader:Shader, elapsed:Float, totalTime:Float, ?camera:FlxCamera):Void
	{
		final def = get(id);
		if (def != null && def.update != null)
		{
			def.update(shader, elapsed, camera);
			return;
		}

		if (!Std.isOfType(shader, FlxRuntimeShader)) return;

		final rt:FlxRuntimeShader = cast shader;
		rt.setFloat('iTime', totalTime);
		rt.setFloat('uTime', totalTime);
	}
}
