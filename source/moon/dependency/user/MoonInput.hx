package moon.dependency.user;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;

using haxe.EnumTools;

enum MoonKeys
{
    LEFT;
    DOWN;
    UP;
    RIGHT;
    RESET;
    UI_LEFT;
    UI_DOWN;
    UI_UP;
    UI_RIGHT;
    ACCEPT;
    BACK;
    PAUSE;
   
    NONE;
}

class MoonInput
{
    public static var binds:Map<String, Array<Array<Dynamic>>> =
    [
        // Gameplay Keybinds
        'LEFT' => [
         [FlxKey.A, FlxKey.LEFT],
         [FlxPad.LEFT_TRIGGER, FlxPad.DPAD_LEFT]
        ],
        'DOWN' => [
         [FlxKey.S, FlxKey.DOWN],
         [FlxPad.LEFT_SHOULDER, FlxPad.DPAD_DOWN]
        ],
        'UP' => [
         [FlxKey.W, FlxKey.UP],
         [FlxPad.RIGHT_SHOULDER, FlxPad.DPAD_UP]
        ],
        'RIGHT' => [
         [FlxKey.D, FlxKey.RIGHT],
         [FlxPad.RIGHT_TRIGGER, FlxPad.DPAD_RIGHT]
        ],
        'RESET' => [[FlxKey.R], [FlxPad.BACK]],

        // UI Keybinds
        'UI_LEFT' => [
         [FlxKey.A, FlxKey.LEFT],
         [FlxPad.LEFT_STICK_DIGITAL_LEFT, FlxPad.DPAD_LEFT]
        ],
        'UI_DOWN' => [
         [FlxKey.S, FlxKey.DOWN],
         [FlxPad.LEFT_STICK_DIGITAL_DOWN, FlxPad.DPAD_DOWN]
        ],
        'UI_UP' => [
         [FlxKey.W, FlxKey.UP],
         [FlxPad.LEFT_STICK_DIGITAL_UP, FlxPad.DPAD_UP]
        ],
        'UI_RIGHT' => [
         [FlxKey.D, FlxKey.RIGHT],
         [FlxPad.LEFT_STICK_DIGITAL_RIGHT, FlxPad.DPAD_RIGHT]
        ],

        // Extra Keybinds
        'ACCEPT' => [[FlxKey.SPACE, FlxKey.ENTER], [FlxPad.A, FlxPad.START]],
        'BACK' => [[FlxKey.BACKSPACE, FlxKey.ESCAPE], [FlxPad.B]],
        'PAUSE' => [[FlxKey.ENTER, FlxKey.ESCAPE], [FlxPad.START]]
    ];

    public static function checkBind(rawBind:MoonKeys, inputState:FlxInputState):Bool
    {
        if(Global.allowInputs)
        {
            final bind = Std.string(rawBind);
            if(!binds.exists(bind))
                return false;

            // for keyboards
            final thisBind:Array<FlxKey> = cast binds.get(bind)[0];
            for(key in thisBind)
                if(FlxG.keys.checkStatus(key, inputState))
                    return true;

            // for controllers
            final thisControllerBind:Array<FlxPad> = cast binds.get(bind)[1];
            if(FlxG.gamepads.lastActive != null)
                for (key in thisControllerBind)
                    if(FlxG.gamepads.lastActive.checkStatus(key, inputState))
                        return true;
        }
        return false;
    }

    public static function loadControls():Void
    {
        if ((MoonSettings.save.data.binds != null) && (Lambda.count(MoonSettings.save.data.binds) == Lambda.count(binds)))
            binds = cast MoonSettings.save.data.binds;
        else
            trace("Control settings do not match or are missing. Loading defaults.", "WARNING");
        saveControls();
    }

    public static function saveControls():Void
    {
        MoonSettings.save.data.binds = binds;
        MoonSettings.saveSettings();
    }

    public static function justPressed(bind:MoonKeys):Bool
        return checkBind(bind, JUST_PRESSED);

    public static function pressed(bind:MoonKeys):Bool
        return checkBind(bind, PRESSED);
        
    public static function released(bind:MoonKeys):Bool
        return checkBind(bind, JUST_RELEASED);
}