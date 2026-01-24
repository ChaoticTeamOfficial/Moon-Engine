package moon.game;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import moon.backend.gameplay.*;
import moon.menus.*;
import moon.game.obj.results.*;
import moon.backend.gameplay.Timings.RankData;
import moon.dependency.scripting.MoonScript;

class ResultsState extends FlxState
{
    public var stats:PlayerStats;

    // The order for each text
    var textOrder:Array<String> = ['totalNotes', 'maxCombo', 'sick', 'good', 'bad', 'shit', 'miss'];
    // Position for each text, representing the orders from the array above ^^
    var posOrder:Array<FlxPoint> = [
        FlxPoint.get(372, 130), FlxPoint.get(372, 198),
        FlxPoint.get(200, 255), FlxPoint.get(200, 312),
        FlxPoint.get(200, 368), FlxPoint.get(200, 426),
        FlxPoint.get(230, 478)
    ];

    public var script:MoonScript = new MoonScript();
    public function new(stats:PlayerStats)
    {
        super();
        this.stats = stats;
    }

    var accTemp(default, set):Int = 0;
    var rankData:RankData;
    var rank:String = '';
    var character:String = '';

    public var background:FlxSpriteGroup = new FlxSpriteGroup();
    override public function create()
    {
        super.create();

        //rank = 'PERFECT';
        rankData = Timings.getRank(stats.accuracy);
        rank = rankData.rank;
        character = MoonSettings.callSetting('Game Character');

        Global.registerScript("rankScript", script);

        var tryRank = rank;

        // Look for the rank in thresholds
        for (i in 0...Timings.thresholds.length)
        {
            if (Timings.thresholds[i].rank == rank)
            {
                var prev = i;
                while (prev >= 0)
                {
                    final fallback = Timings.thresholds[prev].rank;
                    if (Paths.exists('images/ingame/results/$character/$fallback'))
                    {
                        tryRank = fallback;
                        break;
                    }
                    prev--;
                }
                break;
            }
        }
        script.load('images/ingame/results/$character/$tryRank/script.hx');
        Global.scriptSet('results', this);
        
        var back = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECD5C, 0xFFFF9D47]);
        add(back);
        back.alpha = 0.0001;
        FlxTween.tween(back, {alpha: 1}, 0.7);

        add(background);

        var soundBooth = new FlxAnimate();
        soundBooth.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/UI/soundBooth"));
        soundBooth.anim.addBySymbol('drop', 'sound system', 24, false);
        soundBooth.alpha = 0.0001;
        soundBooth.x -= 16;
        soundBooth.y -= 208;
        soundBooth.antialiasing = true;
        add(soundBooth);

        var judges = new FlxAnimate();
        judges.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/UI/judgesDisplay"));
        judges.anim.addBySymbol('show', 'categories', 24, false);
        judges.alpha = 0.0001;
        judges.y += 120;
        judges.x -= 158;
        judges.antialiasing = true;
        add(judges);

        var bb = new MoonSprite().loadGraphic(Paths.image('ingame/results/UI/bb'));
        bb.antialiasing = true;
        add(bb);

        var results = new FlxAnimate();
        results.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/UI/resultsTxt"));
        results.anim.addBySymbol("hi", "results", 24, false);
        results.alpha = 0.0001;
        results.x -= 180;
        results.antialiasing = true;
        add(results);

        var score = new MoonSprite().loadGraphic(Paths.image('ingame/results/UI/score'));
        add(score);
        score.screenCenter(Y);
        score.x += 28;
        score.y += 216;
        score.antialiasing = true;

        var scoreNum = new ScoreNumbers(74, FlxG.height);
        add(scoreNum);

        var scoreBump = new MoonSprite(score.x, score.y);
        scoreBump.loadGraphicFromSprite(score);
        add(scoreBump);
        scoreBump.visible = false;
        scoreBump.blend = ADD;

        score.scale.set(1.6, 1.6);
        score.alpha = 0.00001;

        Global.scriptCall('onPostCreate');

        new FlxTimer().start(0.4, (_) ->
        {
            results.alpha = 1;
            results.anim.play('hi', true);

            soundBooth.alpha = 1;
            soundBooth.anim.play('drop');

            new FlxTimer().start(0.4, (_) ->
            {
                judges.anim.play('show');
                judges.alpha = 1;

                for (i in 0...textOrder.length)
                {
                    new FlxTimer().start(0.6 + (0.14 * i), (_) -> {
                        final point = posOrder[i];
                        final text = textOrder[i];

                        var t = new FlxText(point.x, point.y+16);
                        t.setFormat(Paths.font('letterstuff/Tardling-Regular.otf'), 48, (i > 1) ? Timings.getParameters(text)[4] : FlxColor.WHITE);
                        t.text = (i == 0) ? '${stats.totalNotes}' : (i == 1) ? '${stats.highestCombo}' : '${stats.judgementsCounter.get(text)}';
                        //t.textField.antiAliasType = ADVANCED;
                        //t.textField.sharpness = 400;
                        t.antialiasing = true;
                        t.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
                        add(t);
                        t.alpha = 0.4;

                        t.origin.set(t.width / 2, t.height / 2);
                        FlxTween.tween(t, {y: t.y - 12, alpha: 1}, 0.7, {ease: FlxEase.expoOut});
                    });
                }

                var clear = new FlxText(FlxG.width - 128);
                clear.setFormat(Paths.font('phantomuff/difficulty.ttf'), 128, FlxColor.WHITE);
                clear.screenCenter(Y);
                clear.setBorderStyle(SHADOW, FlxColor.BLACK, 12);
                clear.antialiasing = true;
                add(clear);

                //score.playAnim('boop', true);
                //score.visible = true;

                FlxTween.tween(scoreNum, {y: FlxG.height - 118}, 0.5, {ease:FlxEase.expoOut, onStart: _ -> scoreNum.setScore(stats.score), startDelay: 0.4});

                Paths.playSFX('results/scoreReveal${(rank == "LOSS") ? "-loss" : ""}.wav');
                FlxTween.tween(score, {"scale.x": 1, "scale.y": 1, alpha: 1}, 1, {ease: FlxEase.expoIn, onComplete: _ -> {
                    scoreBump.visible = true;
                    FlxTween.tween(scoreBump, {"scale.x": 1.6, "scale.y": 1.6, alpha: 0}, 2.2, {ease: FlxEase.expoOut, onComplete: _ -> scoreBump.kill()});
                }});
                final pos = 128;
                new FlxTimer().start(1, (_) -> {
                    FlxTween.tween(this, {accTemp: Std.int(stats.accuracy)}, 2, {ease: FlxEase.quadOut, onUpdate: (_) -> {
                        clear.text = '$accTemp%';
                        clear.x = FlxG.width - clear.width - pos;
                    },
                    onComplete: (_)->{
                        clear.text = '${Std.int(stats.accuracy)}%';
                        clear.x = FlxG.width - clear.width - pos;

                        FlxTween.color(clear, 1, rankData.color, FlxColor.WHITE);
                        Paths.playSFX('results/reveal$rank.ogg');

                        if(rank != 'LOSS')
                        {
                            clear.scale.set(1.3, 1.3);
                            FlxTween.tween(clear.scale, {x: 1, y: 1}, 1.3, {ease: FlxEase.elasticOut});
                            FlxTween.tween(clear, {y: FlxG.height - clear.height - 16}, 1.6, {ease: FlxEase.expoInOut, startDelay: 0.6});
                        }
                        else
                        {
                            FlxTween.tween(clear, {y: clear.y + 300, "scale.y": 0.6}, 2, {ease: FlxEase.bounceOut, onComplete: (_)->
                            FlxTween.tween(clear, {alpha: 0}, 0.6, {startDelay: 0.2})});
                        }

                        Global.scriptCall('onIntroEnd');
                    }});
                });
            });
        });
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        Global.scriptCall('onUpdate', [elapsed]);

        if(MoonInput.justPressed(ACCEPT) || MoonInput.justPressed(BACK))
        {
            if(FlxG.sound.music != null)
            {
                FlxG.sound.music.onComplete = null;
                FlxTween.tween(FlxG.sound.music, {pitch: 4}, 0.2, {onComplete: _->{
                    FlxTween.tween(FlxG.sound.music, {pitch: 0, volume: 0}, 0.4, {onComplete: _->FlxG.sound.music.kill()});
                }});
                openSubState(new StickerSubState(new MainMenu()));
            }
        }
    }

    function set_accTemp(a:Int):Int
    {
        if(accTemp != a)
            Paths.playSFX('ui/scrollMenu.ogg');

        accTemp = a;

        return accTemp;
    }
}