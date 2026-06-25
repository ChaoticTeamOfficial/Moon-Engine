package moon.menus;

import animate.FlxAnimate;
import moon.game.PlayState;
import moon.menus.obj.freeplay.*;
import flixel.FlxG;
import flixel.FlxSubState;
import moon.backend.data.Chart;

using StringTools;

enum FreeplayTransition
{
    FADE;
    STICKERS;
    RANK;
    NONE;
}

// TODO: Document Freeplay.
class Freeplay extends FlxSubState
{
    public static var appearType:FreeplayTransition = NONE;
    public static var instance:Freeplay;

    public var character:String;

    public var songVolume:Float = MoonSettings.callSetting('Music Volume') / 100;
    static var curSelected:Int = 0;
    var songList:Array<SongBase> = [];

    public var conductor:Conductor;
    public var mainBG:FreeplayBG;
    public var weekBG:MoonSprite;
    public var thisDJ:FreeplayDJ;
    public var selector:FreeplaySongSelector;
    public var stars:DifficultyStars;
    public var diffSelector:FreeplayDifficultySelector;
    var topBar:MoonSprite;
    public var playerIcon:PixelIcon;
    public var infoText:HTMLText; //html text my belove,,,

    public var title(default, set):String = 'Freeplay';

    public function new(character:String = 'bf')
    {
        super();
        this.character = character;
        Global.allowInputs = false;
        instance = this;

        mainBG = new FreeplayBG(character);
        add(mainBG.behindBG);

        thisDJ = new FreeplayDJ(character);
        add(thisDJ);

        Global.scriptSet('behindBG', mainBG.behindBG);
        Global.scriptSet('frontBG', mainBG.frontBG);
        Global.scriptSet('foreground', mainBG.foreground);
        Global.scriptSet('dj', thisDJ);

        weekBG = new MoonSprite();
        weekBG.loadGraphic(Paths.image('menus/freeplay/bgs/week6'));
        weekBG.scale.set(1.4, 1.4);
        weekBG.antialiasing = true;
        weekBG.updateHitbox();
        weekBG.skew.x = -20;
        weekBG.x = FlxG.width + weekBG.width + 360;
        weekBG.brightness = -1;
        add(weekBG);

        FlxTween.tween(weekBG, {x: FlxG.width - weekBG.width + 360, "skew.x": 5}, Constants.FREEPLAY_TRANSITION_DURATION, {ease: FlxEase.expoOut, onComplete: _->{
            weekBG.brightness = 0.69;
            FlxTween.tween(weekBG, {brightness: -0.45}, 0.35);
            Global.scriptCall('onTransitionEnd', []);
        }});

        add(mainBG.frontBG);

        Global.scriptSet('freeplay', this);

        conductor = new Conductor(0, 4, 4);
        conductor.onBeat.add((beat) ->
        {
            if ((beat % 2 == 0 || conductor.bpm < 120) && thisDJ.canDance)
                thisDJ.playAnim('idle', true);

            Global.scriptCall('onBeat', [beat]);
        });

        add(mainBG.foreground);

        stars = new DifficultyStars(0, 614, 24, 0.055);
        stars.screenCenter(X);
        stars.x += 280;
        stars.difficulty = 0;

        diffSelector = new FreeplayDifficultySelector();
        diffSelector.setPos(stars.x + 110, stars.y + 64);
        
        // Now load the song list with the default difficulty
        songList = getMixSonglist('all', character, diffSelector.getSelected());

        selector = new FreeplaySongSelector();
        selector.loadSongs(songList, curSelected);
        add(selector);
        add(stars);
        add(diffSelector);

        topBar = new MoonSprite().makeGraphic(FlxG.width + 16, 78, FlxColor.BLACK);
        topBar.screenCenter(X);
        add(topBar);

        // I love this goofy.,,,
        playerIcon = new PixelIcon(32, 0, character);
        add(playerIcon);
        playerIcon.y = topBar.y + topBar.height / 2 - playerIcon.height / 2;
        playerIcon.alpha = 0.0001;

        infoText = new HTMLText();
        infoText.setFormat(Paths.font('04/04B_19.TTF'), 24, LEFT);
        add(infoText);
        infoText.antialiasing = false;
        updateInfoText();
        infoText.x = -infoText.width - 16;
        FlxTween.tween(infoText, {x: playerIcon.x + playerIcon.width + 32}, Constants.FREEPLAY_TRANSITION_DURATION, {ease: FlxEase.expoOut}); 
    
        topBar.y -= topBar.height + 8;
        FlxTween.tween(topBar, {y: 0}, Constants.FREEPLAY_TRANSITION_DURATION, {ease: FlxEase.circInOut, onComplete: _->{
            playerIcon.alpha = 1;
            playerIcon.brightness = 1;
            FlxTween.tween(playerIcon, {brightness: 0}, Constants.FREEPLAY_TRANSITION_DURATION);
        }});

        Global.scriptCall('onCreate');
    }

    /**
     * Gets the song list for a week, preferring the given mix and difficulty.
     * @param week The week name. It can also be 'all' if you want all available songs.
     * @param preferredMix The character mix.
     * @param diff The difficulty to filter by.
     */
    public function getMixSonglist(week:String, preferredMix:String, diff:String):Array<SongBase>
    {
        final filtered:Array<SongBase> = [];

        for (song in SongLibrary.get().weekSonglist(week))
            if (song.mix == preferredMix && song.difficulty == diff)
                filtered.push(song);

        return filtered;
    }

    public function change(num:Int = 0)
    {
        if(songList.length <= 0) return;

        curSelected = flixel.math.FlxMath.wrap(curSelected + num, 0, songList.length - 1);
        selector.changeSelection(num);
        Paths.playSFX('ui/scrollMenu.ogg', 'sounds', true, FlxG.random.float(0.9, 1.2));

        Global.scriptCall('onScroll');
    }

    /**
     * Changes the difficulty, reloading the song list to reflect it.
     * It attempts to keep the currently selected song if it exists in the new difficulty.
     */
    public function changeDiff(delta:Int)
    {
        diffSelector.change(delta);
        
        var newDiff = diffSelector.getSelected();
        var newSongList = getMixSonglist('all', character, newDiff);
        
        // Try to find the currently selected song in the new list
        var curSongName:String = songList.length > 0 ? songList[curSelected].song : null;
        
        songList = newSongList;
        var newSelected:Int = 0;
        if (curSongName != null)
        {
            for (i in 0...songList.length)
            {
                if (songList[i].song == curSongName)
                {
                    newSelected = i;
                    break;
                }
            }
        }
        
        curSelected = newSelected;
        selector.loadSongs(songList, curSelected);
        
        updateInfoText();

        if(songList.length <= 0)
        {
            stars.difficulty = 0;
            //
        }

        Global.scriptCall('onDifficultyChange');
    }

    public function updateInfoText()
    {
        final total = selector.songList.length;
        infoText.text = '${title}\n' + 
        '<font size="20px">' +
        '<font color="#ff00fe">${selector.PRanks}/$total Perfects <font color="#ffffff">-'+
        ' <font color="#fea711">${selector.goldPRanks}/$total Goldens';
        infoText.y = topBar.y + topBar.height / 2 - infoText.height / 2;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if(FlxG.sound.music != null)
        {
            if(FlxG.sound.music.playing) conductor.time = FlxG.sound.music.time;
            
            try{
                if(FlxG.sound.music.fadeTween == null || (FlxG.sound.music.fadeTween != null && !FlxG.sound.music.fadeTween.active)) 
                    FlxG.sound.music.volume = FlxMath.lerp(FlxG.sound.music.volume, songVolume, elapsed * 8);
            }
            catch(e) {}
        }

        if (MoonInput.justPressed(UI_DOWN)) change(1);
        if (MoonInput.justPressed(UI_UP)) change(-1);

        if (MoonInput.justPressed(UI_LEFT)) changeDiff(-1);
        if (MoonInput.justPressed(UI_RIGHT)) changeDiff(1);

        if(FlxG.mouse.wheel != 0) change(-FlxG.mouse.wheel);

        if (MoonInput.justPressed(ACCEPT))
        {
            if(songList.length <= 0) return;

            // sets the next transitionIn to false
            // otherwise, for some reason, it shows the main menu when transitioning.
            // so instead, I'll do a fade.
            FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;

            final selected = selector.getSelected();
            Global.allowInputs = false;

            //reset the AFK timer and the "canDance" so it doesn't fuck out the anims 
            thisDJ.canDance = false;
            thisDJ.AFK_TIMER = 0;
            thisDJ.playAnim('confirm', true);
            playerIcon.playAnim('select', true);

            Paths.playSFX('ui/confirmMenu.ogg');

            selector.getSelectedItem().doConfirm();
            Global.scriptCall('onConfirm');

            new FlxTimer().start(1.79, _->{
                if (selected != null)
                {
                    PlayState.songData = {
                        song: selected.song,
                        difficulty: selected.difficulty,
                        mix: selected.mix
                    };
                    FlxG.switchState(() -> new LoadingScreen());
                }
            });
        }

        if(MoonInput.justPressed(BACK))
        {
            Global.allowInputs = false;

            diffSelector.setPos(stars.x + 900, stars.y + 64);
            selector.playExitAnimation(null);
            FlxTween.tween(weekBG, {x: FlxG.width + weekBG.width + 360, "skew.x": -5}, Constants.FREEPLAY_TRANSITION_DURATION, {ease: FlxEase.expoIn, onComplete: _->{
                close();
                Global.allowInputs = true;
            }});
        }

        Global.scriptCall('onUpdate', [elapsed]);
    }

    @:noCompletion public function set_title(title:String):String
    {
        this.title = title;
        updateInfoText();
        return title;
    }
}