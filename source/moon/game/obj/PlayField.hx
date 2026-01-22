package moon.game.obj;

import moon.menus.Freeplay;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import moon.game.obj.judgements.*;
import moon.backend.gameplay.PlayerStats;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.group.FlxGroup;
import moon.game.obj.notes.*;
import moon.backend.gameplay.*;

@:publicFields
class PlayField extends FlxGroup
{
    // -- VARIBALES
    public static var instance:PlayField;

    var conductor:Conductor;
    var playback:Song;

    var noteSpawner:NoteSpawner;
    var chart:Chart;

    var inCutscene:Bool = false;
    var song:String;
    var mix:String;
    var difficulty:String;

    var previousRank:String = "";

    var inputHandlers:Map<String, InputHandler> = [];
    var strumlines:Array<Strumline> = [];
    var playerStrum:Strumline;
    var oppStrum:Strumline;

    var judgements:JudgementSprite;
    var combo:ComboNumbers;
    var healthBar:HealthBar;
    var stats:FlxText;

    static var rankLevels:Array<String> = [for (t in Timings.thresholds) t.rank];

    // -- CALLBACKS -- //

    /**
     * Called whenever a song is started.
     */
    var onSongStart:Void->Void;

    /**
     * Called whenever the song is restarted
     */
    var onSongRestart:Void->Void;

    /**
     * Called when countdown is happening.
     */
    var onSongCountdown:Int->Void;

    /**
     * Called whenever a note gets hit (Good Hit.)
     */
    var onNoteHit:(String, Note, String, Bool)->Void;

    /**
     * Called whenever a note is missed (Bad Hit.)
     */
    var onNoteMiss:(String, Note)->Void;
    
    /**
     * Called whenever a key is pressed (if ghost tapping is off, it'll call onNoteMiss right after.)
     */
    var onGhostTap:Int->Void;

    /**
     * Creates a gameplay scene on screen.
     * @param song        The song that'll be played on the directory.
     * @param difficulty  The song's difficulty.
     * @param mix         The song's mix (e.g. bf, pico)
     */
    public function new(song:String, difficulty:String, mix:String)
    {
        super();
        this.song = song;
        this.mix = mix;
        this.difficulty = difficulty;

        instance = this;

        //< -- SONG SETUP -- >//
        chart = new Chart(song, difficulty, mix);
        
        conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);
        conductor.onBeat.add(beatHit);
        
        playback = new Song(
            song,
            mix,
            (difficulty == 'erect' || difficulty == 'nightmare'),
            conductor
        );
        playback.state = PAUSE;

        //< -- HEALTHBAR SETUP -- >//
        healthBar = new HealthBar(chart.content.meta.opponents[0], chart.content.meta.players[0]);
        add(healthBar);
        healthBar.setPosition(0, 0);
        healthBar.screenCenter(X);

        //< -- COMBO AND JUDGEMENTS SETUP -- >//
        // TODO: skins dammit
        judgements = new JudgementSprite('moon-engine');
        add(judgements);
        add(judgements.extra);

        combo = new ComboNumbers('moon-engine');
        add(combo);

        // Little text for testing out the accuracy.
        // oh lol it doesn't even show accuracy anymore LMFAO
        // fym it does now
        stats = new FlxText(0, 0);
        stats.setFormat(Paths.font('phantomuff/full.ttf'), 24, CENTER);
        stats.antialiasing = true;
        stats.setBorderStyle(SHADOW, FlxColor.BLACK, 4);
        add(stats);
    
        //< -- STRUMLINES & INPUTS SETUP -- >//
        strumlines = [];
        
        final playerIDs = ["opponent", "p1"];
        final isCPUPlayers = [true, false];

        for (i in 0...playerIDs.length)
        {
            var strumline = new Strumline(0, 68, /*chart.content?.meta?.noteskin ?? 'v-slice'*/ 'moon-engine', isCPUPlayers[i], playerIDs[i], conductor);
            add(strumline.strumBG);
            add(strumline);

            for(receptor in strumline.members)
            {
                add(receptor.sustainsGroup);
                add(receptor.notesGroup);
                add(receptor.splashGroup);
            }

            strumlines.push(strumline);
            (playerIDs[i]=='opponent') ? oppStrum = strumline : playerStrum = strumline; 

            var inputHandler = new InputHandler(null, playerIDs[i], strumline, conductor);
            inputHandler.CPUMode = isCPUPlayers[i];
            inputHandlers.set(playerIDs[i], inputHandler);

            inputHandler.onNoteHit = (note, timing, isSustain) -> onHit(playerIDs[i], note, timing, isSustain);
            inputHandler.onNoteMiss = (note) -> onMiss(playerIDs[i], note);
            inputHandler.onGhostTap = (keyDir) -> if(onGhostTap != null) onGhostTap(keyDir);
        }

        setupNotes();
        settingsUpdate();
        updateP1Stats(null, true);

        // obv loss, but whatev
        previousRank = Timings.getRank(inputHandlers.get('p1').stats.accuracy).rank;

        conductor.time = -(conductor.crochet * 6);
    }

    function setupNotes()
    {
        //< -- NOTES SETUP -- >//
        // Add the note spawner.
        noteSpawner = new NoteSpawner(chart.content.notes, strumlines, conductor);
        noteSpawner.scrollSpeed = chart.content.meta.scrollSpd;
        add(noteSpawner);

        // Set each input handler's notes.
        for (handler in inputHandlers.iterator())
            handler.thisNotes = noteSpawner.notes;
    }

    public function settingsUpdate()
    {
        final downscroll = MoonSettings.callSetting('Downscroll');

        for (strum in strumlines)
        {
            strum.y = (!downscroll) ? 80 : FlxG.height - strum.height - 80;

            final mid = (FlxG.width * 0.5);
            final xAddition = (FlxG.width * 0.25);
            final strumXs = [-xAddition, xAddition];

            //TODO: Fix opp notes appearing
            playerStrum.x = (MoonSettings.callSetting('Middlescroll')) ? mid : mid + strumXs[1];
            oppStrum.x = mid + strumXs[0];
            oppStrum.visible = oppStrum.strumBG.visible = !MoonSettings.callSetting('Middlescroll');

            strum.strumBG.setPosition(strum.x - (strum.strumBG.width / 2), 0);
            strum.strumBG.alpha = MoonSettings.callSetting('Lane Background Visibility');
        }

        healthBar.y = (downscroll) ? 64 : FlxG.height - healthBar.height + 32;

        // also this is just so much offsetted it looks like ASS
        stats.y = (MoonSettings.callSetting('Stats Position') == 'On Player Lane')
        ? ((downscroll) ? playerStrum.y + playerStrum.height + stats.height -8 : playerStrum.y - stats.height)
        : healthBar.y + stats.height + 8;
		centerText();
        //updateP1Stats(null, false);

        playback.updateVolume();
    }

    function restartSong()
    {
        playback.time = 0;
        playback.state = PAUSE;
        conductor.time = -(conductor.crochet * 6);

        for(strum in strumlines)
            for(receptor in strum.members)
            {
                receptor.notesGroup.clear();
                receptor.sustainsGroup.clear();
                receptor.sustainSplash.despawn(true);
            }
        
        for (handler in inputHandlers.iterator())
        {
            handler.thisNotes = [];
            handler.heldSustains.clear();
        }
        
        noteSpawner.clear();
        noteSpawner.killMembers();
        remove(noteSpawner, true);
        for (handler in inputHandlers.iterator())
            handler.stats.reset();

        setupNotes();
        updateP1Stats(null);

        previousRank = Timings.getRank(inputHandlers.get('p1').stats.accuracy).rank;

        if(onSongRestart != null) onSongRestart();
        inCountdown = true;
    }

    var inCountdown:Bool = true;
    override public function update(dt:Float)
    {
        // updates some stuff when not in cutscene.
        if(!inCutscene) conductor.time += (dt * 1000) * playback.pitch;
        Global.allowInputs = !inCutscene;

        super.update(dt);

        // set the input keys.
        for (handler in inputHandlers.iterator())
        {
            handler.justPressed = [
                MoonInput.justPressed(LEFT),
                MoonInput.justPressed(DOWN),
                MoonInput.justPressed(UP),
                MoonInput.justPressed(RIGHT)
            ];

            handler.pressed = [
                MoonInput.pressed(LEFT),
                MoonInput.pressed(DOWN),
                MoonInput.pressed(UP),
                MoonInput.pressed(RIGHT)
            ];

            handler.released = [
                MoonInput.released(LEFT),
                MoonInput.released(DOWN),
                MoonInput.released(UP),
                MoonInput.released(RIGHT)
            ];
            handler.update();
        }

        //TODO: REMOVE, PLACEHOLDER.
        if(FlxG.keys.justPressed.I) playback.pitch -= 0.05;
        else if (FlxG.keys.justPressed.O) playback.pitch += 0.05;
        //if(FlxG.keys.justPressed.O) noteSpawner.scrollSpeed = FlxG.random.float(0.2, 4);
        
        // update health based on p1's health.
        healthBar.health = inputHandlers.get('p1').stats.health;

        // uhhmmm yeah stats scaling thats p much all
        stats.scale.x = stats.scale.y = FlxMath.lerp(stats.scale.x, 1, dt * 12);

        final stat = inputHandlers.get('p1').stats;
        final rankData = Timings.getRank(stat.accuracy);

        if(stats.color != rankData.color)
        {
            final curRank = Timings.getRank(stat.accuracy).rank;
            if (curRank != previousRank)
            {
                final oldIndex = rankLevels.indexOf(previousRank);
                final newIndex = rankLevels.indexOf(curRank);

                if(MoonSettings.callSetting('Ranking Sound'))
                {
                    if (newIndex > oldIndex)
                        Paths.playSFX('game/ratingRaise.wav');
                    else if (newIndex < oldIndex)
                        Paths.playSFX('game/ratingLower.wav');
                }

                previousRank = curRank;
            }
        }

        stats.color = rankData.color;
        stats.text = 'Score: ${MoonUtils.formatNumber(stat.score)} • Misses: ${stat.misses} • Acc: ${stat.accuracy}% (${Timings.getRank(stat.accuracy).short})';
		centerText();
        
        if(FlxG.keys.justPressed.F5){
            Global.clearScriptList();
            Paths.clearMemory();
            Paths.clearUnusedAssets();
            FlxG.resetState();
        }
    }

    function onHit(playerID:String, note:Note, timing:String, isSustain:Bool)
    {
        if (playerID == 'p1')
        {
            stats.scale.set(1.07, 1.07);

            // actually its colored by judgement now so fuck
            //if(timing != null) setStatsColor(Timings.getParameters(timing)[4]);
            updateP1Stats(timing);
            playback.muteStatus(false, Voices_Player);
        }

        //final input = inputHandlers.get(playerID);
        //input.attachedChar

        if(onNoteHit != null) onNoteHit(playerID, note, timing, isSustain);
    }

    var statShake:FlxTween;
    function onMiss(playerID:String, note:Note)
    {
        if (playerID == 'p1')
        {
            // update stats
            updateP1Stats('miss');
            //p1Combo.comboRoll(0, 2, true);

            // and do a lil cool thing to the stats
            setStatsColor(FlxColor.RED);

            MoonUtils.cancelActiveTwn(statShake);
            statShake = FlxTween.shake(stats, 0.04, 0.14, X);

            // the good ol sfx ahaha
            Paths.playSFX('game/missnote${FlxG.random.int(1, 3)}.ogg');

            playback.muteStatus(MoonSettings.callSetting('Mute Voices on Miss'), Voices_Player);
        }
        if(onNoteMiss != null) onNoteMiss(playerID, note);
    }

    private function updateP1Stats(judgement, ?statsOnly = false):Void
    {
        // get the stat and update them
        final stat = inputHandlers.get('p1').stats;

        if(!statsOnly)
        {
            if(judgement != null)
                judgements.pop(judgement, stat.isGold);

            combo.pop('x${stat.combo}', judgements.color);
        }
    }

    var statsColor:FlxTween;
    function setStatsColor(color:FlxColor)
    {
        MoonUtils.cancelActiveTwn(statsColor);
        statsColor = FlxTween.color(stats, 0.4, color, Timings.getRank(inputHandlers.get('p1').stats.accuracy).color, {startDelay: 0.05});
    }
	
	function centerText()
	{
		if(MoonSettings.callSetting('Stats Position') != 'On Player Lane' || MoonSettings.callSetting('Middlescroll'))
			stats.screenCenter(X);
		else stats.x = playerStrum.x + playerStrum.width / 2 - stats.width;
	}

    function beatHit(beat:Float):Void
    {
        healthBar.bump();

       // <- COUNTDOWN STUFF -> //
       if(inCountdown && !inCutscene)
       {
            switch(beat)
            {
                case 0: 
                    playback.state = PLAY;
                    inCountdown = false;
                    if(onSongStart != null) onSongStart();
                //case -1: FlxG.sound.play(Paths.sound('game/countdown/intro-0.ogg', 'sounds'));
                //default: if(beat >= -4)FlxG.sound.play(Paths.sound('game/countdown/intro${beat+1}.ogg', 'sounds'));
            }

            if(onSongCountdown != null) onSongCountdown(Std.int(beat));
       }
    }
}