package moon.menus;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

import moon.dependency.MoonSound.Metadata;
import moon.menus.obj.BarsVisualizer;
import moon.game.obj.Character;

import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.FlxGraphic;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileCircle;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;

import openfl.system.Capabilities;
import lime.app.Application;

class Title extends FlxTransitionableState
{
    var backVis:BarsVisualizer;
    var grid1:FlxBackdrop;
    var grid2:FlxBackdrop;
    var logo:MoonSprite;
    var ctlogo:MoonSprite;
    var secretGF:Character;
    var circles:FlxTypedSpriteGroup<FlxShapeCircle> = new FlxTypedSpriteGroup<FlxShapeCircle>();
    var objects:Array<FlxBasic> = []; // the objects that are hidden on start
    var displayTxt:FlxText;

    var conductor:Conductor;

    var randomText:Array<String> = [];

    var gridPos:Float = 0;
    var onTitle:Bool = false; //For tracking when the texts stuff are on screen

    var colorSH:ColorSwap = new ColorSwap();
    override public function create():Void
    {
        super.create();
		
		// otherwise it fucks up the bg bars lol
		FlxG.autoPause = false;

        setupTransition();

        conductor = new Conductor(0, 4, 4);
        
        // -- CREATE BG ELEMENTS
        backVis = new BarsVisualizer(16);
        backVis.alpha = 0.7;
        add(backVis);
        objects.push(backVis);

        var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, 0xff121224);
        bg.alpha = 0.9;
        add(bg);
        bg.shader = colorSH.shader;
        objects.push(bg);
        
        var gradient = FlxGradient.createGradientFlxSprite(
            FlxG.width, FlxG.height,
            [0xff1022c1, FlxColor.TRANSPARENT, 0xffca15ac]
        );
        gradient.alpha = 0.2;
        gradient.shader = colorSH.shader;
        add(gradient);
        objects.push(gradient);

        grid1 = new FlxBackdrop(null, X, 0, 0);
        grid1.loadGraphic(Paths.image('menus/title/bgGrid'));
        grid1.antialiasing = true;
        grid1.alpha = 0.2;
        grid1.screenCenter();
        grid1.y -= 40;
        add(grid1);
        objects.push(grid1);

        grid2 = new FlxBackdrop(null, X, 0, 0);
        grid2.loadGraphic(Paths.image('menus/title/bgGrid'));
        grid2.antialiasing = grid1.antialiasing;
        grid2.alpha = grid1.alpha;
        grid2.screenCenter();
        grid2.y = grid1.y + grid1.height;
        add(grid2);
        objects.push(grid2);

        secretGF = new Character(0,0,'gf', conductor);
        secretGF.blend = ADD;
        add(secretGF);
        secretGF.shader = colorSH.shader;
        secretGF.visible = false;
        secretGF.screenCenter();
        secretGF.x += 700;

        add(circles);

        // create clock circles
        for(i in 0...3)
        {
            final stuff = [10, 16, 24];
            var awa = new FlxShapeCircle(0, 0, stuff[i], { thickness: 4, color: FlxColor.WHITE }, FlxColor.TRANSPARENT);
            awa.antialiasing = true;
            circles.add(awa);
            awa.screenCenter();
            awa.blend = ADD;
            awa.alpha = 0.5;
            awa.y += FlxG.height;
            awa.origin.set(awa.width / 2, awa.height / 2);
        }

        logo = new MoonSprite().loadGraphic(Paths.image('menus/title/logo-white'));
        logo.screenCenter();
        add(logo);
        objects.push(logo);
        
        ctlogo = new MoonSprite().loadGraphic(Paths.image('menus/CTLogo'));
        ctlogo.screenCenter();
        ctlogo.visible = false;
        ctlogo.scale.set(0, 0);
        ctlogo.alpha = 0.2;
        add(ctlogo);

        displayTxt = new FlxText(0, 0);
        displayTxt.setFormat(Paths.font('phantomuff/difficulty.ttf'), 56, FlxColor.WHITE, CENTER);
        displayTxt.antialiasing = true;
        add(displayTxt);

        // -- SETUP THE SONG

        //GlobalMusic.song = 'menus/freakyMenu';
        //GlobalMusic.start(true);

        //TODO: make a better handler for song metadatas
        MoonUtils.playGlobalMusic('menus/freakyMenu', true);
        updateConductor(Paths.JSON('music/menus/freakyMenu-metadata'));

        updateVis();

        // -- ON CONDUCTOR'S BEAT HIT
        conductor.onBeat.add((beat) -> 
        {
            logo.scale.set(1.1, 1.1);
            gridPos += 10;

            for(i in 0...circles.members.length)
            {
                var c = circles.members[i];
                c.scale.set(c.scale.x + 0.3, c.scale.y + 0.3);
            }

            if(!onTitle)
            {
                switch(beat)
                {
                    // intro stuff
                    // biggie!!
                    case 1: setTxt('The Funkin\' Crew');
                    case 3: setTxt('presents');
                    case 4: setTxt(true);
                    case 5: setTxt('(NOT) In association\nwith');
                    case 7: 
                        ctlogo.visible = true;
                        FlxTween.tween(ctlogo, {"scale.x": 1, "scale.y": 1}, conductor.crochet / 1010, {ease: FlxEase.backOut});
                        setTxt('Chaotic Team');
                    case 8:
                        ctlogo.destroy();
                        setTxt(true);
                    case 9: setTxt(randomText[0]);
                    case 11: setTxt(randomText[1]);
                    case 12: setTxt('Friday', true);
                    case 13: setTxt('Night');
                    case 14: setTxt('Funkin');
                    case 15: setTxt('Moon Engine');
                    case 16: endIntro();
                }
            }

            if (codeActive && beat % 2 == 0) colorSH.update(0.125);
        });

        getRandomTXT();

        FlxG.sound.music.onComplete = updateVis;

        trace('Text of the day: $randomText', "DEBUG");

        prepareAD();
    }

    function updateConductor(songMeta:Dynamic)
    {
        if(songMeta != null)
        {
            conductor.changeBpmAt(0, songMeta?.bpm ?? 102, songMeta?.timeSignature[0] ?? 4, songMeta?.timeSignature[1] ?? 4);
            FlxG.sound.music.looped = songMeta?.looped ?? true;
        }
    }

    var lastVidIndex:Int = 0;
    var vidTimer:FlxTimer;
    function prepareAD()
    {
        #if !cpp return; #end
        trace('Playing a random AD video in ${Constants.TITLE_VIDEO_DELAY} seconds.', "DEBUG");
        vidTimer = new FlxTimer().start(Constants.TITLE_VIDEO_DELAY, _-> {
            // now we get a random video.
            final vidDir = Paths.readDir('videos/titleADs', [".mp4"]);
            if(lastVidIndex >= vidDir.length) lastVidIndex = 0;

            final curVid = vidDir[lastVidIndex];
            trace('AD has been chosen: $curVid', "DEBUG");

            // we must cancel inputs here.
            // I mean, not really, though I think it's nice to.
            Global.allowInputs = false;
            FlxG.sound.music.fadeOut(2.0, 0);

            FlxG.camera.fade(FlxColor.BLACK, 2.0, false, ()->
            {
                //this.visible = this.active = false;
                FlxG.sound.music.pause();
                openSubState(new VideoSubState({
                    path: Paths.mp4('videos/titleADs/$curVid'),
                    onStart: () -> {
                        FlxG.camera.fade(FlxColor.BLACK, 1, true);
                        Global.allowInputs = true;
                    },
                    onComplete: () -> {
                        prepareAD();
                        FlxG.camera.fade(FlxColor.BLACK, 1, true);
                        FlxG.sound.music.resume();
                        FlxG.sound.music.fadeIn(140, 0, MoonSettings.callSetting('Music Volume'));
                        @:privateAccess backVis.setAudioSource(cast FlxG.sound.music._channel.__audioSource);
                    },

                    infoText: "Chaotic Team is NOT affiliated with The Funkin' Crew."
                }));
            });

            lastVidIndex++;
        });
    }

    var txTwn:FlxTween;
    public function setTxt(?text:String = '', ?clear:Bool = false)
    {
        if(!onTitle)
        {
            if(clear)displayTxt.text = '';
            displayTxt.text += '\n' + text.toUpperCase();
            displayTxt.screenCenter();
            displayTxt.y -= 35;

            MoonUtils.cancelActiveTwn(txTwn);
            txTwn = FlxTween.tween(displayTxt, {y: displayTxt.y - 15}, 1.1, {ease: FlxEase.expoOut});
        }
    }

    final orbitDistance:Float = 130 * 2;
    var codeKeys:Array<Int> = [0x0001, 0x0010, 0x0001, 0x0010, 0x0100, 0x1000, 0x0100, 0x1000];
    var transitioning = false;
    override public function update(elapsed:Float):Void
    {
        if(FlxG.sound.music != null)
        conductor.time = FlxG.sound.music.time;

        //GlobalMusic.update();
        if(MoonInput.justPressed(ACCEPT))
            (!onTitle) ? endIntro() : {
                if(!transitioning)
                {
                    // gotta put it back to null, otherwise I think it'd crash the game on other states.
                    // I'm not sure, but I gotta make sure hahah
                    FlxG.sound.music.onComplete = null;
                    transitioning = true;

                    FlxG.camera.fade(FlxColor.WHITE, 0.6, true);
                    Paths.playSFX('ui/confirmMenu.ogg');
                    FlxFlicker.flicker(displayTxt, 1.3, 0.05, true, true, (flicker)->FlxG.switchState(() -> new MainMenu()));
                }
            }

        if(onTitle)
        {
            // stuff for that GF easter egg!
            if(MoonInput.justPressed(UI_LEFT)) codePress(FlxDirectionFlags.LEFT.toInt());
            if(MoonInput.justPressed(UI_RIGHT)) codePress(FlxDirectionFlags.RIGHT.toInt());
            if(MoonInput.justPressed(UI_UP)) codePress(FlxDirectionFlags.UP.toInt());
            if(MoonInput.justPressed(UI_DOWN)) codePress(FlxDirectionFlags.DOWN.toInt());

            grid1.x = FlxMath.lerp(grid1.x, gridPos, elapsed * 4);
            grid2.x = FlxMath.lerp(grid2.x, -gridPos, elapsed * 4);
            logo.scale.x = logo.scale.y = FlxMath.lerp(logo.scale.x, 1, elapsed * 10);

            // make the circles position based on time
            for(i in 0...circles.members.length)
            {
                // my brain got eated
                //pffflllrrtrtrgr
                final circle = circles.members[i];
                final angles = [
                    (Math.PI * 2) * (Date.now().getSeconds() / 60) - Math.PI/2,
                    (Math.PI * 2) * (Date.now().getMinutes() / 60) - Math.PI/2,
                    (Math.PI * 2) * ((Date.now().getHours() % 12 * 60 + Date.now().getMinutes()) / 720) - Math.PI/2
                ];

                final x = FlxG.width / 2 + Math.cos(angles[i]) * orbitDistance;
                final y = FlxG.height / 2 + Math.sin(angles[i]) * orbitDistance;
                circle.scale.set(FlxMath.lerp(circle.scale.x, 1, elapsed * 8), FlxMath.lerp(circle.scale.y, 1, elapsed * 8));
                circle.setPosition(FlxMath.lerp(circle.x, x, elapsed), FlxMath.lerp(circle.y, y, elapsed));
            }
        }

        for(obj in objects)
            obj.visible = onTitle;
    }

    var codePos:Int = 0;
    var codeActive:Bool = false;
    private function codePress(input:Int)
    {
        if(codeActive) return;
        if (input == codeKeys[codePos])
        {
            codePos++;
            if (codePos >= codeKeys.length)
            {
                // starts GF's easter egg if the key order matches.
                codeActive = true;

                if(FlxG.sound.music != null) FlxG.sound.music.stop();
                if(vidTimer != null && vidTimer.active)
                    vidTimer.cancel();

                FlxG.fullscreen = false;

                MoonUtils.playGlobalMusic('menus/girlfriendsRingtone');
                updateConductor(Paths.JSON('music/menus/girlfriendsRingtone-metadata'));
                FlxG.sound.music.onComplete = null;
                FlxG.sound.music.onComplete = updateVis;

                secretGF.visible = true;
                secretGF.alpha = 0.4;

                FlxG.camera.fade(FlxColor.WHITE, 0.6, true);
                Paths.playSFX('ui/confirmMenu.ogg');

                trace('Enjoy!', "DEBUG");
                backVis.alpha = 1;

                updateVis();

                final window = Application.current.window;
                window.borderless = false;
                window.width = Std.int(1280 / 2);
                window.height = Std.int(720 / 2);
                window.x = Std.int((Capabilities.screenResolutionX - window.width) / 2);
                window.y = Std.int((Capabilities.screenResolutionY - window.height) / 2);
                window.x -= 164;
                window.y += 18;

                FlxTween.tween(secretGF, {x: secretGF.x - 700 * 2}, conductor.crochet / 1000 * 4, {ease: FlxEase.quadInOut, type:PINGPONG});
                FlxTween.tween(window, {x: window.x + 164 * 2}, conductor.crochet / 1000 * 4, {ease: FlxEase.quadInOut, type:PINGPONG});
                FlxTween.tween(window, {y: window.y - 18 * 2}, conductor.crochet / 1000, {ease: FlxEase.quadInOut, type:PINGPONG});
            }
        }
        else
            codePos = 0;
    }

    function endIntro()
    {
        if(ctlogo != null) ctlogo.destroy();

        FlxG.camera.flash(FlxColor.WHITE, conductor.crochet / 1000 * 4);
        onTitle = true;

        MoonUtils.cancelActiveTwn(txTwn);
        displayTxt.setFormat(Paths.font('ARACNE CONDENSED REGULAR.TTF'), 64, CENTER);
        displayTxt.text = 'PRESS ENTER TO START';
        displayTxt.y = FlxG.height - displayTxt.height - 16;
        displayTxt.screenCenter(X);
        FlxTween.tween(displayTxt, {alpha: 0.2}, conductor.crochet / 1000 * 2, {ease: FlxEase.quadInOut, type: PINGPONG});
    }

    public function getRandomTXT()
    {
        var lines = [];
        for (i in MoonUtils.getArrayFromFile('data/introTexts.txt')) lines.push(i.split('--'));
        randomText = FlxG.random.getObject(lines);
    }

    function updateVis()
        @:privateAccess backVis.setAudioSource(cast FlxG.sound.music._channel.__audioSource);

    private function setupTransition()
    {
        final transitionDuration = 0.6;

        // Initialize the transition stuff!
        var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
        diamond.persist = true;
        diamond.destroyOnNoUse = false;

        FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, transitionDuration, 
            new FlxPoint(-2, -1), {asset: diamond, width: 32, height: 32},
            new FlxRect(-1, 0, FlxG.width, FlxG.height));
        FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, transitionDuration, 
            new FlxPoint(2, -1), {asset: diamond, width: 32, height: 32}, 
            new FlxRect(-1, 0, FlxG.width, FlxG.height));
            
        FlxTransitionableState.defaultTransIn.cameraMode = NEW;
        FlxTransitionableState.defaultTransOut.cameraMode = NEW;

        transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;
    }
}
