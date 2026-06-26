package moon.dependency;

import openfl.display.Shader;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import haxe.extern.EitherType;

/**
 * Manages shaders and their filter wrappers.
 */
class MoonShaderHandler
{
	public static var instances:Array<MoonShaderHandler> = [];

	/**
	 * All registered raw shaders. Key is a string ID.
	 */
	public var shaders:Map<String, Shader> = [];

	private var _filters:Map<String, ShaderFilter> = [];
	private var _enabled:Map<String, Bool> = [];

	/**
	 * Tracks if a specific ID was added explicitly as a ShaderFilter.
	 * If true, it skips applying to Sprites and ONLY applies to Cameras.
	 */
	private var _isExplicitFilter:Map<String, Bool> = [];

	/**
	 * Stores the original shaders/filters of targets before this handler modified them,
	 * so they can be perfectly restored upon removal.
	 */
	private var _originalState:Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();

	/**
	 * The targets whose `filters`/`shader` this handler manages.
	 */
	public var targets:Array<Dynamic> = [];

	public function new(?target:Dynamic)
	{
		targets = [];

		if (target != null)
		{
			if (Std.isOfType(target, Array)) for (t in (cast target : Array<Dynamic>)) addTarget(t);
			else
				addTarget(target);
		}

		instances.push(this);
	}

	/**
	 * Adds a new target to apply the shaders to.
	 */
	public function addTarget(target:Dynamic):MoonShaderHandler
	{
		if (target != null && targets.indexOf(target) == -1)
		{
			var backup:Dynamic = {};

			if (Reflect.hasField(target, "shader")) Reflect.setField(backup, "shader", Reflect.field(target, "shader"));

			if (Reflect.hasField(target, "filters")) Reflect.setField(backup, "filters", Reflect.field(target, "filters"));

			_originalState.set(target, backup);
			targets.push(target);
			_pushFilters();
		}
		return this;
	}

	/**
	 * Removes a target and restores its original shaders/filters.
	 */
	public function removeTarget(target:Dynamic):MoonShaderHandler
	{
		if (targets.remove(target))
		{
			final backup = _originalState.get(target);
			if (backup != null)
			{
				if (
					Reflect.hasField(backup, "shader")
					&& Reflect.hasField(target, "shader")
				) Reflect.setField(target, "shader", Reflect.field(backup, "shader"));

				if (
					Reflect.hasField(backup, "filters")
					&& Reflect.hasField(target, "filters")
				) Reflect.setField(target, "filters", Reflect.field(backup, "filters"));
			}

			_originalState.remove(target);
		}
		return this;
	}

	/**
	 * Adds a shader and optionally enables it immediately.
	 * @param id      Unique string ID.
	 * @param shader  Can be a raw `Shader` or an explicit `ShaderFilter`.
	 * @param enabled Whether to enable it on add.
	 */
	public function add(id:String, shader:EitherType<Shader, ShaderFilter>, enabled:Bool = true):MoonShaderHandler
	{
		var rawShader:Shader;
		var filter:ShaderFilter;
		var isExplicit:Bool = false;

		if (Std.isOfType(shader, ShaderFilter))
		{
			isExplicit = true;
			filter = cast shader;
			rawShader = filter.shader;
		}
		else
		{
			isExplicit = false;
			rawShader = cast shader;
			filter = new ShaderFilter(rawShader);
		}

		shaders.set(id, rawShader);
		_filters.set(id, filter);
		_isExplicitFilter.set(id, isExplicit);
		_enabled.set(id, enabled);

		_pushFilters();
		return this;
	}

	/**
	 * Removes a shader entirely from all targets.
	 */
	public function remove(id:String):MoonShaderHandler
	{
		shaders.remove(id);
		_filters.remove(id);
		_isExplicitFilter.remove(id);
		_enabled.remove(id);
		_pushFilters();
		return this;
	}

	/**
	 * Enables or disables a specific shader by ID across all targets.
	 */
	public function setEnabled(id:String, enabled:Bool):MoonShaderHandler
	{
		if (_enabled.exists(id))
		{
			_enabled.set(id, enabled);
			_pushFilters();
		}
		return this;
	}

	/**
	 * Toggles a specific shader by ID.
	 */
	public function toggle(id:String):MoonShaderHandler
	{
		if (_enabled.exists(id)) setEnabled(id, !_enabled.get(id));
		return this;
	}

	/**
	 * Returns the raw Shader instance for a given ID.
	 */
	public function getShader(id:String):Shader return shaders.get(id);

	/**
	 * Returns the ShaderFilter wrapper for a given ID.
	 */
	public function getFilter(id:String):ShaderFilter return _filters.get(id);

	/**
	 * Re-applies filters/shaders to all targets, taking the shaders setting in account.
	 */
	public function refresh():MoonShaderHandler
	{
		_pushFilters();
		return this;
	}

	/**
	 * Compiles and pushes the active shaders/filters to all targets.
	 */
	private function _pushFilters():Void
	{
		if (targets.length == 0) return;

		var isGlobalEnabled = (MoonSettings.callSetting('Shaders') ?? true);

		for (t in targets)
		{
			var hasDirectShader = Reflect.hasField(t, "shader");
			var hasFilters = Reflect.hasField(t, "filters");

			if (hasDirectShader)
			{
				// TARGET IS LIKELY A SPRITE
				var applicableRawShaders:Array<Shader> = [];

				for (id => filter in _filters)
				{
					if (!isGlobalEnabled || !_enabled.get(id)) continue;
					if (_isExplicitFilter.get(id)) continue;

					applicableRawShaders.push(shaders.get(id));
				}

				if (applicableRawShaders.length == 1)
				{
					Reflect.setField(t, "shader", applicableRawShaders[0]);
					if (hasFilters) Reflect.setField(t, "filters", null);
				}
				else if (applicableRawShaders.length > 1)
				{
					var fArr:Array<BitmapFilter> = [];
					for (s in applicableRawShaders) fArr.push(new ShaderFilter(s));

					if (hasFilters) Reflect.setField(t, "filters", fArr);
					Reflect.setField(t, "shader", null);
				}
				else
				{
					Reflect.setField(t, "shader", null);
					if (hasFilters) Reflect.setField(t, "filters", null);
				}
			}
			else if (hasFilters)
			{
				// TARGET IS LIKELY A CAMERA
				var cameraFilters:Array<BitmapFilter> = [];

				for (id => filter in _filters)
				{
					if (!isGlobalEnabled || !_enabled.get(id)) continue;
					cameraFilters.push(filter);
				}

				Reflect.setField(t, "filters", cameraFilters.length > 0 ? cameraFilters : null);
			}
		}
	}

	public function destroy()
	{
		// Restore original states for all managed targets before destroying!
		for (t in targets)
		{
			final backup = _originalState.get(t);
			if (backup != null)
			{
				// oh fuuuucckkk this engine aint running on android nuh uh
				// reflect my belove,,,,,,,
				if (Reflect.hasField(backup, "shader") && Reflect.hasField(t, "shader")) Reflect.setField(t, "shader", Reflect.field(backup, "shader"));

				if (Reflect.hasField(backup, "filters") && Reflect.hasField(t, "filters")) Reflect.setField(t, "filters", Reflect.field(backup, "filters"));
			}
		}

		targets.resize(0);
		_originalState.clear();
		shaders.clear();
		_filters.clear();
		_enabled.clear();
		_isExplicitFilter.clear();

		instances.remove(this);
	}
}
