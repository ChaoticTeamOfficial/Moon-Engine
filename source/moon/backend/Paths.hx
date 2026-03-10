package moon.backend;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.sound.FlxSound;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.io.Bytes;
import openfl.system.System;

using StringTools;

/**
 * The Paths class, used for getting ingame files and memory cleaning as well.
 * 
 * Would like to clarify that: This class belongs to Doido Engine, and I'm using it with permission.
 * https://github.com/DoidoTeam/FNF-Doido-Engine/blob/main/source/Paths.hx
 * (Give Doido Engine a try, It's a very well made engine! ^^)
 **/
class Paths
{
    public static var renderedGraphics:Map<String, FlxGraphic> = [];
    public static var renderedSounds:Map<String, Sound> = [];

    /**
     * Whether or not should the game skip the next memory cleanup.
     * Used for the loading screen. 
     */
    public static var skipNextCleanup:Bool = false;

    // idk
    public static function getPath(key:String, ?library:String):String
    {
        #if RENAME_UNDERSCORE
        var pathArray:Array<String> = key.split("/").copy();
        var loopCount = 0;
        key = "";

        for (folder in pathArray)
        {
            var truFolder:String = folder;

            if(folder.startsWith("_"))
                truFolder = folder.substr(1);

            loopCount++;
            key += truFolder + (loopCount == pathArray.length ? "" : "/");
        }

        if(library != null)
            library = (library.startsWith("_") ? library.split("_")[1] : library);
        #end

        if(library == null)
            return 'assets/$key';
        else
            return 'assets/$library/$key';
    }

    private static function fileExists(path:String, ?library:String):Bool
    {
        var fsPath:String = getPath(path, library);
        #if desktop
        return FileSystem.exists(fsPath);
        #else
        return Assets.exists(fsPath);
        #end
    }

    private static function getFileBytes(path:String, ?library:String):Bytes
    {
        var fsPath:String = getPath(path, library);
        #if desktop
        if (!FileSystem.exists(fsPath))
            return null;

        return File.getBytes(fsPath);
        #else
        if (!Assets.exists(fsPath))
            return null;

        return Assets.getBytes(fsPath);
        #end
    }
    
    public static function exists(filePath:String, ?library:String):Bool
        return fileExists(filePath, library);
    
    public static function getSound(key:String, ?library:String):Sound
    {
        var cacheKey:String = key;
        if (!renderedSounds.exists(cacheKey))
        {
            if (!fileExists(key, library))
            {
                trace('$key doesnt exist!', "ERROR");
                return null;
            }
            var sound:Sound;
            #if desktop
            sound = Sound.fromFile(getPath(key, library));
            #else
            sound = Assets.getSound(getPath(key, library), false);
            #end
            
            renderedSounds.set(cacheKey, sound);
        }
        return renderedSounds.get(cacheKey);
    }

    public static function getGraphic(key:String, from:String = 'images', ?library:String):FlxGraphic
    {
        final cacheKey:String = key;

        if (key.endsWith('.png'))
            key = key.substring(0, key.lastIndexOf('.png'));

        final imagePath:String = '$from/$key.png';
        if (!renderedGraphics.exists(cacheKey))
        {
            if (!fileExists(imagePath, library))
            {
                trace('$imagePath does not exist!', "ERROR");
                return null;
            }

            var bitmap:BitmapData;
            var fsPath = getPath(imagePath, library);
            #if desktop
            bitmap = BitmapData.fromFile(fsPath);
            #else
            bitmap = Assets.getBitmapData(fsPath, false);
            #end

            //hmmm doesnt seem to do anything different xd
            bitmap.disposeImage();
            var newGraphic = FlxGraphic.fromBitmapData(bitmap, false, cacheKey, false);
            newGraphic.persist = true;
            renderedGraphics.set(cacheKey, newGraphic);
        }
        return renderedGraphics.get(cacheKey);
    }
    
    /*  add .png at the end for images
    *   add .ogg at the end for sounds
    */
    public static var dumpExclusions:Array<String> = [];

    public static function clearMemory()
    {   
        // Clear graphics
        var clearCount:Array<String> = [];
        for(key => graphic in renderedGraphics)
        {
            if(dumpExclusions.contains(key + '.png')) continue;

            clearCount.push(key);
            
            renderedGraphics.remove(key);
            
            graphic.persist = false;
            FlxG.bitmap.remove(graphic);
            
            if(graphic.bitmap != null)
            {
                graphic.bitmap.dispose();
                graphic.bitmap.disposeImage();
            }
            
            #if (flixel < "6.0.0")
            graphic.dump();
            #end
            graphic.destroy();
        }

        if(clearCount.length > 0)
        {
            trace('cleared $clearCount', "DEBUG");
            trace('cleared ${clearCount.length} assets', "DEBUG");
        }

        // uhhhh
        @:privateAccess
        for(key in FlxG.bitmap._cache.keys())
        {
            var obj = FlxG.bitmap._cache.get(key);
            if(obj != null && !renderedGraphics.exists(key))
            {
                obj.persist = false;
                
                if(obj.bitmap != null)
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
        }
        
        // sound clearing
        // well uhm this kinda kills menu music :T
        /*for (key => sound in renderedSounds)
        {
            if(dumpExclusions.contains(key + '.ogg')) continue;
            
            sound.close();
            renderedSounds.remove(key);
        }*/

        renderedGraphics.clear();
        renderedSounds.clear();

        #if cpp
        cpp.vm.Gc.run(true);
        cpp.vm.Gc.compact();
        #end
        
        System.gc();
        
        #if hl
        hl.Gc.major();
        #end
    }

    public static function clearUnusedAssets()
    {
        // Clear unused graphics
        var clearedGraphics:Array<String> = [];
        for (key => graphic in renderedGraphics)
        {
            if (dumpExclusions.contains(key + '.png')) continue;
            if (graphic.useCount > 0) continue;

            clearedGraphics.push(key);
            renderedGraphics.remove(key);
            
            graphic.persist = false;
            FlxG.bitmap.remove(graphic);
            #if (flixel < "6.0.0")
            graphic.dump();
            #end
            graphic.destroy();
        }

        // Clear unused sounds (not referenced by any active sound)
        var clearedSounds:Array<String> = [];
        for (key => sound in renderedSounds)
        {
            if (dumpExclusions.contains(key + '.ogg')) continue;

            var isUsed:Bool = false;

            // Check music
            @:privateAccess
            if (FlxG.sound.music != null && FlxG.sound.music._sound == sound)
                isUsed = true;

            // Check active sounds
            if (!isUsed)
            {
                for (flxSound in FlxG.sound.list)
                {
                    if (@:privateAccess flxSound._sound == sound)
                    {
                        isUsed = true;
                        break;
                    }
                }
            }

            if (!isUsed)
            {
                clearedSounds.push(key);
                sound.close();
                renderedSounds.remove(key);
            }
        }

        if(clearedGraphics.length > 0) trace('cleared graphics $clearedGraphics', "DEBUG");
        if(clearedSounds.length > 0) trace('cleared sounds $clearedSounds', "DEBUG");
    }
    
    public static function sound(key:String, from:String = 'music', ?library:String):Sound
        return getSound('$from/$key', library);
    
    public static function image(key:String, from:String = 'images', ?library:String):FlxGraphic
        return getGraphic(key, from, library);
    
    public static function font(key:String, ?library:String):String
        return getPath('fonts/$key', library);

    public static function mp4(key:String, ?library:String):String
        return getPath('$key.mp4', library);

    public static function text(key:String, ?library:String):String
        return getFileContent('$key.txt', library).trim();

    public static function getFileContent(path:String, ?library:String):String
    {
        var bytes:Bytes = getFileBytes(path, library);
        if (bytes == null)
        {
            trace('$path doesnt exist!', "ERROR");
            return "";
        }
        return bytes.toString();
    }

    public static function JSON(key:String, ?format:String = 'json', ?library:String):Dynamic
    {
        final content = getFileContent('$key.$format', library);
        if(content == "" || content == null) return null;
        
        return haxe.Json.parse(content.trim());
    }

    public static function video(key:String, ?library:String):String
        return getPath('videos/$key.mp4', library);
    
    // sparrow (.xml) sheets
    public static function getSparrowAtlas(key:String, from:String = 'images', ?library:String)
        return FlxAtlasFrames.fromSparrow(getGraphic(key, from, library), getFileContent(('$from/$key.xml'), library));
    
    // packer (.txt) sheets
    public static function getPackerAtlas(key:String, from:String = 'images', ?library:String)
        return FlxAtlasFrames.fromSpriteSheetPacker(getGraphic(key, from, library), getFileContent('$from/$key.txt', library));

    // aseprite (.json) sheets
    public static function getAsepriteAtlas(key:String, from:String = 'images', ?library:String)
        return FlxAtlasFrames.fromAseprite(getGraphic(key, from, library), getFileContent('$from/$key.json', library));

    // sparrow (.xml) sheets but split into multiple graphics
    public static function getMultiSparrowAtlas(baseSheet:String, from:String = 'images', otherSheets:Array<String>, ?library:String) {
        var frames:FlxFramesCollection = getSparrowAtlas(baseSheet, from);

        if(otherSheets.length > 0) {
            for(i in 0...otherSheets.length) {
                var newFrames:FlxFramesCollection = getSparrowAtlas(otherSheets[i], from);
                for(frame in newFrames.frames) {
                    frames.pushFrame(frame);
                }
            }
        }

        return frames;
    }

    // get single frame (for now sparrow only)
    public static function getFrame(key:String, from:String = 'images', frame:String, ?library:String):FlxGraphic
        return FlxGraphic.fromFrame(getSparrowAtlas(key, from).getByName(frame));
        
    public static function readDir(dir:String, ?typeArr:Array<String>, ?removeType:Bool = true, ?library:String):Array<String>
    {
        var swagList:Array<String> = [];
        
        try {
            #if desktop
            var rawList = FileSystem.readDirectory(getPath(dir, library));
            for(i in 0...rawList.length)
            {
                if(typeArr?.length > 0)
                {
                    for(type in typeArr) {
                        if(rawList[i].endsWith(type)) {
                            // cleans it
                            if(removeType)
                                rawList[i] = rawList[i].replace(type, "");
                            swagList.push(rawList[i]);
                        }
                    }
                }
                else
                    swagList.push(rawList[i]);
            }
            #end
        } catch(e) {}
        
        //trace('read dir ${(swagList.length > 0) ? '$swagList' : 'EMPTY'} at ${getPath(dir, library)}', "DEBUG");
        return swagList;
    }

    public static function preloadGraphic(key:String, from:String = 'images', ?library:String)
    {
        // no point in preloading something already loaded duh
        if(renderedGraphics.exists(key)) return;

        var what = new FlxSprite().loadGraphic(image(key, from, library));
        FlxG.state.add(what);
        FlxG.state.remove(what);
    }

    public static function preloadSound(key:String, from:String = 'music', ?library:String)
    {
        if(renderedSounds.exists(key)) return;

        var what = new FlxSound().loadEmbedded(getSound('$from/$key', library), false, false);
        what.play();
        what.stop();
    }

    private static var sfxCache = new Map<Sound, FlxSound>();
    public inline static function playSFX(key:String, once:Bool = false)
    {
        var snd:FlxSound;
        final p:Sound = sound('$key', 'sounds');

        if(!once)
            return FlxG.sound.play(p, MoonSettings.callSetting('SFX Volume') / 100);

        if (!sfxCache.exists(p))
        {
            snd = FlxG.sound.load(p, 1.0, false, null, false, false);
            sfxCache.set(p, snd);
        }
        else snd = sfxCache.get(p);

        if(snd.playing) snd.stop();

        snd.volume = MoonSettings.callSetting('SFX Volume') / 100;
        return snd.play(true);
    }

    public static inline function spaceToDash(string:String):String
        return string.replace(" ", "-");

    public static inline function dashToSpace(string:String):String
        return string.replace("-", " ");

    public static inline function swapSpaceDash(string:String):String
        return string.contains('-') ? dashToSpace(string) : spaceToDash(string);
}

/**
 * An typedef for animation data, useful for spritesheets with jsons.
 */
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