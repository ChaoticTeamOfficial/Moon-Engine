import flixel.FlxG;
import moon.global_obj.TextScroll;
import moon.dependency.MoonSprite;
import flixel.text.FlxText;
import flixel.addons.display.FlxBackdrop;

function onCreate()
{
    var test = new MoonSprite();
    test.makeGraphic(600, FlxG.height, 0xFFffd863);
    behindBG.add(test);
    
    // peak....	
	//var checker = new FlxBackdrop(Paths.image('oi'));
	///checker.alpha = 0.69;
	//checker.velocity.x = -100;
	//checker.velocity.y = -49;
	//behindBG.add(checker);

    //Scrolling texts
    final texts = [
		{
            text: "OH SHIT OH SHIT",
            size: 32, color: 0xffffffff, speed: 2,
            bold: true, offsetY: 0
        },
        {
            text: "I'M SCARED ACTUALLY LOLOLOL",
            size: 32, color: 0xFFfff383, speed: 5,
            bold: true, offsetY: 0
        },
        {
            text: "BOYFRIEND",
            size: 64, color: 0xFFff9963, speed: -3,
            bold: false, offsetY: 0
        },
        {
            text: "PROTECT YO NUTS",
            size: 32, color: 0xffffffff, speed: 2,
            bold: true, offsetY: 25
        },
        {
            text: "FUCKASS",
            size: 64, color: 0xFFff9963, speed: -3,
            bold: false, offsetY: 30
        },
        {
            text: "HOT BLOODED IN MORE WAYS THAN ONE",
            size: 32, color: 0xFFfff383, speed: 5,
            bold: true, offsetY: 55
        },
        {
            text: "FUCKASS",
            size: 64, color: 0xFFff9963, speed: -3,
            bold: false, offsetY: 85
        },
    ];

    var txtBack = new MoonSprite(0, 418);
    txtBack.makeGraphic(900, 70, 0xFFfed100);
    behindBG.add(txtBack);

    for(i in 0...texts.length)
    {
        final dt = texts[i];
        var textii = new TextScroll(0, 105 + (40 * i) + dt.offsetY, dt.text, 200, dt.size, dt.bold);
        textii.speed = dt.speed;
        textii.color = dt.color;
        behindBG.add(textii);
    }
}