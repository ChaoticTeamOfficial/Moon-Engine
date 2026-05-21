package moon.backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.sound.FlxSound;
import openfl.media.Sound;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.io.Bytes;

using StringTools;

// I separated asset cleanup at `AssetManager`
// hopefully I won't ever need to touch this class again!! :'>

/**
 * Class for path resolution and asset retrieval.
 */
class Paths
{
    /**
     * Returns the vanilla (non-modded) asset path.
     * @param key     Relative path inside `assets/`.
     * @param library Optional sub-folder inside `assets/`.
     */
    public static function getVanillaPath(key:String, ?library:String):String
    {
        #if RENAME_UNDERSCORE
        var pathArray = key.split("/").copy();
        var loopCount = 0;
        key = "";
        for (folder in pathArray)
        {
            var truFolder = folder.startsWith("_") ? folder.substr(1) : folder;
            loopCount++;
            key += truFolder + (loopCount == pathArray.length ? "" : "/");
        }
        if (library != null)
            library = library.startsWith("_") ? library.split("_")[1] : library;
        #end

        return library == null ? 'assets/$key' : 'assets/$library/$key';
    }

    /**
     * Returns the resolved path for a key, preferring active mod overrides on desktop.
     * @param key     Relative path.
     * @param library Optional asset library/sub-folder.
     */
    public static function getPath(key:String, ?library:String):String
    {
        #if sys
        return Mods.getModdedPath(key, library);
        #else
        return getVanillaPath(key, library);
        #end
    }

    /**
     * Returns true if the given file path exists, checking mod overrides first.
     */
    public static function exists(filePath:String, ?library:String):Bool
    {
        final resolved = getPath(filePath, library);
        #if desktop
        return FileSystem.exists(resolved);
        #else
        return Assets.exists(resolved);
        #end
    }

    /**
     * Returns the raw byte content of a file, or null if it doesn't exist.
     */
    public static function getFileBytes(path:String, ?library:String):Bytes
    {
        final resolved = getPath(path, library);
        #if desktop
        if (!FileSystem.exists(resolved)) return null;
        return File.getBytes(resolved);
        #else
        if (!Assets.exists(resolved)) return null;
        return Assets.getBytes(resolved);
        #end
    }

    /**
     * Returns the text content of a file, or an empty string if missing.
     */
    public static function getFileContent(path:String, ?library:String):String
    {
        final bytes = getFileBytes(path, library);
        if (bytes == null)
        {
            trace('[PATHS] $path does not exist!', "ERROR");
            return "";
        }
        return bytes.toString();
    }

    /**
     * Parses and returns a JSON file as a Dynamic object, or null if missing/empty.
     */
    public static function JSON(key:String, ?format:String = 'json', ?library:String):Dynamic
    {
        final content = getFileContent('$key.$format', library);
        if (content == "" || content == null) return null;
        return haxe.Json.parse(content.trim());
    }

    /**
     * Returns a sound from cache, loading from disk if needed.
     * @param key     Path relative to `assets/`, including extension.
     * @param library Optional sub-folder.
     */
    public static function getSound(key:String, ?library:String):Sound
    {
        final resolved = getPath(key, library);
        final snd = AssetManager.getSound(key, resolved);
        if (snd == null) trace('[PATHS] $key does not exist!', "ERROR");
        return snd;
    }

    /**
     * Returns a graphic from cache, loading from disk if needed.
     * @param key  Filename without extension.
     * @param from Folder inside `assets/` (default: `images`).
     */
    public static function getGraphic(key:String, from:String = 'images', ?library:String):FlxGraphic
    {
        if (key.endsWith('.png'))
            key = key.substring(0, key.lastIndexOf('.png'));

        final imagePath = '$from/$key.png';
        final resolved  = getPath(imagePath, library);
        final g = AssetManager.getGraphic(key, imagePath, resolved);
        if (g == null) trace('[PATHS] $imagePath does not exist!', "ERROR");
        return g;
    }

    /** Loads a sound from `assets/<from>/<key>`. Defaults to the `music` folder. */
    public static function sound(key:String, from:String = 'music', ?library:String):Sound
        return getSound('$from/$key', library);

    /** Loads a graphic from `assets/<from>/<key>.png`. Defaults to the `images` folder. */
    public static function image(key:String, from:String = 'images', ?library:String):FlxGraphic
        return getGraphic(key, from, library);

    /** Returns the resolved path to a font file inside `assets/fonts/`. */
    public static function font(key:String, ?library:String):String
        return getPath('fonts/$key', library);

    /** Returns the resolved path to a `.mp4` file. */
    public static function mp4(key:String, ?library:String):String
        return getPath('$key.mp4', library);

    /** Returns trimmed text content from a `.txt` file. */
    public static function text(key:String, ?library:String):String
        return getFileContent('$key.txt', library).trim();

    /** Loads a Sparrow (.xml) atlas from `assets/<from>/<key>.png`. Defaults to the `images` folder. */
    public static function getSparrowAtlas(key:String, from:String = 'images', ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromSparrow(getGraphic(key, from, library), getFileContent('$from/$key.xml', library));

    /** Loads a Packer (.txt) atlas from `assets/<from>/<key>.png`. Defaults to the `images` folder. */
    public static function getPackerAtlas(key:String, from:String = 'images', ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromSpriteSheetPacker(getGraphic(key, from, library), getFileContent('$from/$key.txt', library));

    /** Loads an Aseprite (.json) atlas from `assets/<from>/<key>.png`. Defaults to the `images` folder. */
    public static function getAsepriteAtlas(key:String, from:String = 'images', ?library:String):FlxAtlasFrames
        return FlxAtlasFrames.fromAseprite(getGraphic(key, from, library), getFileContent('$from/$key.json', library));

    /**
     * Loads a Sparrow atlas split across multiple sprite sheets, merging them into one frame collection.
     * @param baseSheet   The primary sheet key.
     * @param from        Folder inside `assets/`.
     * @param otherSheets Additional sheet keys to merge in.
     */
    public static function getMultiSparrowAtlas(baseSheet:String, from:String = 'images', otherSheets:Array<String>, ?library:String):FlxFramesCollection
    {
        var frames:FlxFramesCollection = getSparrowAtlas(baseSheet, from);
        for (sheet in otherSheets)
            for (frame in getSparrowAtlas(sheet, from, library).frames)
                frames.pushFrame(frame);
        return frames;
    }

    /** Returns a `FlxGraphic` containing a single named frame from a Sparrow atlas. */
    public static function getFrame(key:String, from:String = 'images', frame:String, ?library:String):FlxGraphic
        return FlxGraphic.fromFrame(getSparrowAtlas(key, from).getByName(frame));

    /**
     * Lists files in a directory, merging results from all active mods and the vanilla folder.
     * Duplicate filenames are deduplicated as mod files take precedence.
     *
     * @param dir        Directory path relative to the asset root.
     * @param typeArr    Optional list of extensions to filter by (e.g. `[".json"]`).
     * @param removeType When true, the extension is stripped from returned names.
     * @param library    Optional sub-folder override.
     */
    public static function readDir(dir:String, ?typeArr:Array<String>, ?removeType:Bool = true, ?library:String):Array<String>
    {
        var result:Array<String> = [];

        #if desktop
        var relativeDir = (library != null ? '$library/' : '') + dir;
        if (!relativeDir.endsWith('/')) relativeDir += '/';

        var tempList:Array<String> = [];
        var seen:Map<String, Bool> = [];

        inline function addIfNew(files:Array<String>)
        {
            for (f in files)
                if (!seen.exists(f))
                {
                    seen.set(f, true);
                    tempList.push(f);
                }
        }

        for (mod in Mods.activeMods)
        {
            final modDir = '${mod.root}/$relativeDir';
            if (FileSystem.exists(modDir) && FileSystem.isDirectory(modDir))
                try
                {
                    addIfNew(FileSystem.readDirectory(modDir));
                }
                catch (_) {}
        }

        try
        {
            addIfNew(FileSystem.readDirectory(getVanillaPath(dir, library)));
        }
        catch (_) {}

        for (i in 0...tempList.length)
        {
            if (typeArr != null && typeArr.length > 0)
            {
                for (type in typeArr)
                {
                    if (tempList[i].endsWith(type))
                    {
                        result.push(removeType ? tempList[i].replace(type, "") : tempList[i]);
                        break;
                    }
                }
            }
            else result.push(tempList[i]);
        }
        #end

        return result;
    }

    /**
     * Preloads a graphic into cache without displaying it.
     */
    public static function preloadGraphic(key:String, from:String = 'images', ?library:String):Void
    {
        if (AssetManager.graphics.exists(key)) return;
        final spr = new FlxSprite().loadGraphic(image(key, from, library));
        FlxG.state.add(spr);
        FlxG.state.remove(spr);
    }

    /**
     * Preloads a sound into cache without playing it.
     */
    public static function preloadSound(key:String, from:String = 'music', ?library:String):Void
    {
        if (AssetManager.sounds.exists(key)) return;
        final snd = new FlxSound().loadEmbedded(getSound('$from/$key', library), false, false);
        snd.volume = 0;
        snd.play();
        snd.stop();
    }

    private static var _sfxCache = new Map<Sound, FlxSound>();

    /**
     * Plays a sound effect.
     * @param key   Path relative to `assets/<from>/`, including extension.
     * @param from  Source folder. Defaults to `sounds`.
     * @param once  When true, reuses a single cached `FlxSound` instance (stops if already playing).
     * @param pitch Playback pitch multiplier.
     */
    public inline static function playSFX(key:String, ?from:String = 'sounds', once:Bool = false, ?pitch:Float = 1):FlxSound
    {
        final src = sound(key, from);

        if (!once)
            return FlxG.sound.play(src, MoonSettings.callSetting('SFX Volume') / 100);

        var snd = _sfxCache.get(src);
        if (snd == null)
        {
            snd = FlxG.sound.load(src, 1.0, false, null, false, false);
            _sfxCache.set(src, snd);
        }

        if (snd.playing) snd.stop();
        snd.volume = MoonSettings.callSetting('SFX Volume') / 100;
        snd.persist = true;
        snd.pitch = pitch;
        return snd.play(true);
    }
}

typedef AnimationData = {
    var name:String;
    var prefix:String;
    var ?indices:Array<Int>;
    var ?x:Float;
    var ?y:Float;
    var ?fps:Int;
    var ?looped:Bool;
    var ?finishAnim:String;
}

enum abstract AtlasType(String) {
    var NONE = 'none';
    var SPARROW = 'sparrow';
    var PACKED = 'packed';
}

enum abstract AnimBehavior(String) {
    var ONBEAT = 'on-beat';
    var ONCE = 'once';
}