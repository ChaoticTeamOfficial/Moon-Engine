package moon.menus.obj.replay;

import flixel.group.FlxSpriteGroup;

class ReplayButton extends FlxSpriteGroup {
    public var selectColors:Array<FlxColor> = [0xFFFFFFFF, 0xFF000000];
    public var deselectColors:Array<FlxColor> = [0x0, 0xFFFFFFFF];

    var selBG:MoonSprite;
    var butText:FlxText;

    public function new(width:Int, height:Int, text:String, ?lineColor:FlxColor = FlxColor.GRAY) {
        super(0, 0);

		selBG = new MoonSprite().makeGraphic(width, height, FlxColor.WHITE); selBG.visible = false;
		var playBG = new MoonSprite().makeGraphic(width, height, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(playBG, 0, 0, width, height, 16, 16, FlxColor.TRANSPARENT, {
			thickness: 8.0,
			color: lineColor
		});
	    butText = new FlxText(); butText.x = 14; butText.y = height / 4;
		butText.setFormat(Paths.font('phantomuff/full.ttf'), 24, CENTER);
        butText.antialiasing = true; butText.text = text;
		add(playBG);
		add(selBG);
		add(butText);
    }

    public function setSelect() {
        selBG.color = selectColors[0]; selBG.visible = true;
        butText.color = selectColors[1];
    }

    public function setDeselect() {
        selBG.color = deselectColors[0]; selBG.visible = false;
        butText.color = deselectColors[1];
    }
}