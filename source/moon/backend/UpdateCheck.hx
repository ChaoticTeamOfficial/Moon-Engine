package moon.backend;

import haxe.Http;
import haxe.Json;
import lime.app.Application;

class UpdateCheck
{
    public static function run(onUpdateAvailable:(String)->Void, onNoUpdate:()->Void)
    {
        #if html5
        onNoUpdate();
        return;
        #end

        // TODO: change this link, using FunkinCrew's for now as a placeholder.
        final http = new Http("https://api.github.com/repos/FunkinCrew/Funkin/releases/latest");
        http.setHeader("User-Agent", "Moon-Engine-AutoUpdater");
        http.onData = function(data:String) {
            try {
                final release:GithubRelease = Json.parse(data);

                if (compareVersions(release.tag_name, lime.app.Application.current.meta.get("version")) > 0)
                    onUpdateAvailable(release.tag_name);
                else onNoUpdate();
            } catch(e)
            {
                trace("Failed to parse GitHub release data", "ERROR");
                onNoUpdate();
            }
        };

        http.onError = function(msg)
        {
            trace('Update check failed: $msg', "WARNING");
            onNoUpdate();
        };

        http.request();
    }

    static function compareVersions(v1:String, v2:String):Int
    {
        var a = v1.split('.').map(Std.parseInt);
        var b = v2.split('.').map(Std.parseInt);
        
        for (i in 0...3) {
            if (a[i] > b[i]) return 1;
            if (a[i] < b[i]) return -1;
        }
        return 0;
    }
}

typedef GithubRelease = {
    var tag_name:String;
    var assets:Array<Dynamic>;
}