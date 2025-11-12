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
import moon.game.obj.dialogue.TextTyper;
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
        // -- TEST FOR PARSING INFO -- //
        /*final schema:Map<String, Array<String>> = [
            "wave" => ["intensity", "duration"],
            "shake" => ["intensity"]
        ];
        final raw = 'I have the <wave=0.3, 1>feeling</wave> that this dialogue is <shake=0.5>very cool</shake>';
        final parsed = DialogueParser.parseTaggedText(raw, schema);
        trace('raw text: $raw', "DEBUG");
        trace('clean text: ${parsed.text}', "DEBUG");
        for (e in parsed.events)
            trace('event: ${e.name} chars= ${e.range} values= ${e.values}', "DEBUG");
        */

        // -- TEST FOR ACTUAL TEXT RENDERING -- //
        final rawDialogue = "I hate this <color=pink>fucking</color> typer\n" +
        "Ok these should <wave=3>float</wave> in a nice sine\n" +
        "<shake=0.8>ooooo i shake</shake>\n" +
        "suck my <size=48>WOAH</size> <size=16>stop swearing dude...</size>\n" +
        "I can just <font=DS-DIGI.TTF>change my font</font> whether you <font=KodeMono-Bold.ttf>like</font> <font=5by7_b.ttf>or</font> <font=phantomuff/full.ttf>not</font>.\n" +
        "I can also: <color=red><shake=1.2><wave=0.5>COMBO VERY <size=56>COOL</size> EFFECTS!</wave></shake></color>\n";

        final schema:Map<String, Array<String>> = [
            "wave" => ["intensity", "frequency", "delay"],
            "shake" => ["intensity"],
            "size" => ["size"],
            "color" => ["color"],
            "font" => ["path"]
        ];

        final parsed = DialogueParser.parseTaggedText(rawDialogue, schema);
        var typer = new TextTyper(0, 0, parsed.text, parsed.events, 45);
        typer.defaultFont = 'vcr.ttf';
        typer.defaultSize = 32;
        typer.defaultColor = 0xFFFFFFFF;
        typer.lineHeight = 48;
        add(typer);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        //if(FlxG.keys.justPressed.R) FlxG.resetState();
    }
}