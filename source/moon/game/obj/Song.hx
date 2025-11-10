package moon.game.obj;

import flixel.FlxG;
import moon.dependency.MoonSound.MusicType;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal;

enum SongState {
    PLAY;
    PAUSE;
    STOP;
    KILL;
}

class Song extends FlxTypedGroup<MoonSound>
{
    /**
     * The song's state, those being: `PLAY`, `PAUSE`, `STOP` & `KILL`.
     */
    public var state(default, set):SongState = PLAY;

    /**
     * The song's pitch.
     */
    public var pitch(default, set):Float = 1;

    /**
     * The song's current time.
     */
    @:isVar public var time(get, set):Float = 0;

    /**
     * Get the song's full time.
     */
    @:isVar public var fullLength(get, never):Float = 0;

    public var inst:Array<MoonSound> = [];
    public var voices:Array<MoonSound> = [];

    public final onFinish = new FlxTypedSignal<Void->Void>();

    private var conductor:Conductor;

    /**
     * Creates a song insance, useful for gameplay Inst & Voices.
     * @param song The name of the song
     * @param char The character mix
     * @param useErect Whether or not to use the erect song 
     * @param conductor 
     */
    public function new(song:String, char:String, ?useErect:Bool, conductor:Conductor)
    {
        super();
        this.conductor = conductor;

        var audList =[Voices_Opponent, Voices_Player, Inst];

        for(i in 0...audList.length)
        {
            final item = audList[i];

            final erectOrNot = (useErect) ? "-erect" : "";
            final items = '$song/$char/${audList[i]}$erectOrNot';
            //trace(items);
            //trace(Paths.sound('$items', 'songs'));

            if(Paths.exists('songs/$items.ogg'))
            {
                this.recycle(MoonSound, function():MoonSound
                {
                    var aud = cast new MoonSound().loadEmbedded(Paths.sound('$items', 'songs'), false, true);
                    aud.type = audList[i];
                    aud.strID = song;
                    aud.onComplete = finish;
                    FlxG.sound.list.add(cast aud);

                    (aud.type == Inst) ? inst.push(aud) : voices.push(aud);
                    return aud;
                });
            }
        }

        conductor.onStep.add(steps);
    }

    override public function update(dt:Float)
    {
        super.update(dt);
        if (conductor.time >= fullLength)
            finish();
    }

    /**
     * Mutes/Unmutes certain audio types.
     * @param mute Whether it should be mute or not
     * @param type The music type (e.g. Inst)
     */
    public function muteStatus(mute:Bool, type:MusicType)
    {
        for (aud in this.members)
            if(aud.type == type)
                aud.volume = mute ? 0 : MoonSettings.callSetting(type == Inst ? 'Instrumental Volume' : 'Voices Volume') / 100;
    }

    public function updateVolume()
    {
        for (aud in this.members)
            aud.volume = MoonSettings.callSetting(aud.type == Inst ? 'Instrumental Volume' : 'Voices Volume') / 100;
    }

    function finish()
    {
        //trace("AAAAAAAAAAAA");
        onFinish.dispatch();
    }

    final threshold = 30;
    private function steps(step)
    {
        if (this.state == PLAY)
        {
            //resync if its off compared to conductor
            for (i in inst)
                if ((i.time >= conductor.time + threshold || i.time <= conductor.time - threshold))
                    resync();

            //resync if the vocals are off compared to inst
            if(voices.length > 0)
                for(v in voices)
                    for(i in inst)
                        if(Math.abs(v.time - i.time) > 5) //has to be at 5 just to make sure its in time :P
                            v.time = i.time;
        }
    }

    /**
     * Resyncs every member in this instance to their supposed time position based on conductor.
     */
    public function resync():Void
    {
        for(i in inst)
        {
            conductor.time = i.time;
            if(voices.length > 0) for(v in voices) v.time = i.time;
        }
        //(member.type == Inst) ? conductor.time = member.time : member.time = conductor.time;
    }

    override public function kill()
    {
        super.kill();

        for (member in this.members)
        {
            FlxG.sound.list.remove(member, true);
            remove(member);
            member.destroy();
        }
        inst = voices = null;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    @:noCompletion public function set_state(state:SongState = PLAY):SongState
    {
        this.state = state;
        for (i in 0...members.length)
        {
            switch(state)
            {
                case PLAY: members[i].play();
                case PAUSE: members[i].pause();
                case STOP: members[i].stop();
                case KILL: 
                    FlxG.sound.list.remove(this.members[i]);
                    members[i].kill();
            }
        }
        return state;
    }

    @:noCompletion public function set_pitch(value:Float):Float
    {
        pitch = value;

        for (i in 0...members.length)
            members[i].pitch = pitch;

        return value;
    }

    @:noCompletion public function get_time():Float
    {
        var lastTime:Float = 0;
        for (i in 0...members.length)
            lastTime = members[i].time;

        return lastTime;
    }       

    @:noCompletion public function set_time(value:Float):Float
    {
        time = value;
        for(i in 0...members.length)
            members[i].time = value;

        return value;
    }
    
    @:noCompletion public function get_fullLength():Float
    {
        var lastLength:Float = 0;
        for (i in 0...members.length)
            lastLength = members[i].length;

        return lastLength;
    }
}