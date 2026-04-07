package moon.backend.data;

import moon.dependency.scripting.MoonEvent;
import haxe.Json;
#if sys
import moonchart.formats.fnf.legacy.*;
import moonchart.formats.fnf.*;
import moonchart.formats.*;
#end
import haxe.io.Path;
using StringTools;

/**
 * Structure for the Chart's notes.
 */
typedef NoteStruct =
{
    var time:Float;
    var data:Int;
    var lane:String;
    var type:String;
    var duration:Float;
    var ?values:Dynamic;
};

/**
 * Structure for the Chart's events.
 */
typedef EventStruct = 
{
    var tag:String;
    var values:Dynamic;
    var time:Float;
    var ?lane:Int;
};

/**
 * Struct for a bookmark.
 * Only visible in the chart editor.
 */
typedef BookmarkStruct = 
{
    var text:String;
    var time:Float;
};

/**
 * Structure for the Chart's metadata.
 */
typedef MetadataStruct =
{
    // Game data
    var bpm:Float;
    var timeSignature:Array<Int>;
    var scrollSpd:Float;
    var stage:String;
    var lanes:Array<String>;
    var players:Array<String>;
    var spectators:Array<String>;
    var opponents:Array<String>;
    var noteskin:String;

    // Other data
    var displayName:String;
    var album:String;
    var artist:String;
    var charter:String;
    var preview:Array<Float>;
    
    // MISC
    var generatedBy:String;
    var version:String;
};

/**
 * Structure for the entire Chart.
 */
typedef ChartStruct =
{
    var meta:MetadataStruct;
    var notes:Array<NoteStruct>;
    var ?bookmarks:Array<BookmarkStruct>;
};

/**
 * Class used for handling ingame charts.
 **/
class Chart
{
    /**
     * All the chart formats supported for converting.
     */
    public static final SUPPORTED_FORMATS:Array<String> = 
    [
        //TODO: add other formats in here.
        'legacy',
        'psych',
        'codename',
        'v-slice',
        'osu',
        'kade',
        'fps-plus'
    ];

    /**
     * All of the chart content, except for the events.
     */
    public var content:ChartStruct;

    /**
     * All of the chart's events.
     */
    public var events:Array<EventStruct>;

    public var song:String;
    public var difficulty:String;
    public var mix:String;

    /**
     * Loads a chart from a path.
     * @param song        The song's name. (e.g. satin panties)
     * @param difficulty  The song's difficulty. (e.g. hard)
     * @param mix         The song's mix. (e.g. bf)
     */
    public function new(song:String, difficulty:String = 'hard', mix:String = 'bf')
    {
        final modifier = (difficulty == 'erect' || difficulty == 'nightmare') ? '-erect' : '';
        events = (Paths.exists('songs/$song/$mix/events$modifier.json')) ? Paths.JSON('songs/$song/$mix/events$modifier') : [];
        content = Paths.JSON('songs/$song/$mix/chart-$difficulty');

        this.song = song;
        this.difficulty = difficulty;
        this.mix = mix;

        content.notes.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
        events.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
    }

    /**
     * Calculates a clean 0-20 difficulty rating based on NPS, chords, and jacks.
     * @param notes The array containing all notes.
     * @param bpm The BPM value.
     */
    public static function calculateDifficultyRating(notes:Array<NoteStruct>, bpm:Float):Int
    {
        if (notes == null || notes.length == 0) return 0;

        var p1Notes:Array<NoteStruct> = [];
        for (note in notes)
            if (note.lane == "p1") p1Notes.push(note);

        if (p1Notes.length == 0) return 0;

        p1Notes.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);

        final songDuration:Float = p1Notes[p1Notes.length - 1].time - p1Notes[0].time;
        if (songDuration <= 0) return 0;

        // first step is to do some sliding 1-second window NPS analysis
        final WINDOW_MS:Float = 1000.0;
        var npsValues:Array<Float> = [];
        var windowStart:Int = 0;

        for (i in 0...p1Notes.length)
        {
            while (p1Notes[i].time - p1Notes[windowStart].time > WINDOW_MS)
                windowStart++;

            // normalize to per-second so units stay consistent
            npsValues.push((i - windowStart + 1) * (1000.0 / WINDOW_MS));
        }

        npsValues.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);

        final peakNPS:Float = npsValues[npsValues.length - 1];
        final p90NPS:Float  = npsValues[Std.int(npsValues.length * 0.90)];
        var avgNPS:Float = 0.0;
        for (v in npsValues) avgNPS += v;
        avgNPS /= npsValues.length;

        // peak and sustained matter more than average
        final blendedNPS:Float = (peakNPS * 0.45) + (p90NPS * 0.45) + (avgNPS * 0.10);

        // now we go for the 2nd step, check for chord bonus (multiple notes at nearly the same time)
        var chordNotes:Int = 0;
        for (i in 1...p1Notes.length)
        {
            if (Math.abs(p1Notes[i].time - p1Notes[i - 1].time) < 15.0)
                chordNotes++;
        }

        // up to 25% bonus for chord-heavy charts
        final chordFactor:Float = 1.0 + (chordNotes / p1Notes.length) * 0.25;

        // now for the 3rd step: jack factor! (same column hit twice quickly if u didnt know)
        var jackNotes:Int = 0;
        for (i in 1...p1Notes.length)
        {
            final gap:Float = p1Notes[i].time - p1Notes[i - 1].time;
            if (p1Notes[i].data == p1Notes[i - 1].data && gap > 15.0 && gap < 250.0)
                jackNotes++;
        }

        // up to +15% bonus for jack-heavy charts
        final jackFactor:Float = 1.0 + (jackNotes / p1Notes.length) * 0.15;

        // now the last step! map to 0-20 via tanh curve

        // calibration with SCALE = 20:
        // ~3 NPS blend -> ~6 (easy-ish)
        // ~6 NPS blend -> ~11 (moderate)
        // ~10 NPS blend -> ~15 (hard)
        // ~18 NPS blend -> ~19 (extreme)

        // power of 1.8 squashes easy songs down while leaving hard songs near the top.
        // that should nerf this a lil
        // bc for example, bopeebo was getting 4 on diff rating LOL
        // o yea also have bpm taking into account
        final bpmFactor:Float = 1.0 + Math.max(0.0, (bpm - 120.0) / 120.0) * 0.20;
        final adjustedNPS:Float = blendedNPS * chordFactor * jackFactor * bpmFactor;
        final normalized:Float = Math.pow(adjustedNPS / 16.0, 2.0);
        final e2x:Float = Math.exp(2.0 * normalized);

        final rating:Float = 20.0 * (e2x - 1.0) / (e2x + 1.0);

        return Std.int(Math.min(20, Math.max(0, Math.round(rating))));
    }

    /**
     * Converts a chart type to Moon Engine's chart type.
     * @param type The chart type you're converting from
     * @param path The chart's path
     * @param difficulty The chart's difficulty
     */
    public static function convert(type:String, path:String, difficulty:String, ?metaPath:String):ConvertResult
    {
        // gotta do that since moonchart uses filesystem.

        #if sys
        // So first, we'll get the chart format and convert 'em to
        // vslice, because vslice will be our main 'base' for converting.
        // (thanks moonchart for existing its BASED AF)

        //trace('choosing format', "DEBUG");
        final chart = switch (type)
        {
            // This switch is a mess btw!!!
            case 'psych': new FNFVSlice().fromFormat(new FNFPsych().fromFile(path, null, difficulty));
            case 'codename': new FNFVSlice().fromFormat(new FNFCodename().fromFile(path, metaPath, difficulty));
            case 'legacy': new FNFVSlice().fromFormat(new FNFLegacy().fromFile(path, null, difficulty));
            case 'osu': new FNFVSlice().fromFormat(new OsuMania().fromFile(path, null, difficulty));
            case 'fps-plus': new FNFVSlice().fromFormat(new FNFFpsPlus().fromFile(path, null, difficulty));
            case 'kade': new FNFVSlice().fromFormat(new FNFKade().fromFile(path, null, difficulty));
            default: new FNFVSlice().fromFile(path, metaPath, difficulty);
        };

        //trace('done! reading content', "DEBUG");

        final data = Json.parse(chart.stringify().data);
        final metadata = Json.parse(chart.stringify().meta);

        //trace('content read! now, converting notes', "DEBUG");
        // Now we create a variable for the converted chart.
        var convertedChart:ChartStruct = {notes: [], meta: null};
        var convertedEvents:Array<EventStruct> = [];

        // Now we convert the notes and add them to the chart.
        if (Reflect.hasField(data.notes, difficulty))
        {
            final noteArray:Array<Dynamic> = Reflect.field(data.notes, difficulty);
            
            for (note in noteArray)
            {
                final note:NoteStruct =
                {
                    time: note.t,
                    data: (note.d > 3) ? Std.int(note.d - 4) : note.d,
                    lane:  (note.d > 3) ? 'opponent' : 'p1',
                    type: (note.k == '') ? null : note.k,
                    duration: note.l,
                    values: {}
                };
                convertedChart.notes.push(note);
            }
        }

        convertedChart.notes.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);

        //trace('converting events', "DEBUG");

        // time to convert some basic events (such as camera and stuff)
        final events:Array<Dynamic> = data.events;
        for(event in events)
        {
            var convertedEvent:EventStruct = switch(event.e)
            {
                case 'FocusCamera': {
                    tag: 'Move Camera',
                    values: {
                        character: (event?.v?.char == 1 ?? 0) ? 'opponent' : (event?.v?.char == 2 ?? 0) ? 'spectator' : (event?.v?.char == -1 ?? 0) ? 'none' : 'player', 
                        duration: (event.v.ease == 'CLASSIC') ? 26 : event?.v?.duration ?? 26,
                        ease: (event.v.ease == 'CLASSIC') ? 'expoOut' : '${event?.v?.ease ?? "expo"}${event?.v?.easeDir ?? ""}',
                        x: Std.parseFloat(event?.v?.x) ?? 0,
                        y: Std.parseFloat(event?.v?.y) ?? 0,
                    },
                    lane: 0, time: event.t
                };

                case 'ZoomCamera': {
                    tag: 'Set Zoom',
                    values: {
                        zoom: Std.parseFloat(event.v.zoom),
                        duration: event?.v?.duration ?? 8,
                        ease: '${event?.v?.ease ?? "expo"}${event?.v?.easeDir ?? ""}' ?? 'circOut',
                        mode: event?.v?.mode ?? 'absolute',
                    },
                    lane:1, time: event.t                    
                };

                case 'SetCameraBop': {
                    tag: 'Customized Pulse Timing',
                    values: event.v,
                    lane:2, time: event.t                    
                };

                case 'PlayAnimation': {
                    tag: 'Play Character Animation',
                    time: event.t,
                    lane: 3,
                    values: {
                        anim:event.v.anim,
                        target: (event.v.target == 'dad') ? 'opponent' : (event.v.target == 'boyfriend') ? 'player' : 'spectator',
                        force: event?.v?.force ?? true,
                        forceOverride: true,
                        reversed: false,
                        frame: 0
                    }
                };

                case 'ScrollSpeed': {
                    tag: 'Set Lane Scroll Speed',
                    time: event.t,
                    lane: 1,
                    values: {
                        duration: event.v.duration,
                        strumline: event.v.strumline,
                        ease: '${event?.v?.ease ?? "expo"}${event?.v?.easeDir ?? ""}' ?? 'circOut',
                        scroll: event.v.scroll,
                        absolute: event.v.absolute
                    }
                };
                
                default: {
                    tag: event.e, values: event.v,
                    time: event.t, lane: FlxG.random.int(0, 7)
                };
            }

            convertedEvents.push(convertedEvent);
        }

        final tChanges = metadata.timeChanges;
        
        // Convert time signature/bpm changes
        for (i in 0...tChanges.length)
        {
            // because the first time change is applied to the metadata instead
            if(i != 0)
            {
                final event:EventStruct = {
                    tag: 'Change Playback Settings',
                    values: {
                        bpm: tChanges[i].bpm,
                        timeSignature: [tChanges[i]?.n ?? 4, tChanges[i]?.d ?? 4]
                    },
                    time: tChanges[i].t
                };

                convertedEvents.push(event);
            }
        }

        convertedEvents.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);

        //trace('[CHART] converting metadata', "DEBUG");

        // Now let's convert the metadata as well.
        convertedChart.meta =
        {
            bpm: metadata.timeChanges[0].bpm,
            timeSignature: [metadata.timeChanges[0]?.n ?? 4, metadata.timeChanges[0]?.d ?? 4],
            scrollSpd: Reflect.field(data.scrollSpeed, difficulty),
            stage: metadata.playData.stage,
            lanes: ["opponent", "p1"],
            players: [metadata.playData.characters.player],
            spectators: [metadata.playData.characters.girlfriend],
            opponents: [metadata.playData.characters.opponent],
            noteskin: 'v-slice',

            displayName: metadata.songName,
            album: metadata.playData.album,
            artist: metadata.artist,
            charter: metadata.charter,
            preview: [metadata.playData.previewStart, metadata.playData.previewEnd],

            generatedBy: metadata.generatedBy,
            version: metadata.version
        };

        return {
            chartJson: Json.stringify(convertedChart, "\t"),
            eventsJson: Json.stringify(convertedEvents, "\t"),
        };
        #else
        throw 'Chart conversion is currently only available for Desktop.';
        return null;
        #end
    }
}

/**
 * Structure for the result of a conversion.
 */
typedef ConvertResult =
{
    var chartJson:String;
    var eventsJson:String;
};