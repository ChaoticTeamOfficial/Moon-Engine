package moon.modding;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;

using StringTools;

@:publicFields
/**
 * The main mod manager!
 * Used to scan the mods folder and overall provide some access over mods.
 */
class Mods
{
	static var allMods:Array<Mod> = [];
	static var activeMods:Array<Mod> = [];
	static var loadOrder:Array<String> = [];
	static var config:
		{enabled:Array<String>, order:Array<String>} = {
			enabled: [],
			order: []
		};

	static function scanMods():Void
	{
		allMods = [];
		activeMods = [];

		#if sys
		loadConfig();

		final items = FileSystem.readDirectory('mods/');
		for (item in items)
		{
			final fullPath = 'mods/$item';

			if (FileSystem.isDirectory(fullPath))
			{
				final mod = new Mod(item, fullPath);
				allMods.push(mod);
			}
		}

		rebuildActiveMods();
		#end
	}

	static function rebuildActiveMods():Void
	{
		activeMods = [];

		for (modName in loadOrder)
		{
			var mod:Mod = null;
			for (m in allMods)
			{
				if (m.name == modName)
				{
					mod = m;
					break;
				}
			}

			if (mod != null && config.enabled.contains(modName)) activeMods.push(mod);
		}

		trace('[MODS] Active mods (in order): ${[for (m in activeMods) m.name]}', "DEBUG");
	}

	static function saveConfig():Void
	{
		#if sys
		config.enabled = [for (mod in allMods) if (config.enabled.contains(mod.name)) mod.name];
		config.order = loadOrder;

		File.saveContent('mods/mods.json', Json.stringify(config, null, "\t"));
		trace('[MODS] Saved mod config!', "DEBUG");
		#end
	}

	static function loadConfig():Void
	{
		#if sys
		final path = 'mods/mods.json';
		if (FileSystem.exists(path))
		{
			try
			{
				config = Json.parse(File.getContent(path));
				loadOrder = config.order ?? [];
			}
			catch (e)
			{
			}
		}
		else
		{
			config.enabled = [];
			config.order = [];
			saveConfig();
		}
		#end
	}

	/**
	 * Toggles a mod on or off.
	 */
	static function toggleMod(modName:String):Void
	{
		if (config.enabled.contains(modName)) config.enabled.remove(modName);
		else
			config.enabled.push(modName);

		rebuildActiveMods();
		saveConfig();
	}

	/**
	 * Returns the first modded path that exists (highest priority mod).
	 */
	static function getModdedPath(originalPath:String, ?library:String):String
	{
		#if sys
		for (mod in activeMods)
		{
			final modPath = mod.getAsset(originalPath, library);
			if (modPath != null) return modPath;
		}
		#end
		return Paths.getVanillaPath(originalPath, library);
	}

	/**
	 * Returns the root folder of the first active mod that contains `originalPath`,
	 * or null if no active mod has it (meaning it lives in vanilla `assets/`).
	 */
	static function getOwningMod(originalPath:String, ?library:String):Null<Mod>
	{
		#if sys
		for (mod in activeMods)
		{
			final modPath = mod.getAsset(originalPath, library);
			if (modPath != null) return mod;
		}
		#end
		return null;
	}

	static function getOwningModRoot(originalPath:String, ?library:String):Null<String> return getOwningMod(originalPath, library)?.root;

	/**
	 * True when `query` matches this mod's `id`, folder name (`Mod.name`), or display name (`metadata.name`).
	 */
	static function matchesName(mod:Mod, query:String):Bool
	{
		if (mod == null || query == null || query == '') return false;

		final q = query.toLowerCase();
		if (mod.id != null && mod.id.toLowerCase() == q) return true;

		if (mod.name.toLowerCase() == q) return true;
		final display = mod.metadata?.name;

		if (display != null && display != '' && display != 'None' && display.toLowerCase() == q) return true;
		return false;
	}

	/**
	 * Finds an active mod by id, folder name, or metadata display name.
	 */
	static function getActiveMod(name:String):Null<Mod>
	{
		for (mod in activeMods) if (matchesName(mod, name)) return mod;
		return null;
	}

	/**
	 * Finds any scanned mod by id, folder name, or metadata display name.
	 */
	static function getMod(name:String):Null<Mod>
	{
		for (mod in allMods) if (matchesName(mod, name)) return mod;
		return null;
	}

	/**
	 * Preferred human-readable name: metadata display name when set, otherwise folder name.
	 */
	static function getDisplayName(mod:Mod):String
	{
		if (mod == null) return '';
		final display = mod.metadata?.name;
		if (display != null && display != '' && display != 'None') return display;
		return mod.name;
	}
}
