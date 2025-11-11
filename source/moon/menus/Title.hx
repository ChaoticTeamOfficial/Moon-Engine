package moon.menus;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;
import flixel.util.FlxTimer;
import moon.dependency.MoonSound.Metadata;
import moon.menus.obj.BarsVisualizer;
import flixel.math.FlxMath;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxGradient;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxState;
import moon.global_obj.Alphabet;

class Title extends FlxState
{
    var grid1:FlxBackdrop;
    var grid2:FlxBackdrop;
    var logo:MoonSprite;
    var ctlogo:MoonSprite;
    var circles:FlxTypedSpriteGroup<FlxShapeCircle> = new FlxTypedSpriteGroup<FlxShapeCircle>();
    var objects:Array<FlxBasic> = []; // the objects that are hidden on start
    var displayTxt:FlxText;

    var conductor:Conductor;

    var randomText:Array<String> = [];

    var gridPos:Float = 0;
    var onTitle:Bool = false; //For tracking when the alphabet isnt on screensies
    override public function create():Void
    {
        super.create();
        
        // -- CREATE BG ELEMENTS
        var backVis = new BarsVisualizer(16);
        backVis.alpha = 0.2;
        add(backVis);
        objects.push(backVis);

        var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, 0xff121224);
        bg.alpha = 0.9;
        add(bg);
        objects.push(bg);
        
        var gradient = FlxGradient.createGradientFlxSprite(
            FlxG.width, FlxG.height,
            [0xff1022c1, FlxColor.TRANSPARENT, 0xffca15ac]
        );
        gradient.alpha = 0.2;
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
        MoonUtils.playGlobalMusic('menus/freakierMenu', true);
        var songMeta = Paths.JSON('music/menus/freakierMenu-metadata');

        if(songMeta != null)
        {
            conductor = new Conductor(songMeta.bpm ?? 0, songMeta.timeSignature[0] ?? 4, songMeta.timeSignature[1] ?? 4);
            FlxG.sound.music.looped = songMeta.looped;
        }
        
        // (visualizer audio source stuff)
        @:privateAccess
        backVis.setAudioSource(cast FlxG.sound.music._channel.__audioSource);

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
        });

        getRandomTXT();
        trace('Text of the day: $randomText', "DEBUG");
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
    override public function update(elapsed:Float):Void
    {
        if(FlxG.sound.music != null)
        conductor.time = FlxG.sound.music.time;

        //GlobalMusic.update();
        if(MoonInput.justPressed(ACCEPT))
        {
            (!onTitle) ? endIntro() : {
                //nothing cause we dont have a menu yet :[
            }
        }

        if(onTitle)
        {
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
        var allTxts = MoonUtils.getArrayFromFile('data/introTexts.txt');
        var lines = [];
        for (i in allTxts) lines.push(i.split('--'));
        randomText = FlxG.random.getObject(lines);
    }
}
