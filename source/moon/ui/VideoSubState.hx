package moon.ui;

import hxvlc.flixel.FlxVideoSprite;

class VideoSubState extends FlxSubState
{
    var video:FlxVideoSprite;

    public function new(?path:String, ?camera:FlxCamera)
    {
        super();
        //TODO: Finish and document this class.

        this.camera = camera ?? FlxG.camera;

        if(path == null) path = 'videos/titleVideos/boyfriendEverywhere';

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

        video.bitmap.onEndReached.add(() ->
        {
            close();
        });

        add(video);

        if (video.load(Paths.mp4(path)))
            new FlxTimer().start(0.001, _ -> {
            	video.visible = true;
            	video.play();
    		});
    }
}