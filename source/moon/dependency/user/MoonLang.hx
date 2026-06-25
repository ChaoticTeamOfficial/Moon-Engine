package moon.dependency.user;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using Lambda;

/**
 * Metadata stored in the meta block of a locale file.
 */
typedef LocaleMeta =
{
	/**
	 * The display name for this language. (E.G. "English (US)")
	 */
	var name:String;

	/**
	 * The locale code used to identify the file (e.g. "en-US")
	 */
	var code:String;

	/**
	 * The translation credit for the language.
	 */
	var ?author:String;
};

@:publicFields
/**
 * Manages game localization. Locale files are at `data/locales/<code>.json`.
 *
 * Locale file format:
 * ```json
 * {
 *   "meta": { "name": "English (US)", "code": "en-US", "author": "Chaotic Team" },
 *   "strings": {
 *     "setting.Master Volume.name": "Master Volume",
 *     "setting.Master Volume.desc": "Changes the game's main volume.",
 *     "category.Sound Settings": "SOUND SETTINGS",
 *     "ui.some.key": "Some string"
 *   }
 * }
 * ```
 * Mods should be able to automatically "merge".
 */
class MoonLang
{
	/**
	 * The currently active locale code.
	 */
	static var currentCode(default, null):String = 'en-US';

	/**
	 * All loaded strings for the active locale.
	 */
	static var strings(default, null):Map<String, String> = [];

	/**
	 * English strings, always kept as a fallback regardless of the active locale.
	 */
	static var fallback(default, null):Map<String, String> = [];

	/**
	 * All locale metadata discovered by the last `scan()` call.
	 */
	static var available(default, null):Array<LocaleMeta> = [];

	/**
	 * Scans `data/locales/` for available locale files.
	 */
	static function scan():Void
	{
		available = [];

		for (file in Paths.readDir('data/locales', ['.json'], true))
		{
			final data:Dynamic = Paths.JSON('data/locales/$file');
			if (data?.meta?.code == null) continue;

			available.push({
				name: data.meta.name ?? data.meta.code,
				code: data.meta.code,
				author: data.meta.author
			});
		}

		if (available.length == 0) trace('[LANG] No locale files found in "data/locales"!', "WARNING");
		else
			trace('[LANG] Discovered ${available.length} locale(s): ${[for (l in available) l.code]}', "DEBUG");
	}

	/**
	 * Reads the saved Language setting and loads it.
	 */
	static function loadFromSettings():Void load(_codeFromName(MoonSettings.callSetting('Language') ?? '') ?? Constants.FALLBACK_LANG);

	/**
	 * Loads a locale by its code.
	 * @param code The language name (e.g. `en-US`).
	 */
	static function load(code:String):Void
	{
		strings = [];
		fallback = [];

		// english is always loaded as the base fallback.
		// I mean, the default one does, unless someone changes the fallback lang
		_loadVanilla(Constants.FALLBACK_LANG, fallback);
		_loadMods(Constants.FALLBACK_LANG, fallback);

		if (code == Constants.FALLBACK_LANG) strings = [for (k => v in fallback) k => v];
		else
		{
			_loadVanilla(code, strings);
			_loadMods(code, strings);

			if (strings.count() == 0)
			{
				trace('[LANG] Locale "$code" has no strings, using ${Constants.FALLBACK_LANG}.', "WARNING");
				code = Constants.FALLBACK_LANG;
				strings = [for (k => v in fallback) k => v];
			}
		}

		currentCode = code;
		trace('[LANG] Loaded "$currentCode" (${strings.count()} strings).', "DEBUG");
	}

	/**
	 * Returns the localized string for `key`.
	 * @param key    The string key to look up.
	 * @param def    Optional default if the key is missing entirely.
	 */
	static inline function get(key:String, ?def:String):String
	{
		if (strings.exists(key)) return strings.get(key);
		if (fallback.exists(key)) return fallback.get(key);
		return def ?? key;
	}

	/**
	 * Returns the localized display name for a setting.
	 * Falls back to `name` itself if no translation exists.
	 */
	static inline function settingName(name:String):String return get('setting.$name.name', name);

	/**
	 * Returns the localized description for a setting.
	 * Falls back to `fallbackDesc` if no translation exists.
	 */
	static inline function settingDesc(name:String, ?fallbackDesc:String):String return get('setting.$name.desc', fallbackDesc ?? '');

	/**
	 * Returns the localized display name for a settings category.
	 * Falls back to the category string itself.
	 */
	static inline function category(name:String):String return get('category.$name', name.toUpperCase());

	/**
	 * Returns the display names of all available locales, in scan order.
	 * Used to populate the Languages in settings.
	 */
	static function getDisplayNames():Array<String> return[for (l in available) l.name];

	/**
	 * Returns the locale codes for all available locales, in scan order.
	 */
	static function getCodes():Array<String> return[for (l in available) l.code];

	// -- Internals wooohooo I'm free from documenting SMH...
	// codename engine reference????

	private static function _codeFromName(displayName:String):Null<String>
	{
		for (l in available) if (l.name == displayName) return l.code;
		return null;
	}

	private static function _loadVanilla(code:String, into:Map<String, String>):Void
	{
		// getVanillaPath bypasses mod overrides so we always read the base file.
		#if sys
		final path = Paths.getVanillaPath('data/locales/$code.json');
		if (!FileSystem.exists(path)) return;

		try
		{
			final data:Dynamic = haxe.Json.parse(File.getContent(path));
			_mergeStrings(data, into);
		}
		catch (e)
		{
			trace('[LANG] Failed to parse vanilla locale "$code": $e', "ERROR");
		}
		#else
		final data:Dynamic = Paths.JSON('data/locales/$code');
		_mergeStrings(data, into);
		#end
	}

	private static function _loadMods(code:String, into:Map<String, String>):Void
	{
		#if sys
		for (mod in Mods.activeMods)
		{
			final path = '${mod.root}/data/locales/$code.json';
			if (!FileSystem.exists(path)) continue;

			try
			{
				final data:Dynamic = haxe.Json.parse(File.getContent(path));
				_mergeStrings(data, into);
			}
			catch (e)
			{
				trace('[LANG] Failed to parse mod locale "${mod.name}/$code": $e', "ERROR");
			}
		}
		#end
	}

	private static function _mergeStrings(data:Dynamic, into:Map<String, String>):Void
	{
		if (data?.strings == null) return;
		for (key in Reflect.fields(data.strings)) into.set(key, Std.string(Reflect.field(data.strings, key)));
	}
}
