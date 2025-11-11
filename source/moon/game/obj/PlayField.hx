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

    var inputHandlers:Map<String, InputHandler> = [];
    var strumsBG:Array<MoonSprite> = [];
    var strumlines:Array<Strumline> = [];
    var playerStrum:Strumline;
    var oppStrum:Strumline;

    var healthBar:HealthBar;
    
    //var p1Judgements:JudgementSprite;
    //var p1Combo:ComboNumbers;
    var stats:FlxText;

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

        //< -- COMBO SETUP -- >//
        //TODO: Refactor and do an overhaul on this system.
        //TODO: Its currently VERY terrible on optimization :P
        /*p1Judgements = new JudgementSprite();
        p1Judgements.alpha = 0.0001;
        //just for preloading :p
        
        for(judgement => judgementVals in Timings.judgementsMap)
            p1Judgements.showJudgement(judgement, true, true);

        add(p1Judgements);*/

        //p1Combo = new ComboNumbers();
        //add(p1Combo);

        //< -- HEALTHBAR SETUP -- >//
        healthBar = new HealthBar(chart.content.meta.opponents[0], chart.content.meta.players[0]);
        add(healthBar);
        healthBar.setPosition(0, 0);
        healthBar.screenCenter(X);
    
        //< -- STRUMLINES & INPUTS SETUP -- >//
        strumlines = [];

        final xVal = (FlxG.width * 0.5);
        final xAddition = (FlxG.width * 0.25);
        final strumXs = [-xAddition, xAddition];
		
        final playerIDs = ["opponent", "p1"];
        final isCPUPlayers = [true, false];

        for (i in 0...playerIDs.length)
        {
            var strumBG = new MoonSprite();
            add(strumBG);
            strumsBG.push(strumBG);
            //TODO: Skins lol
            var strumline = new Strumline(xVal + strumXs[i], 68, 'v-slice', isCPUPlayers[i], playerIDs[i], conductor);
            add(strumline);

            strumBG.makeGraphic(Std.int(strumline.width + 64), Std.int(FlxG.height) + 32, FlxColor.BLACK);
            strumBG.setPosition(strumline.members[0].x - 32, 0);

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

            //p1Judgements.skin = p1Combo.skin = strumline.members[0].judgementsSkin;
        }

        // Little text for testing out the accuracy.
        // oh lol it doesn't even show accuracy anymore LMFAO
        // fym it does now
        stats = new FlxText(0, 0);
        stats.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 20, FlxColor.WHITE, CENTER);
        stats.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        stats.textField.antiAliasType = ADVANCED;
        stats.textField.sharpness = 400;
        add(stats);

        setupNotes();
        settingsUpdate();
        updateP1Stats(null, true);

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
            if(strum.playerID == 'p1')
                playerStrum = strum;

            strum.y = (!downscroll) ? 80 : FlxG.height - strum.height - 80;
        }
        
        for(strumBG in strumsBG)
            strumBG.alpha = MoonSettings.callSetting('Lane Background Visibility');

        healthBar.y = (downscroll) ? 64 : FlxG.height - healthBar.height + 32;

        // also this is just so much offsetted it looks like ASS
        stats.y = (MoonSettings.callSetting('Stats Position') == 'On Player Lane')
        ? ((downscroll) ? playerStrum.y + playerStrum.height + stats.height -8 : playerStrum.y - stats.height)
        : healthBar.y + stats.height + 8;
        updateP1Stats(null, false);

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
		
		if(FlxG.keys.justPressed.ONE) FlxG.resetState();
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
            Paths.playSFX('game/missnote${FlxG.random.int(1, 3)}');

            playback.muteStatus(MoonSettings.callSetting('Mute Voices on Miss'), Voices_Player);
        }
        if(onNoteMiss != null) onNoteMiss(playerID, note);
    }

    private function updateP1Stats(judgement, ?statsOnly = false):Void
    {
        // get the stat and update them
        final stat = inputHandlers.get('p1').stats;
        final rankData = Timings.getRank(stat.accuracy);
        stats.text = 'Score: ${stat.score} // Misses: ${stat.misses} // Accuracy: ${stat.accuracy}% (${rankData.short})';
        stats.color = rankData.color;

        // set stats X based on what setting it is.
        final sx = playerStrum.x + playerStrum.width / 2;

        ((MoonSettings.callSetting('Stats Position') != 'On Player Lane')) ? stats.screenCenter(X)
        : stats.x = sx - (stats.width / 2);

        /*if(!statsOnly)
        {
            if(judgement != null)
            {
                p1Judgements.color = Timings.getParameters(judgement)[4];
                
                p1Judgements.screenCenter();
                p1Judgements.y -= 60;
                p1Judgements.showJudgement(judgement, true, true);
            }
            
            //TODO: custom positioning
            p1Combo.combo = stat.combo;
            p1Combo.displayCombo(true, true);
            p1Combo.numsColor = p1Judgements.color;
            p1Combo.screenCenter();
        }*/
    }

    var statsColor:FlxTween;
    function setStatsColor(color:FlxColor)
    {
        MoonUtils.cancelActiveTwn(statsColor);
        statsColor = FlxTween.color(stats, 0.4, color, Timings.getRank(inputHandlers.get('p1').stats.accuracy).color, {startDelay: 0.05});
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
                case -1: FlxG.sound.play(Paths.sound('game/countdown/intro-0', 'sounds'));
                default: if(beat >= -4)FlxG.sound.play(Paths.sound('game/countdown/intro${beat+1}', 'sounds'));
            }

            if(onSongCountdown != null) onSongCountdown(Std.int(beat));
       }
    }
}