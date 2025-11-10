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

    private static function fileExists(path:String, ?library:String, isMod:Bool = false):Bool
    {
        if (isMod)
        {
            return Global.currentModFiles.exists(path);
        }
        else
        {
            var fsPath:String = getPath(path, library);
            #if desktop
            return FileSystem.exists(fsPath);
            #else
            return Assets.exists(fsPath);
            #end
        }
    }

    private static function getFileBytes(path:String, ?library:String, isMod:Bool = false):Bytes
    {
        if (isMod)
        {
            if (!Global.currentModFiles.exists(path))
            {
                return null;
            }
            return Global.currentModFiles.get(path);
        }
        else
        {
            var fsPath:String = getPath(path, library);
            #if desktop
            if (!FileSystem.exists(fsPath))
            {
                return null;
            }
            return File.getBytes(fsPath);
            #else
            if (!Assets.exists(fsPath))
            {
                return null;
            }
            return Assets.getBytes(fsPath);
            #end
        }
    }
    
    public static function exists(filePath:String, ?library:String):Bool
    {
        var isMod = filePath.startsWith('curMod/');
        var checkPath = isMod ? filePath.substr(7) : filePath;
        return fileExists(checkPath, library, isMod);
    }
    
    public static function getSound(key:String, ?library:String):Sound
    {
        var cacheKey:String = key;
        var isMod = key.startsWith('curMod/');
        var soundRelative:String = isMod ? key.substr(7) : key;
        var soundPath:String = soundRelative + '.ogg';
        if (!renderedSounds.exists(cacheKey))
        {
            if (!fileExists(soundPath, library, isMod))
            {
                trace('$soundPath doesnt exist!${isMod ? " in mod" : ""}', "ERROR");
                return null;
            }
            var sound:Sound;
            if (isMod)
            {
                var bytes:Bytes = getFileBytes(soundPath, library, true);
                if (bytes == null)
                {
                    return null;
                }
                var buffer:AudioBuffer = AudioBuffer.fromBytes(bytes);
                sound = Sound.fromAudioBuffer(buffer);
            }
            else
            {
                #if desktop
                sound = Sound.fromFile(getPath(soundPath, library));
                #else
                sound = Assets.getSound(getPath(soundPath, library), false);
                #end
            }
            renderedSounds.set(cacheKey, sound);
        }
        return renderedSounds.get(cacheKey);
    }

    public static function getGraphic(key:String, from:String = 'images', ?library:String):FlxGraphic
    {
        var cacheKey:String = key;
        var isMod = key.startsWith('curMod/');
        var graphicRelative:String = isMod ? key.substr(7) : key;
        if (!isMod && graphicRelative.endsWith('.png'))
            graphicRelative = graphicRelative.substring(0, graphicRelative.lastIndexOf('.png'));
        var imagePath:String = isMod ? graphicRelative + '.png' : '$from/$graphicRelative.png';
        if (!renderedGraphics.exists(cacheKey))
        {
            if (!fileExists(imagePath, library, isMod))
            {
                trace('$imagePath does not exist!${isMod ? " in mod" : ""}', "ERROR");
                return null;
            }
            var bitmap:BitmapData;
            if (isMod)
            {
                var bytes:Bytes = getFileBytes(imagePath, library, true);
                if (bytes == null)
                {
                    return null;
                }
                bitmap = BitmapData.fromBytes(bytes);
            }
            else
            {
                var fsPath = getPath(imagePath, library);
                #if desktop
                bitmap = BitmapData.fromFile(fsPath);
                #else
                bitmap = Assets.getBitmapData(fsPath, false);
                #end
            }
            var newGraphic = FlxGraphic.fromBitmapData(bitmap, false, cacheKey, false);
            renderedGraphics.set(cacheKey, newGraphic);
        }
        return renderedGraphics.get(cacheKey);
    }
    
    /*  add .png at the end for images
    *   add .ogg at the end for sounds
    */
    public static var dumpExclusions:Array<String> = [
        "menus/alphabet.png"
    ];
    public static function clearMemory()
    {   
        // sprite caching
        var clearCount:Array<String> = [];
        for(key => graphic in renderedGraphics)
        {
            if(dumpExclusions.contains(key + '.png')) continue;

            clearCount.push(key);
            
            renderedGraphics.remove(key);
            
            FlxG.bitmap.remove(graphic);
            #if (flixel < "6.0.0")
            graphic.dump();
            #end
            graphic.destroy();
        }

        trace('cleared $clearCount', "DEBUG");
        trace('cleared ${clearCount.length} assets', "DEBUG");

        // uhhhh
        @:privateAccess
        for(key in FlxG.bitmap._cache.keys())
        {
            var obj = FlxG.bitmap._cache.get(key);
            if(obj != null && !renderedGraphics.exists(key))
            {
                FlxG.bitmap._cache.remove(key);
                #if (flixel < "6.0.0")
                obj.dump();
                #end
                obj.destroy();
            }
        }
        
        // sound clearing
        for (key => sound in renderedSounds)
        {
            if(dumpExclusions.contains(key + '.ogg')) continue;
            
            renderedSounds.remove(key);
        }
    }
    
    public static function sound(key:String, from:String = 'music', ?library:String):Sound
        return getSound('$from/$key', library);
    
    public static function image(key:String, from:String = 'images', ?library:String):FlxGraphic
        return getGraphic(key, from, library);
    
    public static function font(key:String, ?library:String):String
        return getPath('fonts/$key', library);

    public static function text(key:String, ?library:String):String
    {
        var isMod = key.startsWith('curMod/');
        var txtPath = isMod ? key.substr(7) + '.txt' : '$key.txt';
        return getFileContent(txtPath, library, isMod).trim();
    }

    public static function getFileContent(path:String, ?library:String, isMod:Bool = false):String
    {
        var bytes:Bytes = getFileBytes(path, library, isMod);
        if (bytes == null)
        {
            trace('$path doesnt exist!${isMod ? " in mod" : ""}', "ERROR");
            return "";
        }
        return bytes.toString();
    }

    public static function JSON(key:String, ?library:String):Dynamic
    {
        final isMod = key.startsWith('curMod/');
        final jsonPath = isMod ? key.substr(7) + '.json' : '$key.json';
        return haxe.Json.parse(getFileContent(jsonPath, library, isMod).trim());
    }

    public static function video(key:String, ?library:String):String
        return getPath('videos/$key.mp4', library);
    
    // sparrow (.xml) sheets
    public static function getSparrowAtlas(key:String, from:String = 'images', ?library:String)
    {
        var isMod = key.startsWith('curMod/');
        var graphic = getGraphic(key, from, library);
        var xmlRelativePath = isMod ? key.substr(7) : '$from/$key';
        var xmlPath = xmlRelativePath + '.xml';
        var xmlContent = getFileContent(xmlPath, library, isMod);
        return FlxAtlasFrames.fromSparrow(graphic, xmlContent);
    }
    
    // packer (.txt) sheets
    public static function getPackerAtlas(key:String, from:String = 'images', ?library:String)
    {
        var isMod = key.startsWith('curMod/');
        var graphic = getGraphic(key, from, library);
        var txtRelativePath = isMod ? key.substr(7) : '$from/$key';
        var txtPath = txtRelativePath + '.txt';
        var txtContent = getFileContent(txtPath, library, isMod);
        return FlxAtlasFrames.fromSpriteSheetPacker(graphic, txtContent);
    }

    // aseprite (.json) sheets
    public static function getAsepriteAtlas(key:String, from:String = 'images', ?library:String)
    {
        var isMod = key.startsWith('curMod/');
        var graphic = getGraphic(key, from, library);
        var jsonRelativePath = isMod ? key.substr(7) : '$from/$key';
        var jsonPath = jsonRelativePath + '.json';
        var jsonContent = getFileContent(jsonPath, library, isMod);
        return FlxAtlasFrames.fromAseprite(graphic, jsonContent);
    }

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
        var isMod = dir.startsWith('curMod/');
        if (isMod)
        {
            var modDir:String = dir.substr(7);
            var swagList:Array<String> = [];
            var seen:Map<String, Bool> = new Map<String, Bool>();
            for (k in Global.currentModFiles.keys())
            {
                var prefixLen = modDir.length + (modDir.length > 0 ? 1 : 0);
                if (StringTools.startsWith(k, modDir + (modDir == "" ? "" : "/")))
                {
                    var remaining:String = k.substr(prefixLen);
                    if (remaining == "") continue;
                    var file:String = remaining.split('/')[0];
                    if (file != '' && !seen.exists(file))
                    {
                        seen.set(file, true);
                        var isFile:Bool = !remaining.contains('/');
                        if (typeArr != null && typeArr.length > 0 && isFile)
                        {
                            var added = false;
                            for (type in typeArr)
                            {
                                if (remaining.endsWith(type))
                                {
                                    if (removeType)
                                        file = file.substr(0, file.length - type.length);
                                    swagList.push(file);
                                    added = true;
                                    break;
                                }
                            }
                            if (added) continue;
                        }
                        else
                        {
                            swagList.push(file);
                        }
                    }
                }
            }
            trace('read dir ${(swagList.length > 0) ? '$swagList' : 'EMPTY'} at mod $modDir', "DEBUG");
            return swagList;
        }
        else
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
            
            trace('read dir ${(swagList.length > 0) ? '$swagList' : 'EMPTY'} at ${getPath(dir, library)}', "DEBUG");
            return swagList;
        }
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

    public inline static function playSFX(key:String)
        return FlxG.sound.play(sound('$key', 'sounds'), MoonSettings.callSetting('SFX Volume') / 100);

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
}