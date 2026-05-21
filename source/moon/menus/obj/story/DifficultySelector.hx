package moon.menus.obj.story;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import moon.menus.obj.story.StoryWeek;
import moon.backend.data.SongLibrary.Difficulty;

class DifficultySelector extends FlxSpriteGroup
{
    public var box:MoonSprite;
    public var bar:MoonSprite;
    public var weekGroup:StoryWeek;
    public var difficulties:Array<Difficulty>;
    public var difficultyTexts:FlxSpriteGroup;
    public var availableDifficulties:Array<Difficulty>;
    public var currentDifficulty(get, never):Null<String>;
    function get_currentDifficulty() 
        return difficulties[curSelected]?.name;
    

    public var curSelected:Int = -1;
    public var ready:Bool = true;

    var fontSize:Int = 40;
    var difficultySpacing:Int = 25;

    public function new(weekId:String) 
    {
        super();

        box = new MoonSprite().makeGraphic(500, 300, 0xFF0D0316);
        add(box);

        bar = new MoonSprite().makeGraphic(Std.int(this.width * 0.8), 6, 0xFFFFFFFF);
        bar.setPosition(this.width / 2 - bar.width / 2, this.height / 2);
        add(bar);

        weekGroup = new StoryWeek(0, 0, weekId);
        weekGroup.setPosition(this.width / 2 - weekGroup.width / 2, this.height / 5);
        add(weekGroup);

        loadDifficulties();

        difficultyTexts = new FlxSpriteGroup();
        add(difficultyTexts);

        var posX:Float = 0;
        for(index => diff in difficulties) {
            var text = new FlxText(posX, 0, 0, diff.displayName);
            text.setFormat(Paths.font('phantomuff/difficulty.ttf'), fontSize);
            text.color = FlxColor.fromRGB(diff.color[0], diff.color[1], diff.color[2]);
            difficultyTexts.add(text);
            posX += text.width + difficultySpacing;
        }
        difficultyTexts.setPosition(this.width/2 - difficultyTexts.width/2, this.height/2 + 50);

        changeSelection(1);
    }

    override function update(e) 
    {
        super.update(e);
        if(!ready) return;

        for(index => text in difficultyTexts.members) text.alpha = FlxMath.lerp(text.alpha, index == curSelected ? 1 : 0.3, 0.1);
        if (MoonInput.justPressed(UI_LEFT)) changeSelection(-1);
        else if (MoonInput.justPressed(UI_RIGHT)) changeSelection(1);
    }

	function changeSelection(change:Int = 0):Void
    {
        Paths.playSFX('ui/scrollMenu.ogg');
        if(availableDifficulties.length <= 0) return;

        curSelected = FlxMath.wrap(curSelected + change, 0, difficultyTexts.length - 1);
        while(!availableDifficulties.contains(difficulties[curSelected]))
            curSelected = FlxMath.wrap(curSelected + change, 0, difficultyTexts.length - 1);
    }

    function loadDifficulties() 
    {
        difficulties = SongLibrary.instance.allDifficulties;

        var dummy:Null<Array<Difficulty>> = null;

        // Makes a list of difficulties and only keeps the ones that are in all of the songs in the week
        for(song in weekGroup.weekData.tracks) {
            var diffs:Array<Difficulty> = SongLibrary.instance.availableDifficulties(song, weekGroup.weekData.mainMix);
            dummy ??= diffs;
            for(difficulty in dummy) 
                if(!diffs.contains(difficulty)) dummy.remove(difficulty); 
        }

        availableDifficulties = dummy;
    }

    public function open(?finishCallback:Void->Void) {
        ready = false;
        this.scale.set(0, 0);
        this.alpha = 0;
        FlxTween.tween(this, {'scale.x': 1, 'scale.y': 1, alpha: 1}, 0.25, {ease: FlxEase.backOut, onComplete: (twn) -> { 
            if(finishCallback != null) finishCallback();
            ready = true;
        }});
    }

    public function close(?finishCallback:Void->Void) {
        ready = false;
        FlxTween.tween(this, {'scale.x': 0, 'scale.y': 0, alpha: 0}, 0.5, {ease: FlxEase.backIn, onComplete: (twn) -> { 
            if(finishCallback != null) finishCallback();
            this.destroy();
        }});
    }
}