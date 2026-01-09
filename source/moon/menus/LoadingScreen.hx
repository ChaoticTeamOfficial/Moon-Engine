package moon.menus;

import flixel.ui.FlxBar;
import moon.menus.obj.*;
import moon.game.*;
import moon.game.obj.*;
import moon.game.obj.notes.*;

// Heavily inspired at Doido Engine's loading screen!
class LoadingScreen extends FlxTransitionableState
{
    var mutex = new sys.thread.Mutex();
    var preloadGrp = new FlxGroup();

    private var loadingBar:FlxBar;
    private var loadText:FlxText;
    private var loadDisplay:MoonSprite;

    var loadComplete:Bool = false;
    var loadProgress:Int = 0;
    override public function create():Void
    {
        super.create();
        add(preloadGrp);

        var cover = new MoonSprite().makeGraphic(FlxG.width + 64, FlxG.height + 64, FlxColor.BLACK);
        add(cover);

        var scrollingArts = new ScrollingArts("images/menus/loading/arts");
        add(scrollingArts);

        loadingBar = new FlxBar(0, 0, LEFT_TO_RIGHT, 560, 10).createFilledBar(FlxColor.fromRGB(13, 13, 16), FlxColor.WHITE);
        loadingBar.y = (FlxG.height - loadingBar.height) - 50;
        loadingBar.screenCenter(X);
        loadingBar.x += 70;
        add(loadingBar);

        loadText = new FlxText();
        loadText.setFormat(Paths.font('vcr.ttf'), 22, RIGHT);
        loadText.text = '...';
        loadText.antialiasing = false;
        add(loadText);
        loadText.setPosition(loadingBar.x, loadingBar.y - loadText.height - 10);

        loadDisplay = new MoonSprite().loadGraphic(Paths.image('menus/loading/loadingCorner'));
        loadDisplay.screenCenter(X);
        loadDisplay.antialiasing = true;
        add(loadDisplay);
        loadDisplay.y = FlxG.height - loadDisplay.height;

        // We begin preloading here!!!
        new FlxTimer().start(0.4, function(_)
        {
            sys.thread.Thread.create(() ->
            {
                mutex.acquire();

                loadText.text = 'Preloading song...';

                final d = PlayState.songData;
                var chart = new Chart(d.song, d.difficulty, d.mix);
                var conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);

                loadProgress = 15;
                var playback = new Song(
                    d.song,
                    d.mix,
                    (d.difficulty == 'erect' || d.difficulty == 'nightmare'),
                    conductor
                );
                playback.state = STOP;
                loadProgress = 30;

                loadText.text = 'Preloading Graphics...';
                preload(new HealthBar(chart.content.meta.opponents[0], chart.content.meta.players[0]));
                loadProgress = 40;

                final thing = ['opponent', 'p1'];

                //TODO: Skins lol
                for(i in 0...thing.length)
                    preload(new Strumline(0, 68, chart.content?.meta?.noteskin ?? 'v-slice', false, thing[i], conductor));
                loadProgress = 50;

                //TODO ONCE IMPLEMENTED: LOAD JUDGEMENTS N COMBO!
                var stage = new Stage(chart.content.meta.stage, conductor);
                
                final chartMeta = chart.content.meta;
                for (opp in chartMeta.opponents) stage.addCharTo(opp, stage.opponents);
                for (plyr in chartMeta.players) stage.addCharTo(plyr, stage.players);
                for (spct in chartMeta.spectators) stage.addCharTo(spct, stage.spectators);
                preload(stage);
                loadProgress = 70;

                // This is the part where it'll preload song events (like change stage and change character)
                // Once I have them implemented ofc lol
                // also, TODO, have a "preload" function for song scripts.
                loadText.text = 'Preloading events and such...';

                Paths.skipNextCleanup = true;
                Global.clearScriptList();

                loadText.text = 'Done! Press ACCEPT to continue.';
                loadProgress = 102;
                loadComplete = true;

                FlxTween.tween(loadText, {alpha: 0.5}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
                mutex.release();
            });
        });
    }

    var tracker:Float = 0;
    var trackerB:Bool = false;
    var transitioning = false;
    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        loadingBar.value = FlxMath.lerp(loadingBar.value, loadProgress, elapsed * 6);

        tracker += elapsed;
        if(tracker >= 0.6)
        {
            tracker = 0;
            trackerB = !trackerB;
            loadDisplay.y += trackerB ? 5 : -5; 
        }

        if(loadComplete && MoonInput.justPressed(ACCEPT) && !transitioning)
        {
            transitioning = true;
            Paths.playSFX('ui/confirmMenu.ogg');
            if(FlxG.sound.music != null) FlxG.sound.music.stop();

            FlxFlicker.flicker(loadText, 1.4, 0.05, true, true, (flicker)->FlxG.switchState(() -> new PlayState()));
        }
    }

    function preload(item:FlxBasic)
    {
        preloadGrp.add(item);
        preloadGrp.remove(item);
    }
}