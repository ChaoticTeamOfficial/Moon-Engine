package moon.menus.obj.replay;

import flixel.group.FlxSpriteGroup;
import moon.global_obj.PixelIcon;
import moon.backend.gameplay.Timings;
import moon.menus.obj.freeplay.FreeplayRank;
import DateTools;
using StringTools;

class ReplayItem extends FlxSpriteGroup {
    public var id:Null<String>;
    public var difficulty:Null<String>;
    public var mix:Null<String>;
    public var replayPath:Null<String>;

    // stuff for the menu to display
    public var chartDisplayName:Null<String>;
    public var rpCode:Null<String>;
    public var recordDate:Null<String>;
    public var maxCombo:Null<Int>;
    public var score:Null<Int>;
    public var misses:Null<Int>;
    public var acc:Null<Float>;

    // visual stuff for the option
    public var bg:Null<MoonSprite>;
    public var title:Null<FlxText>;
    public var chartName:Null<FlxText>;
    public var iconOpponent:PixelIcon;
    public var iconPlayer:PixelIcon;
    public var rankDisplay:FreeplayRank;

    static var selectedBGColor:FlxColor = FlxColor.WHITE;
    static var unselectedBGColor:FlxColor = FlxColor.BLACK;
    static var selectedTextColor:FlxColor = FlxColor.BLACK;
    static var unselectedTextColor:FlxColor = FlxColor.WHITE;
    static var selectedChartTextColor:FlxColor = 0xFF202020;
    static var unselectedChartTextColor:FlxColor = FlxColor.GRAY;

    public function new(x:Float, y:Float, data:String):Void {
        super(x, y);
        replayPath = data;
        final replayData = Paths.JSON('data/replays/$data', 'mrp');
        var splitData = data.split('_');
        id = splitData[0];
        difficulty = splitData[1];
        mix = splitData[2];
        rpCode = splitData[3];
        final chartData = new Chart(id, difficulty, mix);

        maxCombo = replayData.stats?.maxCombo;
        score = replayData.stats?.score;
        misses = replayData.stats?.misses;
        acc = replayData.stats?.accuracy;

        bg = new MoonSprite().makeGraphic(900, 64, selectedBGColor);
		add(bg);

        final rank = Timings.getRank(acc).rank;

        rankDisplay = new FreeplayRank();
        rankDisplay.x += 430; rankDisplay.y -= 30;
        rankDisplay.setRank(rank); rankDisplay.updateHitbox();
        if (acc == null) {
            rankDisplay.visible = false;
        } else {
            var rankShadow = new FreeplayRank();
            rankShadow.x += 430; rankShadow.y -= 28;
            rankShadow.setRank(rank); rankShadow.updateHitbox();
            add(rankShadow); rankShadow.color = FlxColor.BLACK;
        }
        add(rankDisplay);

        iconOpponent = new PixelIcon(4, 4, 'bf'); iconOpponent.character = chartData.content.meta.opponents[0]; iconOpponent.character = chartData.content.meta.opponents[0];
        add(iconOpponent); iconOpponent.setGraphicSize(48); iconOpponent.updateHitbox();
        iconPlayer = new PixelIcon(32, 16, 'bf'); iconPlayer.character = chartData.content.meta.players[0]; iconPlayer.character = chartData.content.meta.players[0];
        add(iconPlayer); iconPlayer.setGraphicSize(48); iconPlayer.updateHitbox();

        title = new FlxText(84, 8);
        title.text = replayData.displayName ?? data;
        title.setFormat(Paths.font('phantomuff/full.ttf'), 24, CENTER);
        title.color = selectedTextColor;
        title.antialiasing = true;
        add(title);

        chartName = new FlxText(84, 40);
        var date:Date;
        if (replayData.replayCode != null)
            date = Date.fromTime(replayData.replayCode);
        else 
            date = Date.fromTime(Std.parseFloat(splitData[3]));

        chartDisplayName = chartData.content.meta.displayName;
        recordDate = DateTools.format(date, '%d/%m/%Y');
        chartName.text = '${chartData.content.meta.displayName} - (${recordDate})';
        chartName.setFormat(Paths.font('phantomuff/full.ttf'), 16, CENTER);
        chartName.color = selectedChartTextColor;
        chartName.antialiasing = true;
        add(chartName);
    }

    public function select():Void {
        bg.color = selectedBGColor;
        title.color = selectedTextColor;
        chartName.color = selectedChartTextColor;
    }

    public function deselect():Void {
        bg.color = unselectedBGColor;
        title.color = unselectedTextColor;
        chartName.color = unselectedChartTextColor;
    }
}