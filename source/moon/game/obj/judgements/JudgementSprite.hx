package moon.game.obj.judgements;

import moon.backend.gameplay.*;

using StringTools;

@:publicFields
class JudgementSprite extends MoonSprite
{   
    var extra:MoonSprite;
    var skin(default, set):String;
    var data:JudgementsCombo;

    public function new(skin:String)
    {
        super();
        this.skin = skin;
        alpha = 0.00001;
        extra.visible = false;
        extra.blend = ADD;
    }

    var thisTwn:FlxTween;
    var xtraTwn:FlxTween;
    function pop(judgement:String = 'sick', isGold:Bool = false, notAnimated:Bool = false)
    {
        if (judgement == null) return;

        MoonUtils.cancelActiveTwn(thisTwn);

        playAnim(judgement, true);
        extra.playAnim(judgement, true);

        this.color = (isGold) ? 0xFFfeae34 : Timings.getParameters(judgement)[4];
        scale.set(data?.judgementsSize ?? 1, data?.judgementsSize ?? 1);
        updateHitbox();
        alpha = 1;
        //screenCenter();

        if(notAnimated) return;
        if(data?.judgementAnims?.appear == 'light')
        {
            MoonUtils.cancelActiveTwn(xtraTwn);

            if(!extra.visible) extra.visible = true;
            extra.color = this.color;
            extra.scale.set((data?.judgementsSize ?? 1) * 0.95, (data?.judgementsSize ?? 1) * 0.95);
            extra.updateHitbox();
            extra.alpha = 1;
            extra.screenCenter();

            xtraTwn = FlxTween.tween(extra, {"scale.x": extra.scale.x * 1.35, "scale.y": extra.scale.y * 1.35, alpha: 0}, 0.8, {ease: FlxEase.expoOut});
        }

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

        extra = new MoonSprite();
        extra.loadGraphicFromSprite(this);

        return skin;
    }
}