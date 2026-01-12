package moon.game.obj.judgements;

import moon.backend.gameplay.*;

using StringTools;

@:publicFields
class JudgementSprite extends MoonSprite
{
    var skin(default, set):String;
    var data:JudgementsCombo;

    var thisTwn:FlxTween;

    public function new(skin:String)
    {
        super();
        this.skin = skin;
        alpha = 0.00001;
    }

    function pop(judgement:String = 'sick')
    {
        if (judgement == null) return;

        MoonUtils.cancelActiveTwn(thisTwn);

        playAnim(judgement, true);
        this.color = Timings.getParameters(judgement)[4];
        scale.set(data?.size ?? 1, data?.size ?? 1);
        updateHitbox();
        alpha = 1;
        screenCenter();

        final appear = data?.judgementAnims?.appear ?? 'jump-in';
        final disappear = data?.judgementAnims?.disappear ?? 'fade';

        MoonUtils.doSpriteAnim(this, appear, disappear, function(t) thisTwn = t);
    }

    function set_skin(skin:String):String
    {
        this.skin = skin;

        data = JudgementsCombo.getData(skin);
        antialiasing = data?.antialiasing ?? true;

        for(file in Paths.readDir('images/combo_judgements/$skin'))
            if(file.startsWith('judgements'))
            {
                final resolution = file.split('-')[1].split('x');
                loadGraphic(Paths.image('combo_judgements/$skin/${file.split(".png")[0]}'), true, Std.parseInt(resolution[0]), Std.parseInt(resolution[1]));

                final wow = ['sick', 'good', 'bad', 'shit', 'miss', 'combo'];
                for(i in 0...wow.length)
                    animation.add(wow[i], [i], 0, false);
            }

        return skin;
    }
}