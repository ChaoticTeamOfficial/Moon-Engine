package moon.menus;

using StringTools;

class PlaylistMode extends FlxSubState
{
	var songList:Array<SongBase> = [];
	var bg:MoonSprite;
	var upperBG:MoonSprite;
	var icon:MoonSprite;
	var mode:FlxText;
	var sideImg:MoonSprite;
	var isClosing:Bool = false;

	public function new()
	{
		super();

		for (song in Paths.readDir('songs/'))
		{
			for (mix in Paths.readDir('songs/$song/'))
			{
				if (mix == 'events' || !Paths.exists('songs/$song/$mix/', null))
					continue;

				for (chart in Paths.readDir('songs/$song/$mix/', ['.json'], true))
				{
					if (chart.startsWith('chart-'))
					{
						final diff = chart.substr(6);
						songList.push({
							song: song,
							mix: mix,
							difficulty: diff
						});
					}
				}
			}
		}

		songList.sort(function(a, b)
		{
			final aL = a.song.toLowerCase();
			final bL = b.song.toLowerCase();
			return (aL < bL) ? -1 : (aL > bL) ? 1 : 0;
		});

		bg = new MoonSprite().loadGraphic(Paths.image('menus/main/menuDesat'));
		add(bg);
		bg.color = 0xFFd5ddc4;
		bg.x -= bg.width;
		FlxTween.tween(bg, {x: -332}, 0.8, {ease: FlxEase.expoOut});
		bg.shader = new InvertColor();

		upperBG = new MoonSprite().makeGraphic(FlxG.width, 78, 0xFF131313);
		add(upperBG);
		upperBG.alpha = 0.00001;
		upperBG.y -= upperBG.height;
		FlxTween.tween(upperBG, {y: 0, alpha: 1}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.4});

		icon = new MoonSprite(32, -90);
		icon.frames = Tilemap.getAtlasFrames("mainUI");
		icon.frame = Tilemap.getFrame('playlistMode', 'mainUI');
		icon.alpha = 0.0001;
		add(icon);
		icon.antialiasing = false;
		FlxTween.tween(icon, {y: 16, alpha: 1}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.8});

		mode = new FlxText(96);
		mode.setFormat(Paths.font('phantomuff/difficulty.ttf'), 40, CENTER);
		mode.text = 'PLAYLIST MODE';
		add(mode);
		mode.alpha = 0.0001;
		mode.y -= mode.height;
		mode.antialiasing = true;
		FlxTween.tween(mode, {y: 16, alpha: 1}, 0.7, {ease: FlxEase.expoOut, startDelay: 0.65});

		sideImg = new MoonSprite().makeGraphic(541, FlxG.height, 0xFF040404);
		add(sideImg);
		sideImg.x = FlxG.width + sideImg.width + 32;
		sideImg.skew.x = -5;
		FlxTween.tween(sideImg, {x: FlxG.width - sideImg.width + 32}, 1, {ease: FlxEase.expoOut});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!isClosing && FlxG.keys.justPressed.ESCAPE)
		{
			isClosing = true;
			FlxTween.tween(bg, {x: -bg.width}, 0.8, {ease: FlxEase.expoIn});
			FlxTween.tween(upperBG, {y: -upperBG.height, alpha: 0.00001}, 0.7, {ease: FlxEase.expoIn});
			FlxTween.tween(icon, {y: -90, alpha: 0.0001}, 0.7, {ease: FlxEase.expoIn});
			FlxTween.tween(mode, {y: -mode.height, alpha: 0.0001}, 0.7, {ease: FlxEase.expoIn});
			FlxTween.tween(sideImg, {x: FlxG.width + sideImg.width + 32}, 1, {
				ease: FlxEase.expoIn,
				onComplete: function(twn:FlxTween)
				{
					close();
				}
			});
		}
	}
}
