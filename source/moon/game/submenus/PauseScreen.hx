package moon.game.submenus;

import moon.menus.*;
import moon.menus.obj.freeplay.*;
import moon.backend.gameplay.*;
import moon.game.obj.*;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BlendMode;

/**
 * A group for the best score display elements.
 * ... that lowkey sounds funny LOL
 */
class BestScoreGroup extends FlxSpriteGroup
{
    public var bestBG:MoonSprite;
    public var playerIcon:PixelIcon;
    public var bestScore:FlxText;
    public var bestRank:FreeplayRank;

    public function new(player:String, bgWidth:Int, ?data:SongData.SongScoreData)
    {
        super();

        if(data == null)
            data = {
                score: 0,
                misses: 0,
                accuracy: 0
            };

        bestBG = new MoonSprite(0, 0).makeGraphic(bgWidth, 64, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRoundRect(bestBG, 0, 0, bestBG.width, bestBG.height, 16, 16, FlxColor.BLACK);
        bestBG.antialiasing = true;
        bestBG.active = false;
        bestBG.alpha = 0.5;
        add(bestBG);

        playerIcon = new PixelIcon(player);
        playerIcon.scale.set(1, 1);
        playerIcon.updateHitbox();
        playerIcon.x = 16;
        playerIcon.y = bestBG.height / 2 - playerIcon.height / 2;
        add(playerIcon);

        bestScore = new FlxText(0, 0);
        bestScore.setFormat(Paths.font('phantomuff/full.ttf'), 16, LEFT);
        bestScore.text = 'Best Score: ${MoonUtils.formatNumber(data.score)}\nBest Accuracy: ${data.accuracy}%';
        bestScore.antialiasing = true;
        bestScore.active = false;
        bestScore.y = bestBG.height / 2 - bestScore.height / 2;
        bestScore.x = bestBG.width / 2 - bestScore.width / 2;
        add(bestScore);

        bestRank = new FreeplayRank(0);
        bestRank.setRank(Timings.getRank(data.accuracy).rank, true);
        bestRank.updateHitbox();
        bestRank.y = bestBG.height / 2 - bestRank.height / 2 + 6;
        bestRank.x = bestBG.width - bestRank.width - 16;
        add(bestRank);
    }
}

/**
 * Ahh yes the pause menu, this code is kinda shitty btw.
 */
class PauseScreen extends FlxSubState
{
    private final DEFAULT_ITEMS:Array<String> = [
        'Resume', 'Restart Track', 'Settings', 'Exit'
    ];

    private final ACCESSIBILITY_ITEMS:Array<String> = [
        'botplay', 'practice mode', 'change difficulty', 'back'
    ];

    private var currentArray:Array<String> = [];
    private var slideOutItems:Array<Dynamic> = [];

    public var curSelected:Int = 0;

    public var canMove:Bool;

    private var backGradient:FlxSprite;
    private var paused:MoonSprite;
    private var back:MoonSprite;
    private var bestGroup:BestScoreGroup;

    public var oppIcon:PixelIcon;

    public var pauseItems:FlxTypedGroup<UIButton> = new FlxTypedGroup<UIButton>();

    private var pf:PlayField;
    var game(get, never):PlayState;
    var center:Float = 0;

    public function new(camera:FlxCamera)
    {
        super();
        canMove = true;
        this.camera = camera;
        pf = game.playField; // NAO NAO É UM PRATO FEITO É UM PLAYFIELD!!!!

        final tweenDur = 0.3;

        // < BACKGROUND SETUP > //
        backGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00000000, 0xFF111111], 1, 180);
        backGradient.alpha = 0;
        add(backGradient);
        FlxTween.tween(backGradient, {alpha: 0.7}, tweenDur);

        back = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        back.alpha = 0;
        back.blend = BlendMode.DIFFERENCE;
        add(back);
        FlxTween.tween(back, {alpha: 0.5}, tweenDur);

        paused = new MoonSprite(-800, 45).loadGraphic(Paths.image('menus/pause/pause'));
        paused.scale.set(2, 2);
        paused.antialiasing = false;
        paused.updateHitbox();
        add(paused);
        slideOutItems.push(paused);

        var pausedL = new MoonSprite(-800, paused.y + paused.height + 16).makeGraphic(Std.int(paused.width), 2, FlxColor.GRAY);
        add(pausedL);
        slideOutItems.push(pausedL);
        center = 55 + pausedL.width / 2;

        add(pauseItems);

        final meta = pf.chart.content.meta;
        final extraDist = 100;

        var songName = new ScrollingText(-400, pausedL.y + 48, pausedL.width - extraDist, '${meta.artist} - ${meta.displayName}');
        songName.textField.setFormat(Paths.font('phantomuff/full.ttf'), 24);
        songName.antialiasing = true;
        add(songName);
        slideOutItems.push(songName);

        var np = new FlxText(-400, songName.y - 12);
        np.setFormat(Paths.font('phantomuff/full.ttf'), 12, LEFT);
        np.text = 'Now Playing:\n\n\nCharted by: ${meta.charter}';
        np.antialiasing = true;
        np.active = false;
        add(np);
        slideOutItems.push(np);

        oppIcon = new PixelIcon(meta.opponents[0]);
        add(oppIcon);
        oppIcon.updateHitbox();
        oppIcon.setPosition(-400, songName.y + songName.height / 2 - oppIcon.height / 2);
        slideOutItems.push(oppIcon);

        regenItems(DEFAULT_ITEMS);

        final sData = SongData.retrieveData(pf.song, pf.difficulty, pf.mix);
        bestGroup = new BestScoreGroup(meta.players[0], Std.int(pausedL.width) - 96, sData);
        add(bestGroup);
        bestGroup.x = -400;
        bestGroup.y = pauseItems.members[pauseItems.members.length - 1].y + 90;
        slideOutItems.push(bestGroup);
        bestGroup.visible = (sData != null);

        // gotta love the tween bullshit here
        FlxTween.tween(bestGroup, {x: center - bestGroup.width / 2}, tweenDur, {ease: FlxEase.expoOut});
        for(woah in [songName, np])
            FlxTween.tween(woah, {x: 55 + extraDist}, tweenDur, {ease: FlxEase.expoOut});

        for(ye in [paused, pausedL, oppIcon])
            FlxTween.tween(ye, {x: 55}, tweenDur, {ease: FlxEase.expoOut});

        Paths.playSFX('game/pause/onPause${FlxG.random.bool(5) ? "-PVZ" : ""}.ogg');
    }

    override public function update(elapsed:Float)
    {
        if(MoonInput.justPressed(UI_DOWN) && canMove) changeSelection(1);
        if(MoonInput.justPressed(UI_UP) && canMove) changeSelection(-1);

        if(MoonInput.justPressed(BACK) && canMove)
        {
            if(currentArray != DEFAULT_ITEMS) regenItems(DEFAULT_ITEMS);
            else prepareToClose(true);
        }

        super.update(elapsed);

        if(MoonInput.justPressed(ACCEPT) && canMove)
        {
            switch(pauseItems.members[curSelected].text.toLowerCase())
            {
                case 'resume': 
                    prepareToClose();
                    Paths.playSFX('ui/confirmMenu.ogg');
                case 'restart track': 
                    //TODO: This isn't actually visible due to how fast it resets lol
                    // so uhhh... get it to be shown!!
                    paused.loadGraphic(Paths.image('menus/pause/reset'));
                    pf.restartSong();
                    resumeGame();
                case 'settings': 
                    close();
                    FlxG.state.openSubState(new Settings());
                //case 'accessibility settings': regenItems(ACCESSIBILITY_ITEMS);
                //case 'back': regenItems(DEFAULT_ITEMS);
                case 'exit': 
                    //PlayState.instance.destroy();
                    PlayState.instance.exit();
            }
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, pauseItems.members.length - 1);

        for(i in 0...pauseItems.members.length)
            pauseItems.members[i].selected = i == curSelected;

        Paths.playSFX('ui/scrollMenu.ogg');
    }

    public function regenItems(items:Array<String>)
    {
        currentArray = items;
        pauseItems.clear();
        
        for (i in 0...items.length)
        {
            final item = items[i];
            pauseItems.recycle(UIButton, function():UIButton
            {
                var hi = new UIButton(-250, 320 + (50 * i), item);
                hi.alpha = 0;
                hi.scale.set(0, 0);
                hi.selected = false;
                FlxTween.tween(hi, {alpha: 1, x: center - hi.width / 2}, 0.8, {ease: FlxEase.expoOut, startDelay: 0.04 * i});
                return hi;
            });
        }

        changeSelection(0);
    }

    var counter:Int = 3;

    final txtDisplay = ['0', '1', '2', '3'];
    final colors = [0xFF00FF00, 0xFFFFEE00, 0xFFFF8C00, 0xFFE50000];
    public function prepareToClose(?pressedEsc:Bool = false)
    {
        for (c in pauseItems.members) slideOutItems.push(c);
        canMove = false;

        paused.loadGraphic(Paths.image('menus/pause/resume'));

        if(!pressedEsc)FlxFlicker.flicker(pauseItems.members[curSelected], 1, 0.05, true);
        oppIcon.playAnim('select', true);
        // Note: Assuming access via the group; if BestScoreGroup is not a member variable, declare it as such if needed.
        // For this refactor, we'll assume it's local but accessible; in practice, make it a class member if reused.
        // But since it's only used in constructor and here, for completeness, declare private var bestGroup:BestScoreGroup; and assign in new.
        bestGroup.playerIcon.playAnim('select', true);

        // COUNTDOWN TEXT
        // TODO: change it.
        var wah = new FlxText(0, 0, 500, '');
        wah.setFormat(null, 78, FlxColor.WHITE, CENTER);
        wah.alpha = 0;
        wah.textField.antiAliasType = ADVANCED;
        //wah.textField.sharpness = 400;
        add(wah);

        new FlxTimer().start(pf.conductor.crochet / 1000 * 2, function(_)
        {
            for (bg in [backGradient, back]) FlxTween.tween(bg, {alpha: 0}, pf.conductor.crochet / 1000 * 2);
            for (item in slideOutItems) FlxTween.tween(item, {x: item.x - 700}, pf.conductor.crochet / 1000, {ease: FlxEase.expoIn});
        });

        // - Starts the lil countdown.
        new FlxTimer().start(pf.conductor.crochet / 1000, function(_)
        {
            if(counter == -1)
            {
                if(!pf.inCountdown)
                {
                    pf.playback.state = PLAY;    
                    pf.playback.resync();
                }
                resumeGame();
            }
            else
            {
                Paths.playSFX((counter == 0) ? 'game/pause/pausecountdown-end.ogg' : 'game/pause/pausecountdown-normal.ogg');
                wah.color = colors[counter];
                wah.text = txtDisplay[counter];
                wah.alpha = 1;
                wah.size += 16;
                wah.updateHitbox();
                wah.screenCenter();
            }
            counter--;
        }, 5);
    }

    public function resumeGame()
    {
        game.activeTweens(true);
        close();
    }

    @:noCompletion function get_game():PlayState
        return PlayState.instance;
}