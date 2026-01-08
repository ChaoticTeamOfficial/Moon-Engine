package moon.menus.obj;

using StringTools;
class ScrollingArts extends FlxSpriteGroup
{
    private var imgs:Array<String> = [];

    public var scrollAmmount:Float;
    public var scrollLength:Float;

    /**
     * Creates the class, it will make some arts (or images) scroll.
     * @param path Path containing all the images you want to be displayed.
     * @param scrollAmount How much should an image scroll.
     * @param scrollLength How many seconds should an image take to scroll.
     */
    public function new(path:String, ?scrollAmmount:Float = 60, ?scrollLength:Float = 5)
    {
        super();
        this.scrollAmmount = scrollAmmount;
        this.scrollLength = scrollLength;
        imgs = Paths.readDir(path);

        for(i in 0...imgs.length)
        {
            this.recycle(MoonSprite, function():MoonSprite
            {
                var img = new MoonSprite().loadGraphic(Paths.image('${path.split("images/")[1]}/${imgs[i].split(".png")[0]}'));
                img.alpha = 0.0001;
                return img;
            });
        }

        doScrolling(0);
    }

    var tween1:FlxTween;
    var tween2:FlxTween;
    var tween3:FlxTween;
    var cool:Bool = false;
    public function doScrolling(index:Int)
    {
    	cool = !cool;
    	
        final spr = this.members[index];
        spr.screenCenter();

        for(twn in [tween1, tween2, tween3])
            MoonUtils.cancelActiveTwn(twn);
        
        tween1 = FlxTween.tween(spr, {alpha: 1}, 0.5);
        tween2 = FlxTween.tween(spr, {x: (cool) ? spr.x - scrollAmmount : spr.x + scrollAmmount}, scrollLength);
        tween3 = FlxTween.tween(spr, {alpha: 0.0001}, 0.5, {startDelay: scrollLength - 0.5, onComplete: (_) -> doScrolling(FlxG.random.int(0, this.members.length - 1, [index]))});
    }
}