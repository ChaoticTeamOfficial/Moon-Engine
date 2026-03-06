package moon.ui;

import hxvlc.flixel.FlxVideoSprite;

class VideoSubState extends FlxSubState
{
    var video:FlxVideoSprite;

    public function new(?params:VideoParams)
    {
        super();
        //TODO: Finish and document this class.

        this.camera = params.camera ?? FlxG.camera;

        //if(params.path == null) params.path = Paths.mp4('videos/titleVideos/boyfriendEverywhere');
        var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(bg);

        video = new FlxVideoSprite(0, 0);
        video.antialiasing = true;
        video.visible = false;

        // why ts so laggy on my trashy pc,...., augh

        video.bitmap.onFormatSetup.add(() ->
        {
            if (video.bitmap != null && video.bitmap.bitmapData != null)
            {
                video.setGraphicSize(FlxG.width, FlxG.height);
                video.updateHitbox();
                video.screenCenter();
            }
        });

        video.bitmap.onEndReached.add(() ->{ 
            video.bitmap.dispose(); 
            close(); 
            if(params.onComplete != null) params.onComplete(); 
        });

        video.bitmap.onPlaying.add(() -> if(params.onStart != null) params.onStart());

        add(video);

        if (video.load(params.path))
        {
        	video.visible = true;
        	video.play();
		};

        if(params.infoText != null)
        {
            var txt = new FlxText();
            txt.setFormat(Paths.font('DynaPuff.ttf'), 18);
            txt.antialiasing = true;
            txt.text = params.infoText;
            txt.blend = DIFFERENCE;
            add(txt);
            txt.alpha = 0.00001;
            FlxTween.tween(txt, {alpha: 0.7}, 1);

            txt.setPosition(16, FlxG.height - txt.height - 16);
        }
    }
}

typedef VideoParams = {
    var path:String;
    var ?onStart:Void->Void;
    var ?onComplete:Void->Void;
    var ?camera:FlxCamera;
    var ?uiType:VideoUIType;
    var ?infoText:String;
};

enum abstract VideoUIType(String) {
    var DEFAULT = 'default';
}