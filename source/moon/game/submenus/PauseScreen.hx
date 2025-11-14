package moon.game.submenus;

import moon.menus.Settings;
import flixel.effects.FlxFlicker;
import flixel.util.FlxTimer;
import moon.global_obj.PixelIcon;
import moon.game.obj.PlayField;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BlendMode;
import flixel.util.FlxGradient;

/**
 * Ahh yes the pause menu, this code is kinda shitty btw.
 */
class PauseScreen extends FlxSubState
{
    private final DEFAULT_ITEMS:Array<String> = [
        'resume', 'restart', 'settings', 'accessibility settings', 'exit'
    ];

    private final ACCESSIBILITY_ITEMS:Array<String> = [
        'botplay', 'practice mode', 'change difficulty', 'back'
    ];

    private var currentArray:Array<String> = [];
    private var slideOutItems:Array<Dynamic> = [];

    private final thisFont:String = 'vcr.ttf';

    public var curSelected:Int = 0;

    public var canMove:Bool;

    private var paused:FlxSprite;
    private var backGradient:FlxSprite;
    private var back:FlxSprite;

    public var displayIcon:PixelIcon;

    public var pauseItems:FlxTypedGroup<FlxText> = new FlxTypedGroup<FlxText>();
    public var selector:FlxText = new FlxText();
    
    private var pf:PlayField;
    var game(get, never):PlayState;

    public function new(camera:FlxCamera)
    {
        super();
        canMove = true;
        this.camera = camera;
        pf = game.playField; // NAO NAO É UM PRATO FEITO É UM PLAYFIELD!!!!

        // < BACKGROUND SETUP > //
        backGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00000000, 0xFF001A83], 1, 180);
        backGradient.alpha = 0;
        add(backGradient);
        FlxTween.tween(backGradient, {alpha: 0.7}, pf.conductor.crochet / 1000);

        back = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        back.alpha = 0;
        back.blend = BlendMode.DIFFERENCE;
        add(back);
        FlxTween.tween(back, {alpha: 0.5}, pf.conductor.crochet / 1000);

        paused = new FlxSprite(-800, 45).loadGraphic(Paths.image('menus/pause/pause'));
        paused.scale.set(2, 2);
        paused.antialiasing = false;
        paused.updateHitbox();
        add(paused);
        slideOutItems.push(paused);
        FlxTween.tween(paused, {x: 55}, pf.conductor.crochet / 1000, {ease: FlxEase.expoOut});

        // < SELECTABLE ITEMS SETUP > //
        regenItems(DEFAULT_ITEMS);
        add(pauseItems);

        selector.text = '>>';
        selector.setFormat(Paths.font(thisFont), 32, FlxColor.WHITE, LEFT);
        add(selector);

        // < METADATA TEXT SETUP > //
        //(chart content)
        final cc = pf.chart.content;
        var metadata = new FlxText();
        metadata.text = '${cc.meta.artist} - ${pf.chart.content.meta.displayName}';
        metadata.setFormat(Paths.font(thisFont), 20, FlxColor.WHITE, LEFT);
        metadata.alpha = 0;
        add(metadata);

        slideOutItems.push(metadata);

        metadata.textField.antiAliasType = ADVANCED;
        metadata.textField.sharpness = 400;
        metadata.antialiasing = false;
        metadata.setPosition(130, (FlxG.height - metadata.height) - 64);

        var cmetadata = new FlxText();
        cmetadata.text = 'Chart: ${cc.meta.charter}';
        cmetadata.setFormat(Paths.font(thisFont), metadata.size, FlxColor.WHITE, LEFT);
        cmetadata.alpha = 0;
        cmetadata.textField.antiAliasType = metadata.textField.antiAliasType;
        cmetadata.textField.sharpness = metadata.textField.sharpness;
        add(cmetadata);

        slideOutItems.push(cmetadata);

        cmetadata.antialiasing = false;
        cmetadata.setPosition(metadata.x, (metadata.y + cmetadata.height));

        //! FIX TODO!!!
        //! FOR SOME REASON WHEN RE-ENTERING THE MENU THE ICON ISNT LOADED.
        //! MAYBE COULD BE SOMETHING RELATED TO HOW IT'S HANDLED.
        displayIcon = new PixelIcon(cc.meta.opponents[0]);
        displayIcon.alpha = 0;
        add(displayIcon);

        slideOutItems.push(displayIcon);
        
        displayIcon.setPosition((metadata.x - displayIcon.width) - 16, (metadata.y - (displayIcon.height / 2)) + 16);

        final wawa = [metadata, displayIcon, cmetadata];
        for(i in 0...wawa.length)
            FlxTween.tween(wawa[i], {x: wawa[i].x + 30, alpha: 1}, pf.conductor.crochet / 2000, {ease: FlxEase.quadOut, startDelay: 0.1 * i});

        Paths.playSFX('game/pause/onPause');
    }

    override public function update(elapsed:Float)
    {
        if(MoonInput.justPressed(UI_DOWN) && canMove) changeSelection(1);
        if(MoonInput.justPressed(UI_UP) && canMove) changeSelection(-1);

        if(MoonInput.justPressed(BACK) && canMove)
        {
            if(currentArray != DEFAULT_ITEMS) regenItems(DEFAULT_ITEMS);
            else prepareToClose(true);
        }

        if(MoonInput.justPressed(ACCEPT) && canMove)
        {
            switch(pauseItems.members[curSelected].text.toLowerCase())
            {
                case 'resume': 
                    prepareToClose();
                    Paths.playSFX('ui/confirmMenu');
                case 'restart': 
                    //TODO: This isn't actually visible due to how fast it resets lol
                    // so uhhh... get it to be shown!!
                    paused.loadGraphic(Paths.image('menus/pause/reset'));
                    pf.restartSong();
                    close();
                case 'settings': 
                    close();
                    game.openSubState(new Settings(true));
                case 'accessibility settings': regenItems(ACCESSIBILITY_ITEMS);
                case 'back': regenItems(DEFAULT_ITEMS);
            }
        }

        super.update(elapsed);

        if(pauseItems.members.length > 0)
        {
            final item = pauseItems.members[curSelected];
            selector.setPosition(FlxMath.lerp(selector.x, item.x - 42, 0.2), FlxMath.lerp(selector.y, item.y, 0.2));
        }

        for (it in pauseItems.members)
            if(canMove) it.x = FlxMath.lerp(it.x, 120, elapsed * 12);
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, pauseItems.members.length - 1);
        pauseItems.members[curSelected].x += 10;
        Paths.playSFX('ui/scrollMenu');

        selector.text = switch(pauseItems.members[curSelected].text.toLowerCase())
        {
            case 'exit' | 'back': '<<';
            default: '>>';
        };
    }

    public function regenItems(items:Array<String>)
    {
        currentArray = items;
        pauseItems.clear();
        
        for (i in 0...items.length)
        {
            final item = items[i];
            pauseItems.recycle(FlxText, function():FlxText
            {
                var hi = new FlxText(-500, 250 + (45 * i), 500, item.toUpperCase());
                hi.setFormat(Paths.font(thisFont), 32, FlxColor.WHITE, LEFT);
                hi.alpha = 0;
                hi.textField.antiAliasType = ADVANCED;
                hi.textField.sharpness = 400;
                FlxTween.tween(hi, {alpha: 1}, pf.conductor.crochet / 1500, {ease: FlxEase.quadOut, startDelay: 0.1 * i});
                return hi;
            });
        }

        selector.setPosition(-100, pauseItems.members[0].y);
        changeSelection(0);
    }

    var counter:Int = 3;

    final txtDisplay = ['0', '1', '2', '3'];
    final colors = [0xFF00FF00, 0xFFFFEE00, 0xFFFF8C00, 0xFFE50000];
    public function prepareToClose(?pressedEsc:Bool = false)
    {
        for (c in pauseItems.members) slideOutItems.push(c);
        canMove = false;

        paused.loadGraphic(Paths.image('menus/pause/resume'));
        displayIcon.playAnim('select', true);

        if(!pressedEsc)FlxFlicker.flicker(pauseItems.members[curSelected], 1, 0.05, true);

        // COUNTDOWN TEXT
        var wah = new FlxText(0, 0, 500, '');
        wah.setFormat(Paths.font(thisFont), 78, FlxColor.WHITE, CENTER);
        wah.alpha = 0;
        wah.textField.antiAliasType = ADVANCED;
        //wah.textField.sharpness = 400;
        add(wah);

        new FlxTimer().start(pf.conductor.crochet / 1000 * 2, function(_)
        {
            for (bg in [backGradient, back]) FlxTween.tween(bg, {alpha: 0}, pf.conductor.crochet / 1000 * 2);
            for (item in slideOutItems) FlxTween.tween(item, {x: item.x - 700}, pf.conductor.crochet / 1000, {ease: FlxEase.expoIn});
        });

        // - Starts the lil countdown.
        new FlxTimer().start(pf.conductor.crochet / 1000, function(_)
        {
            if(counter == -1)
            {
                pf.playback.state = PLAY;
                pf.playback.resync();
                close();
            }
            else
            {
                Paths.playSFX((counter == 0) ? 'game/pause/pausecountdown-end' : 'game/pause/pausecountdown-normal');
                wah.color = colors[counter];
                wah.text = txtDisplay[counter];
                wah.alpha = 1;
                wah.size += 16;
                wah.updateHitbox();
                wah.screenCenter();
            }
            counter--;
        }, 5);
    }

    override public function close()
    {
        super.close();
    }

    @:noCompletion function get_game():PlayState
        return PlayState.instance;
}