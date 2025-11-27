package;

import sys.io.File;

/**
 * A script which executes before the game is built.
 * Originally Made by Funkin' Crew.
 */
class Prebuild
{
    static inline final BUILD_TIME_FILE:String = '.build_time';

    public static var motivationMsgs:Array<String> = [
        "Don't give up hope, no matter what people say.",
		"I know you can make it better than it ever was.",
        "Hmm...",
        "I sure do love waiting!",
        "Some burguers would be nice rn...",
        "Chicken nuggiess,,.,",
        "Deltarune Tomorrow",
        "(Did you know?) Spirits face was inspired by Tom Fulps face. (found this on reddit lolol)",
        "A mimir...",
        "Mano Mix is cool",
        "Luna Mix is cool",
        "Oh, Okay! let's go!",
        "Don't forget to drink some water!",
        "You're almost there!",
        "Why do we brainstorm with ideas only when we're not working?",
        "Don't get any ideas. I think both of you are REALLY fucking ugly. /j",
        "Go pico chud",
        "Yo! Really think so?",
        "GWUUOOOOOOOOOOOOOOO",
        "Eu olho pra esse aqui a coisa que me vem na cabeça é *pum bwananan tumtumu*",
        "FWU FWUU PSHH-",
        "deodorant",
        "psst",
        "Okay!",
        "Tu turu tu taa",
        "Help I don't know what I'm writing!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
        "Trans rights :)",
        "Balatro, balatro. SWEET CAROLINE",
        "Oi Luis caralho caralho ralho",
        "O Luis ganhô, mas também sabe perdê",
        "Boyfriends hair isnt dyed. It is just naturally CIANO. Very cool!!!!\nsend help",
        "We love legacy mods. VS Hex my beloved <3..."
    ];

    static function main():Void
    {
        saveBuildTime();
        traceMessage();
    }

    public static function traceMessage():Void
    {
        final message = motivationMsgs[Std.random(motivationMsgs.length)];
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
