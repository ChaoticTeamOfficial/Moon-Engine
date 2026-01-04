package moon.backend.misc;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import haxe.Json;
import openfl.utils.Assets;

/**
 * Code from Syobon Action Advance lol!
 * I'll be mostly using this for interface stuff on the editors.
 * TODO: documment this class properly 
 */
class Tilemap
{
    public static var atlasGraphics:Map<String, FlxGraphic> = [];
    public static var atlasFrameMap:Map<String, FlxAtlasFrames> = [];

    public static function addAtlas(id:String, atlasName:String, folder:String = 'images'):Void
    {
        if (atlasFrameMap.exists(id))
            trace('Atlas $id already exists, overriding.');

        final imgPath = '$folder/$atlasName.png';
        final jsonPath = '$folder/$atlasName';

        // Verify assets exist
        // my english is so awesome sometimes.
        if (!Paths.exists(imgPath))
        {
            trace('Image file not found at $imgPath', "ERROR");
            return;
        }

        final graphic:FlxGraphic = Paths.image(atlasName, folder);
        if (graphic == null)
        {
            trace('Failed to load graphic from $imgPath', "ERROR");
            return;
        }

        atlasGraphics.set(atlasName, graphic);
        var frames:FlxAtlasFrames = new FlxAtlasFrames(graphic);
        try
        {
            final parsedData = Paths.JSON(jsonPath);
            final jsonArr:Array<Dynamic> = parsedData.frames;
            if (jsonArr == null)
            {
                trace('JSON at $jsonPath has no "frames" array', "ERROR");
                return;
            }

            for (frameData in jsonArr)
            {
                if (!Reflect.hasField(frameData, 'name') || !Reflect.hasField(frameData, 'pos') || !Reflect.hasField(frameData, 'size'))
                {
                    trace('Invalid frame data, missing name/pos/size: $frameData', "ERROR");
                    continue;
                }
                final rect = new FlxRect(frameData.pos[0], frameData.pos[1], frameData.size[0], frameData.size[1]);
                final size = FlxPoint.get(frameData.size[0], frameData.size[1]);
                final offset = FlxPoint.get();
                frames.addAtlasFrame(rect, size, offset, frameData.name);
            }
            trace('Atlas "$atlasName" loaded with ${jsonArr.length} frames');
        }
        catch (e:Dynamic)
        {
            trace('Error parsing JSON at $jsonPath: $e', "ERROR");
            return;
        }

        atlasFrameMap.set(id, frames);
    }

    public static function getFrame(name:String, id:String):FlxFrame
    {
        final frames:FlxAtlasFrames = atlasFrameMap.get(id);
        if (frames == null)
        {
            trace('Atlas "$id" not found! Is it loaded?');
            return null;
        }

        final frame:FlxFrame = frames.getByName(name);
        if (frame == null) trace('Frame "$name" not found in atlas "$id".');
        return frame;
    }

    public static function getAtlasFrames(id:String):FlxAtlasFrames
    {
        var frames:FlxAtlasFrames = atlasFrameMap.get(id);
        if (frames == null) trace('Atlas "$id" not found.');
        return frames;
    }
}