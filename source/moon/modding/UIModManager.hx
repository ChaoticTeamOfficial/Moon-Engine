package moon.modding;

import moon.modding.UIModRegistry.UILayoutData;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * A Manager for modding the ingame UI (like healthbar, stats, etc!)
 */
@:publicFields
class UIModManager
{
	static var layouts:Map<String, Map<String, UILayoutData>> = [];

	/** 
	 * Load all layout files from active mods.
	 */
	static function loadLayouts():Void
	{
		layouts.clear();
		#if sys
		for (mod in Mods.activeMods)
		{
			final dir = '${mod.root}/ui/layouts';
			if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) continue;

			for (file in FileSystem.readDirectory(dir))
			{
				if (!file.endsWith(".json")) continue;
				final context = file.substr(0, file.length - 5);
				try
				{
					final raw:Dynamic = Json.parse(File.getContent('$dir/$file'));
					final map = layouts.get(context) ?? new Map();
					for (id in Reflect.fields(raw)) map.set(id, Reflect.field(raw, id));
					layouts.set(context, map);
				}
				catch (e)
					trace('[UIMod] Bad layout $file in ${mod.name}', "ERROR");
			}
		}
		#end
	}

	static function applyLayouts(context:String):Void
	{
		final map = layouts.get(context);
		if (map == null) return;
		for (id => data in map) UIModRegistry.applyLayout(id, data);
	}
}
