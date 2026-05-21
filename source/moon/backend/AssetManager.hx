package moon.backend;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.sound.FlxSound;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.io.Bytes;

@:publicFields

/**
 * A Class which handles all asset caching, loading, and memory cleanup.
 */
class AssetManager
{
    static var graphics:Map<String, FlxGraphic> = [];
    static var sounds:Map<String, Sound> = [];

    /**
     * Keys that won't be cleared during memory cleanup.
     * Append `.png` for graphics, `.ogg` or `.wav` for sounds.
     */
    static var exclusions:Array<String> = [];

    /**
     * When true, the next `clearAll()` call is skipped.
     * Useful when transitioning into states that immediately reuse cached assets.
     */
    static var skipNextCleanup:Bool = false;

    /**
     * Returns a cached graphic, loading it from disk if not yet cached.
     * @param cacheKey  Unique identifier for the cache entry.
     * @param imagePath The relative image path used to load from disk/assets.
     * @param fsPath    The resolved filesystem/assets path.
     */
    static function getGraphic(cacheKey:String, imagePath:String, fsPath:String):FlxGraphic
    {
        if (graphics.exists(cacheKey))
            return graphics.get(cacheKey);

        var bitmap:BitmapData;
        #if desktop
        if (!FileSystem.exists(fsPath)) return null;
        bitmap = BitmapData.fromFile(fsPath);
        #else
        if (!Assets.exists(fsPath)) return null;
        bitmap = Assets.getBitmapData(fsPath, false);
        #end

        bitmap.disposeImage();
        final g = FlxGraphic.fromBitmapData(bitmap, false, cacheKey, false);
        g.persist = true;
        graphics.set(cacheKey, g);
        return g;
    }

    /**
     * Returns a cached sound, loading it from disk if not yet cached.
     * @param cacheKey Unique identifier for the cache entry.
     * @param fsPath   The resolved filesystem/assets path.
     */
    static function getSound(cacheKey:String, fsPath:String):Sound
    {
        if (sounds.exists(cacheKey))
            return sounds.get(cacheKey);

        var snd:Sound;
        #if desktop
        if (!FileSystem.exists(fsPath)) return null;
        snd = Sound.fromFile(fsPath);
        #else
        if (!Assets.exists(fsPath)) return null;
        snd = Assets.getSound(fsPath, false);
        #end

        sounds.set(cacheKey, snd);
        return snd;
    }

    /**
     * Unloads all cached assets that are not in `exclusions`.
     */
    static function clearAll():Void
    {
        if (skipNextCleanup)
        {
            skipNextCleanup = false;
            return;
        }

        clearGraphics(false);
        clearSounds(false);
        runGC();
    }

    /**
     * Unloads only assets that are no longer referenced by any active sprite or sound.
     * Safer than `clearAll()` during gameplay.
     */
    static function clearUnused():Void
    {
        clearGraphics(true);
        clearSounds(true);
    }

    /**
     * Forcibly unloads a single graphic by cache key.
     */
    static function unloadGraphic(cacheKey:String):Void
    {
        final g = graphics.get(cacheKey);
        if (g == null) return;

        graphics.remove(cacheKey);
        destroyGraphic(g);
        //trace('[ASSET-MANAGER] Unloaded graphic: $cacheKey', "DEBUG");
    }

    /**
     * Forcibly unloads a single sound by cache key.
     */
    static function unloadSound(cacheKey:String):Void
    {
        final snd = sounds.get(cacheKey);
        if (snd == null) return;

        sounds.remove(cacheKey);
        snd.close();
        //trace('[ASSET-MANAGER] Unloaded sound: $cacheKey', "DEBUG");
    }

    static function clearGraphics(unusedOnly:Bool):Void
    {
        final cleared:Array<String> = [];

        for (key => g in graphics)
        {
            if (exclusions.contains('$key.png')) continue;
            if (unusedOnly && g.useCount > 0) continue;

            cleared.push(key);
            graphics.remove(key);
            destroyGraphic(g);
        }

        @:privateAccess
        for (key in FlxG.bitmap._cache.keys())
        {
            final obj = FlxG.bitmap._cache.get(key);
            if (obj == null || graphics.exists(key)) continue;

            obj.persist = false;
            if (obj.bitmap != null)
            {
                obj.bitmap.dispose();
                obj.bitmap.disposeImage();
            }
            FlxG.bitmap._cache.remove(key);
            #if (flixel < "6.0.0")
            obj.dump();
            #end
            obj.destroy();
        }

        if (cleared.length > 0)
            trace('[ASSET-MANAGER] Cleared ${cleared.length} graphic(s): $cleared', "DEBUG");
    }

    static function clearSounds(unusedOnly:Bool):Void
    {
        final cleared:Array<String> = [];

        for (key => snd in sounds)
        {
            if (exclusions.contains('$key.ogg')) continue;

            if (unusedOnly)
            {
                var inUse = false;
                @:privateAccess
                if (FlxG.sound.music != null && FlxG.sound.music._sound == snd)
                    inUse = true;

                if (!inUse)
                    for (s in FlxG.sound.list)
                        if (@:privateAccess s._sound == snd) { inUse = true; break; }

                if (inUse) continue;
            }

            cleared.push(key);
            snd.close();
            sounds.remove(key);
        }

        if (cleared.length > 0)
            trace('[ASSET-MANAGER] Cleared ${cleared.length} sound(s): $cleared', "DEBUG");
    }

    static function destroyGraphic(g:FlxGraphic):Void
    {
        g.persist = false;
        FlxG.bitmap.remove(g);

        if (g.bitmap != null)
        {
            g.bitmap.dispose();
            g.bitmap.disposeImage();
        }

        #if (flixel < "6.0.0")
        g.dump();
        #end
        g.destroy();
    }

    static function runGC():Void
    {
        #if cpp
        cpp.vm.Gc.run(true);
        cpp.vm.Gc.compact();
        #end

        System.gc();

        #if hl
        hl.Gc.major();
        hl.Gc.major(); // gotta run twice for it to work for some reason
        #end
    }
}
