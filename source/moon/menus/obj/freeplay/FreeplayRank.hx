package moon.menus.obj.freeplay;


class FreeplayRank extends MoonSprite
{
    public var rank:String;
    
    public function new(?x:Float = 410, ?y:Float = 42)
    {
        super(x, y);
        frames = Paths.getSparrowAtlas("menus/freeplay/rankbadges");

        animation.addByPrefix("LOSS", "LOSS rank0", 24, false);
        animation.addByPrefix("GOOD", "GOOD rank0", 24, false);
        animation.addByPrefix("GREAT", "GREAT rank0", 24, false);
        animation.addByPrefix("EXCELLENT", "EXCELLENT rank0", 24, false);
        animation.addByPrefix("PERFECT", "PERFECT rank0", 24, false);
        animation.addByPrefix("PERFECT-GOLD", "PERFECT rank GOLD0", 24, false);

        /*addOffset("loss", -3, 4);
        addOffset("good", 0, 4);
        addOffset("great", 0, 4);
        addOffset("excellent", -2, 4);
        addOffset("perfect", 0, 2);
        addOffset("perfectGold", 0, 2);*/
        centerAnimations = true;
        playAnim("perfectGold");
        updateHitbox();

        antialiasing = true;
    }

    public function getRankColor():FlxColor
    {
        switch (rank)
        {
            case 'loss': return 0xFF6044FF;
            case 'good': return 0xFFEF8764;
            case 'great' :return 0xFFEAF6FF;
            case 'excellent': return 0xFFFDCB42;
            case 'perfect': return 0xFFFF58B4;
            case 'perfectGold': return 0xFFFFB619;
        }

        return FlxColor.WHITE; //little handler :T
    }
    
    public function setRank(rank:String, force:Bool = false):Void
    {
        this.rank = rank;
        playAnim(rank, force);
        visible = true;
    }
}
