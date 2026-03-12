package moon.menus.obj.freeplay;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import moon.global_obj.PixelIcon;

using StringTools;

class FreeplaySongItem
{
    static final TEXT_GAP:Float = 10.0;
    static final TEXT_W:Int = 260;

    public var x:Float = -9999;
    public var y:Float = -9999;

    public var targetAlpha:Float = 1.0;
    public var targetScale:Float = 1.0;

    public var alpha:Float = 0.0;
    public var scale:Float = 1.0;

    public var bg:MoonSprite;
    public var icon:PixelIcon;
    public var nameText:ScrollingText;
    public var scoreText:FlxText;

    public function new()
    {
        bg = new MoonSprite().makeGraphic(416, 84, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRoundRect(bg, 0, 0, bg.width, bg.height, 12, 12, 0xFF1d1d1d);
        bg.antialiasing = true;
        bg.active = false;

        icon = new PixelIcon(-9999, -9999, 'bf');

        nameText = new ScrollingText(-9999, -9999, TEXT_W, '', 22);
        nameText.textField.font = Paths.font('phantomuff/full.ttf');
        nameText.antialiasing = true;
        nameText.alpha = 0;

        scoreText = new FlxText(-9999, -9999, TEXT_W, '', 13);
        scoreText.font = Paths.font('phantomuff/full.ttf');
        scoreText.antialiasing = true;
        scoreText.color = 0xFFAAAAAA;
        scoreText.visible = scoreText.active = false;
        scoreText.alpha = 0.0001;
    }

    public function loadEntry(entry:SongBase, charName:String, selected:Bool, scoreVal:Int = -1, accPct:Int = -1):Void
    {
        if (icon.character != charName)
            icon.character = charName;

        final displayName:String = Reflect.hasField(entry, "displayName") 
            ? Reflect.field(entry, "displayName") 
            : entry.song;
        nameText.setText(displayName.toUpperCase());

        scoreText.visible = selected;
        if (selected)
        {
            scoreText.text = ((scoreVal >= 0) ? '${MoonUtils.formatNumber(scoreVal)} SCORE' : '-- SCORE')
            + '\n' + ((accPct >= 0) ? '${accPct}% ACCURACY' : '--% ACCURACY');
        }
    }

    public function lerpVisuals(elapsed:Float):Void
    {
        final t = elapsed * 14;
        alpha = FlxMath.lerp(alpha, targetAlpha, t);
        scale = FlxMath.lerp(scale, targetScale, t);
    }

    public function applyPositions():Void
    {
        icon.scale.set(scale + 1, scale + 1);
        icon.setPosition(x, y);
        icon.alpha = alpha;
        icon.updateHitbox();

        final textX = x + 96 * scale + TEXT_GAP;

        nameText.scale.set(scale, scale);
        nameText.setPosition(textX, y + (icon.height * scale - 22 * scale) * 0.5 - 7 * scale);
        nameText.alpha = alpha;

        scoreText.scale.set(scale, scale);
        scoreText.setPosition(textX, nameText.y + 24 * scale);
        scoreText.alpha = alpha * 0.85;

        bg.scale.set(scale, scale);
        bg.updateHitbox();
        bg.setPosition(icon.x + 11, (nameText.y + nameText.height / 2 - bg.height / 2) + 8);
    }

    /**
     * Snap to targets immediately.
     */
    public function snapToTarget():Void
    {
        alpha = targetAlpha;
        scale = targetScale;
    }

    /**
     * Hides all members without destroying anything. 
     */
    public function hide():Void
    {
        icon.alpha = nameText.alpha = scoreText.alpha = 0.0001;
        scoreText.visible = false;
    }
}