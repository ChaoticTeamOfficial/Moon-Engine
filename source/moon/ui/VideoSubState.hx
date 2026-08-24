package moon.ui;

#if cpp
import hxvlc.flixel.FlxVideoSprite;

class VideoSubState extends FlxSubState
{
	var params:VideoParams;
	var video:FlxVideoSprite;
	var ui:DefaultVideoUI = new DefaultVideoUI();

	public function new(?params:VideoParams)
	{
		super();
		// TODO: Finish and document this class.

		this.params = params;

		this.camera = params?.camera ?? FlxG.camera;

		// if(params.path == null) params.path = Paths.mp4('videos/titleVideos/boyfriendEverywhere');
		// var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		// add(bg);
		// actually lemme just
		bgColor = FlxColor.BLACK;

		video = new FlxVideoSprite(0, 0);
		video.antialiasing = true;
		video.visible = false;

		// why ts so laggy on my trashy pc,...., augh
		// note: it actually doesn't now wow

		params.canPause ??= true;

		video.bitmap.onFormatSetup.add(() ->
		{
			if (video.bitmap != null && video.bitmap.bitmapData != null)
			{
				video.setGraphicSize(FlxG.width, FlxG.height);
				video.updateHitbox();
				video.screenCenter();
			}
		});

		video.bitmap.onEndReached.add(() ->
		{
			video.bitmap.dispose();
			close();
			if (params.onComplete != null) params.onComplete();
		});

		add(video);

		if (video.load(params.path))
		{
			video.visible = true;
			video.play();
			if (params.onStart != null) params.onStart();
		};

		if (params.infoText != null)
		{
			var txt = new FlxText();
			txt.setFormat(Paths.font('DynaPuff.ttf'), 18);
			txt.antialiasing = true;
			txt.text = params.infoText;
			txt.blend = DIFFERENCE;
			add(txt);
			txt.alpha = 0.00001;
			FlxTween.tween(txt, {
				alpha: 0.7
			}, 1);

			txt.setPosition(16, FlxG.height - txt.height - 16);
		}

		ui.camera = this.camera;
		add(ui);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!params.canPause) return;

		if (MoonInput.justPressed(PAUSE) && !ui.paused)
		{
			ui.paused = true;
			video.pause();
		}
		else if (MoonInput.justPressed(BACK) && ui.paused)
		{
			ui.paused = false;
			video.play();
		}
	}
}
#else
class VideoSubState extends FlxSubState
{
	public function new(?params:VideoParams)
	{
		super();
		trace("[VIDEO] VIDEOS ARE ONLY SUPPORTED ON C++ TARGETS!", "WARNING");

		if (params.onComplete != null) params.onComplete();
		close();
	}
}
#end

typedef VideoParams =
{
	var path:String;
	var ?onStart:Void->Void;
	var ?onComplete:Void->Void;
	var ?camera:FlxCamera;
	var ?canPause:Bool;
	var ?infoText:String;
};
