package;

import flixel.math.FlxMath;
import moon.game.obj.PlayField;
import flixel.addons.display.waveform.FlxWaveform;
import moon.game.obj.judgements.ComboNumbers;
import flixel.FlxG;
import flixel.FlxState;
import sys.io.File;
import haxe.io.Path;
import haxe.zip.Writer;
import haxe.zip.Entry;
import haxe.io.Bytes;
import haxe.ds.List;
import sys.Http;

import openfl.net.URLRequest;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import moon.global_obj.PixelIcon;
import moon.backend.data.Dialogue.DialogueParser;

import moon.backend.gameplay.*;
import moon.toolkit.ui.*;
import moon.toolkit.*;

using StringTools;
class TestState extends FlxState
{
    var waveform:FlxWaveform;
    var playfield:PlayField;
    override public function create():Void
    {
        super.create();
        FlxG.mouse.useSystemCursor = true;
        //FlxG.switchState(() -> new moon.game.ResultsState(new PlayerStats('p1')));

        // addons file test
        /*var files = new Map<String, Bytes>();
        files.set("nya/text.txt", Bytes.ofString("Hello world! I am here to spread an important message.\nI got created by code.\nYes.\nThat's right.\n\n\nIsn't that cool?"));
        files.set("data.json", Bytes.ofString('{"hi": true}'));
        MZip.create(files, "test.mzip");*/

        //var fileList = MZip.listFiles("test.mzip");
        //trace('Files: $fileList', "DEBUG");

        //var fileContent = MZip.extract(Paths.getPath("test.mzip", null), "nya/text.txt");
        //trace('Content of text: ${fileContent.toString()}', "DEBUG");

        //var request = new URLRequest('(link)');
        //var loader = new URLLoader();
        //loader.dataFormat = URLLoaderDataFormat.BINARY;

        //files download test
        /*loader.addEventListener(Event.COMPLETE, function(e:Event)
        {
            File.saveBytes('assets/video foda do luis.mp4', cast(loader.data, Bytes));
            trace('gg', "DEBUG");
        });

        loader.addEventListener(ProgressEvent.PROGRESS, function(e:ProgressEvent)
        {
            final mbLoaded = e.bytesLoaded / 1048576;
            final mbTotal = e.bytesTotal / 1048576;
            final percent = (e.bytesLoaded / e.bytesTotal) * 100;

            var display = 'Progress: $formatFloat(percent)% ($formatFloat(mbLoaded) MB / $formatFloat(mbTotal) MB)';
            trace(display);
        });

        loader.load(request);*/

        //reading a json file
        /*var loader = new URLLoader();
        loader.dataFormat = URLLoaderDataFormat.TEXT;

        loader.addEventListener(Event.COMPLETE, function(e:Event)
        {
            trace('gg', "DEBUG");
            var raw:String = cast(e.target, URLLoader).data;
            try 
            {
                var list:Array<String> = haxe.Json.parse(raw).teste;
                for (file in list)
                    trace(file, "DEBUG");
            }
            catch (e) {trace(e, "ERROR");}
        });
        loader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent)
        {
            trace('a: ${e.text}', "ERROR");
        });

        loader.load(new URLRequest('link'));*/

        //var displayIcon = new PixelIcon('dummy');
        //add(displayIcon);
        //displayIcon.playAnim('select', true);

        //trace();

        //testMod();
        testParser();
    }

    //helper 'w'
    /*function formatFloat(val:Float, decimals:Int = 2):String
    {
        var factor = Math.pow(10, decimals);
        return (Math.round(val * factor) / factor) + "";
    }*/

    function testMod()
    {
        /*MZip.loadMod('mods/test.mzip');
        trace(MZip.listFiles('mods/test.mzip'));
        var image = new MoonSprite().loadGraphic(Paths.image('curMod/oie'));
        add(image);*/

        //var popup = new Popup(500, 164);
        //popup.screenCenter();
        //add(popup);
    }

    function testParser() {
        // this could be awesome for making custom events!
        // oh my god the potential...
        final schema:Map<String, Array<String>> = [
            "wave" => ["intensity", "duration"],
            "shake" => ["intensity"]
        ];
        final raw = 'I have the <wave=0.3, 1>feeling</wave> that this dialogue is <shake=0.5>very cool</shake>';
        final parsed = DialogueParser.parseTaggedText(raw, schema);

        trace('raw text: $raw', "DEBUG");
        trace('clean text: ${parsed.text}', "DEBUG");
        for (e in parsed.events)
            trace('event: ${e.name} chars= ${e.range} values= ${e.values}', "DEBUG");

    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        //if(FlxG.keys.justPressed.R) FlxG.resetState();
    }
}