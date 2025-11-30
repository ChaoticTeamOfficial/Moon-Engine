package moon.toolkit.level_editor;

import flixel.addons.display.shapes.FlxShapeCircle;
import moon.game.obj.notes.*;

class Strums extends FlxSpriteGroup
{
	var arrows:Array<MoonSprite> = [];
	public function new(x:Float = 0, y:Float = 0, color:FlxColor = FlxColor.RED)
	{
		super(x, y);

		var line = new MoonSprite().makeGraphic(Std.int(LevelEditor.LANE_WIDTH * (LevelEditor.NUM_LANES + 1)), 2, color);
		add(line);

		var circle = new FlxShapeCircle(0, 0, 8, {thickness: 4, color: color}, color);
		add(circle);
		circle.antialiasing = false;
		circle.y = line.y + line.height / 2 - circle.height / 2;
		circle.x += line.width;

		line.active = circle.active = false;

		for(a in 0...LevelEditor.chart.content.meta.lanes.length)
        {
        	//trace(a);
            for(i in 0...4)
            {
                var ok = new MoonSprite().loadGraphic(Paths.image('toolkit/level-editor/strumline'), true, 32, 32);
                ok.animation.add('a', [i], 1, true);
                ok.animation.play('a');
                add(ok);

                ok.setGraphicSize(LevelEditor.LANE_WIDTH, LevelEditor.LANE_HEIGHT);
                ok.antialiasing = false;
                ok.updateHitbox();

                ok.x = x + ((a * 4 + i) * LevelEditor.LANE_WIDTH);

                final colors = [0xFF7f16ff, 0xFF37a5ff, 0xFF61d041, 0xFFff3f3f];
                ok.color = colors[i % colors.length];
                ok.alpha = 0.0001;
                ok.blend = ADD;

                ok.ID = i;
                ok.strID = LevelEditor.chart.content.meta.lanes[a];
                arrows.push(ok);
                //trace('${chart.content.meta.lanes[a]} & $i', "DEBUG");
            }
        }
	}

	public function onHit(n:Note)
	{
		for(i in 0...arrows.length)
        {
        	final s = arrows[i];
            if (s.strID.toLowerCase() == n.lane.toLowerCase() && s.ID == n.direction)
            {
                s.alpha = 1;
                s.scale.set(1.3, 1.3);
                //trace('${s.strID.toLowerCase()} to ${n.lane.toLowerCase()}', "DEBUG");
            }
        }
	}

	override function update(elapsed)
	{
		super.update(elapsed);

		for(s in arrows)
		{
			s.scale.x = s.scale.y = FlxMath.lerp(s.scale.x, 1, elapsed * 5);
			s.alpha = FlxMath.lerp(s.alpha, 0.00001, elapsed * 4);
		}
	}
}
