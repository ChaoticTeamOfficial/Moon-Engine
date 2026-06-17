package;

import sys.io.File;

/**
 * A script which executes before the game is built.
 * Originally Made by Funkin' Crew.
 */
class Prebuild
{
    static inline final BUILD_TIME_FILE:String = '.build_time';

    public static var compileMsgs:Array<String> = [
        "We love legacy mods. VS Hex my beloved <3...",
        "Did you know that the chart editor is awesome because Luna is also awesome?",
        "If you ever see a moon walking on the streets, remember to scream MOON ENGINE!!!",
        "Luna mix is cool",
        "Mano mix is cool",
        "Mad Virus Attack is pawesome",
        "Cool Pokemon Mod is cool",
        "Vee Mix is the coolest",
        "just add an random useless fact idk i cant think of anything :sob: -- zzshu",
        "The evoker can change the color of the wool of the blue sheeps",
        "Easier to assimilate than explain, anyway.",
        "A mod we gave to bug and beast as they had never dreamed",
        "Sou gay",
        "yo nene"
    ];

    static function main():Void
    {
        saveBuildTime();
        traceMessage();
    }

    public static function traceMessage():Void
    {
        final message = compileMsgs[Std.random(compileMsgs.length)];
        Sys.println('\x1b[36m[INFO] Today\'s message: $message\x1b[0m');
    }

    static function saveBuildTime():Void
    {
        var fo:sys.io.FileOutput = File.write(BUILD_TIME_FILE);
        var now:Float = Sys.time();
        fo.writeDouble(now);
        fo.close();
    }
}