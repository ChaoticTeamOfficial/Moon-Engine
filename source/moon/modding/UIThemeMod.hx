package moon.modding;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;
import moon.toolkit.ui.UITheme;

@:publicFields
/**
 * A class simply made for loading UI themes for the editor!
 */
class UIThemeMod
{
	static function loadFromMods():Void
	{
		#if sys
		for (mod in Mods.activeMods)
		{
			final path = '${mod.root}/ui/theme.json';
			if (!FileSystem.exists(path)) continue;

			try
			{
				final data:Dynamic = Json.parse(File.getContent(path));
				apply(data);
				trace('[UIMod] Applied theme from ${mod.name}', "DEBUG");

				// TODO: should this be first mod only or (current) merge?
				// break;
			}
			catch (e)
			{
				trace('[UIMod] Failed to parse theme from ${mod.name}: $e', "ERROR");
			}
		}
		#end
	}

	static function apply(data:Dynamic):Void
	{
		// TODO
	}
}
