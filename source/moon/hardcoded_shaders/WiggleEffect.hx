package moon.hardcoded_shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.Assets;

enum abstract WiggleEffectType(Int) from Int to Int
{
	var DREAMY = 0;
	var WAVY = 1;
	var HEAT_WAVE_HORIZONTAL = 2;
	var HEAT_WAVE_VERTICAL = 3;
	var FLAG = 4;
}

/**
 * To use:
 * 1. Create an instance of the class, specifying speed, frequency, and amplitude.
 * 2. Call `sprite.shader = wiggleEffect` on the target sprite.
 * 3. Call the update() method on the instance every frame.
 */
@:nullSafety
class WiggleEffect extends FlxRuntimeShader
{
	public var effectType(default, set):Null<WiggleEffectType> = 0;

	function set_effectType(v:Null<WiggleEffectType>):Null<WiggleEffectType>
	{
		this.setInt('effectType', effectType ?? 0);
		return effectType = v;
	}

	public var waveSpeed(default, set):Float = 0;

	function set_waveSpeed(v:Float):Float
	{
		this.setFloat('uSpeed', v);
		return waveSpeed = v;
	}

	public var waveFrequency(default, set):Float = 0;

	function set_waveFrequency(v:Float):Float
	{
		this.setFloat('uFrequency', v);
		return waveFrequency = v;
	}

	public var waveAmplitude(default, set):Float = 0;

	function set_waveAmplitude(v:Float):Float
	{
		this.setFloat('uWaveAmplitude', v);
		return waveAmplitude = v;
	}

	var time(default, set):Float = 0;

	function set_time(v:Float):Float
	{
		this.setFloat('uTime', v);
		return time = v;
	}

	public function new(speed:Float, freq:Float, amplitude:Float, ?effect:WiggleEffectType = DREAMY):Void
	{
		super(Assets.getText(Paths.getPath('data/shaders/wiggle.frag')));

		// These values may not propagate to the shader until later.
		this.waveSpeed = speed;
		this.waveFrequency = freq;
		this.waveAmplitude = amplitude;
		this.effectType = effect;
	}

	public function update(elapsed:Float)
	{
		// The setter tied to this value automatically propagates the value to the shader.
		this.time += elapsed;
	}
}
