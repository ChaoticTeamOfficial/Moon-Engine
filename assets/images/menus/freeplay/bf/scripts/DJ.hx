import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import lime.app.Future;
import moon.dependency.MoonSound;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;

var cartoonPlayer:MoonSound;
function onCreate()
{
    // dj setup
    dj.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/menus/freeplay/bf/freeplay-bf"));
    
    // Main Anims
    dj.anim.addBySymbol("intro", "boyfriend dj intro", 24, false);
    dj.anim.addBySymbol("idle", "bf chilling", 24, false);
    dj.anim.addBySymbol("newChar", "Boyfriend DJ new character", 24, true);
    dj.anim.addBySymbol("confirm", "Boyfriend DJ confirm", 24, false);
    dj.anim.addBySymbol("leave", "Boyfriend DJ to CS", 24, false);

    // Rank Anims
    dj.anim.addBySymbol("rankWin", "Boyfriend DJ fist pump", 24, false);
    dj.anim.addBySymbol("rankLoss", "Boyfriend DJ loss reaction 1", 24, false);

    // Extra
    dj.anim.addBySymbol("afk1", "bf dj afk", 24, false);
    dj.anim.addBySymbol("afk2", "Boyfriend DJ watchin tv OG", 24, false);

    dj.anim.play("intro", true);

    // pos setup and more
    dj.screenCenter();
    dj.antialiasing = true;
    dj.x += 420;
    dj.y += 670;

    // cartoon sound setup
    cartoonPlayer = new MoonSound();
}

var afkIndex = 0;
function onUpdate(elapsed)
{
    switch(afkIndex)
    {
        case 0:
            if(dj.AFK_TIMER >= 60)
            {
                dj.canDance = false;
                dj.anim.play("afk1", true);
                afkIndex += 1;
                dj.AFK_TIMER = 0;
            }
        case 1:
            if(dj.AFK_TIMER >= 100)
            {
                FlxTween.tween(freeplay, {songVolume: 0.15}, 2.2, {startDelay: 2.2});
                dj.canDance = false;
                dj.anim.play("afk2", true);
                afkIndex += 1;
                dj.AFK_TIMER = 0;

                new FlxTimer().start(3.5, function(_)
                {
                    FlxG.sound.play(Paths.sound('menus/freeplay/tv_on.ogg', 'sounds'));
                    new FlxTimer().start(0.3, (_) -> playRandomCartoon());
                });
            }
    }
}

function chooseNextDJAction()
{
    if(FlxG.random.bool(16)) // change channel
    {
        dj.anim.play("afk2", true, false, 55);
        new FlxTimer().start(1, function(_)
        {
            FlxG.sound.play(Paths.sound('menus/freeplay/channel_switch.ogg', 'sounds'));
            new FlxTimer().start(0.3, (_) -> playRandomCartoon());
        });
    }
    else //keep watching the same channel
        dj.anim.play("afk2", true, false, 112);
}

function playRandomCartoon()
{
    new Future(() -> 
    {
        if(cartoonPlayer != null)
        {
            FlxG.sound.list.remove(cartoonPlayer);
            cartoonPlayer.stop();
        }

        cartoonPlayer.loadEmbedded(Paths.sound('menus/freeplay/cartoons/cartoon' + FlxG.random.int(1, 24) + '.ogg'));
        cartoonPlayer.play();
        FlxG.sound.list.add(cartoonPlayer);
    }, true);
}