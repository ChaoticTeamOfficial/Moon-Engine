package moon.menus;

import flixel.util.FlxGradient;
import moon.game.submenus.PauseScreen;
import moon.game.PlayState;
import moon.menus.obj.settings.*;
import moon.dependency.user.MoonSettings.Setting;

class Settings extends FlxSubState
{
    //TODO: doccument thisssss
    static var curSelected:Int = 0;
    var yPos:Float = 0;
    
    var optionFollower:MoonSprite;
    var navOptions:Array<OptionObject> = new Array<OptionObject>();
    var optionsContainer:FlxSpriteGroup = new FlxSpriteGroup();
    //var optionDesc:FlxText;
    var info:OptionInfo;

    public function new(skipTransition:Bool = false)
    {
        super();
        
        if(PlayState.instance != null) this.camera = PlayState.instance.camALT;

        var back = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        back.blend = HARDLIGHT;
        back.alpha = 0.0001;
        add(back);
        FlxTween.tween(back, {alpha: 0.6}, (skipTransition) ? 0.0000001 : 0.8);

        var backGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00000000, 0xFF111111], 1, 180);
        backGradient.alpha = 0;
        add(backGradient);

        info = new OptionInfo();
        info.screenCenter(Y);
        info.x = FlxG.width / 2 + 64;
        info.y -= 32;
        FlxTween.tween(info, {y: info.y + 32}, 2, {type: PINGPONG, ease: FlxEase.quadInOut});
        add(info);

        if(!skipTransition)
        {
            info.scale.set(3, 0);
            FlxTween.tween(info.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.backOut});
        }
        
        optionFollower = new MoonSprite(20, 1000).makeGraphic(OptionObject.separationWidth + 16, 32, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRoundRect(optionFollower, 0, 0, optionFollower.width, optionFollower.height, 8, 8, FlxColor.WHITE);
        add(optionFollower);
        FlxTween.tween(optionFollower, {alpha: 0.5}, 5, {type: PINGPONG, ease: FlxEase.quadIn});

        add(optionsContainer);

        var sttDisplay = new FlxText(32, yPos);
        sttDisplay.text = 'SETTINGS';
        sttDisplay.setFormat(Paths.font('phantomuff/difficulty.ttf'), 54, CENTER);
        sttDisplay.antialiasing = true;
        optionsContainer.add(sttDisplay);
        yPos += sttDisplay.height + 16;

        var separator = new MoonSprite(32, yPos).makeGraphic(OptionObject.separationWidth, 2, FlxColor.WHITE);
        optionsContainer.add(separator);
        yPos += separator.height + 16;

        for(i in 0...MoonSettings.categoryOrder.length)
            createCategory(MoonSettings.categoryOrder[i]);

        //optionsContainer.y += 1000;
        if(!skipTransition)
        {
            optionsContainer.alpha = 0.00001;
            FlxTween.tween(optionsContainer, {alpha: 1}, 0.5);
        }
        
        /*optionDesc = new FlxText();
        optionDesc.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, RIGHT);
        optionDesc.text = '';
        optionDesc.antialiasing = false;
        optionDesc.alpha = 0;
        add(optionDesc);
        optionDesc.y = (FlxG.height - optionDesc.height) - 12;*/
        
        FlxTween.tween(backGradient, {alpha: 1}, (skipTransition) ? 0.0000001 : 1);
        
        //var info = new FlxText(-600);
        //info.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.GRAY, LEFT);
        //info.text = '[ESC] - Leave.\n[TAB] - Go to Next Category.';
        //info.antialiasing = false;
        //add(info);
        
        //info.y = (FlxG.height - info.height) - 12;
        //FlxTween.tween(info, {x: 12}, 1, {ease: FlxEase.circOut});
        changeSelection(0);

        final cur = navOptions[curSelected];
        final targetY:Float = FlxG.height / 2 - (cur.y + cur.height / 2 - optionsContainer.y);
        optionsContainer.y = targetY;
        optionFollower.y = cur.y;

        if(!skipTransition)Paths.playSFX('menus/settings/settingsEnter.wav');
    }

    public function createCategory(category:String):Void
    {
        final separation = 16;
        var categoryTxt:FlxText = new FlxText(32, yPos, -1, category.toUpperCase());
        categoryTxt.setFormat(Paths.font("phantomuff/difficulty.ttf"), 32, FlxColor.WHITE, CENTER);
        categoryTxt.antialiasing = true;
        categoryTxt.alpha = 0.7;
        optionsContainer.add(categoryTxt);
    
        yPos += categoryTxt.height + separation;
    
        final settings:Array<Setting> = MoonSettings.categories.get(category);
        for (i in 0...settings.length)
        {
            var option:OptionObject = new OptionObject(32, yPos, settings[i], category);
            //option.screenCenter(X);
            optionsContainer.add(option);
            option.camera = this.camera;
            navOptions.push(option);
            yPos += option.height + separation;
        }
    
        yPos += separation + 32;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // change selection
        if(MoonInput.justPressed(UI_UP)) changeSelection(-1);
        else if(MoonInput.justPressed(UI_DOWN)) changeSelection(1);
        else if (FlxG.keys.justPressed.TAB) changeCategory();
        
        if (FlxG.mouse.wheel != 0)
            changeSelection(-FlxG.mouse.wheel);

        // center current selected option
        final cur = navOptions[curSelected];
        final targetY:Float = FlxG.height / 2 - (cur.y + cur.height / 2 - optionsContainer.y);
        optionsContainer.y = FlxMath.lerp(optionsContainer.y, targetY, elapsed * 13);
        optionFollower.y = cur.y - 5;

        //exit
        if(MoonInput.justPressed(BACK))
        {
            Paths.playSFX('menus/settings/settingsLeave.wav');
            close();
            if(PlayState.instance != null) PlayState.instance.openSubState(new PauseScreen(PlayState.instance.camALT));
        }
    }

    function changeSelection(change:Int):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, navOptions.length - 1);

        if(change != 0)
            Paths.playSFX('menus/settings/settingsSelection.wav');

        //optionDesc.text = navOptions[curSelected].setting.description;
        //optionDesc.x = (FlxG.width - optionDesc.width) - 12;

        for (i in 0...navOptions.length)
            navOptions[i].selected = (i == curSelected);

        info.updateInfo(navOptions[curSelected].setting);
    }

    private function changeCategory():Void
    {
        final curCat = navOptions[curSelected].category;
        final curIndex = MoonSettings.categoryOrder.indexOf(curCat);
        final nextCat = (curIndex + 1) % MoonSettings.categoryOrder.length;

        for (i in 0...navOptions.length)
        {
            if (navOptions[i].category == MoonSettings.categoryOrder[nextCat])
            {
                curSelected = i;
                changeSelection(0);
                Paths.playSFX('menus/settings/settingsSectionChange.wav');
                return;
            }
        }
    }
}
