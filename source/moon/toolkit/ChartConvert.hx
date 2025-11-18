package moon.toolkit;

import flixel.util.FlxTimer;
import lime.ui.FileDialog;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxMath;

using StringTools;
//todo if im with patience to do so.
// document this. idk. this code is shit.
// maybe I will maybe not.
// but I'll most likely not. :P
class ChartConvert extends FlxState
{
    private var _text:FlxText;
    private var _statusText:FlxText;
    private var _fileDialog:FileDialog;

    private var state(default, set):ConvertState = FormatSelect;

    private var format:String = '';
    private var chartPath:String = null;
    private var metaPath:String = null;
    private var difficulty:String = 'hard';
    private var difficulties:Array<String> = ['easy', 'normal', 'hard', 'erect', 'nightmare'];

    // temporary storage for conversion results before saving stuff :P
    private var _conversionResult:moon.backend.data.Chart.ConvertResult = null;
    private var _savedChartPath:String = null;
    private var _savedEventsPath:String = null;

    private var _curSelection:Int = 0;

    override public function create():Void
    {
        super.create();

        FlxG.sound.playMusic(Paths.sound('toolbox/chillPlace.ogg'));

        _text = new FlxText(0, 40, FlxG.width, '');
        _text.setFormat(Paths.font('5by7_b.ttf'), 32, FlxColor.WHITE, CENTER);
        _text.screenCenter(X);
        add(_text);

        _statusText = new FlxText(0, 0, FlxG.width, '');
        _statusText.setFormat(Paths.font('5by7_b.ttf'), 32, FlxColor.CYAN, CENTER);
        _statusText.screenCenter();
        add(_statusText);

        updateStateText();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        // Don't process input if a file dialog is potentially open
        if (_fileDialog != null) return;

        switch (state)
        {
            case FormatSelect:
                Global.allowInputs = true;
                if (MoonInput.justPressed(UI_LEFT)) changeSelection(-1, Chart.SUPPORTED_FORMATS);
                else if (MoonInput.justPressed(UI_RIGHT)) changeSelection(1, Chart.SUPPORTED_FORMATS);
                else if (MoonInput.justPressed(ACCEPT))
                {
                    format = Chart.SUPPORTED_FORMATS[_curSelection];
                    _curSelection = 0;
                    state = ChartFileSelect;
                    updateStateText();
                    selectChartFile();
                }

            case DifficultySelect:
                if (FlxG.keys.justPressed.LEFT) changeSelection(-1, difficulties);
                else if (FlxG.keys.justPressed.RIGHT) changeSelection(1, difficulties);
                else if (FlxG.keys.justPressed.ENTER)
                {
                    difficulty = difficulties[_curSelection];
                    // Check if metadata is needed for this format
                    if (format == 'codename' || format == 'v-slice')
                    {
                        state = MetaFileSelect;
                        updateStateText();
                        selectMetaFile();
                    }
                    else startConversion();
                }
            case ChartFileSelect | MetaFileSelect | Converting | SavingChart | SavingEvents | Done:
                // already handled by dialogue or timers, so ignore.
            case Failed:
                if (MoonInput.justPressed(ACCEPT) || MoonInput.justPressed(BACK)) FlxG.resetState();
        }
    }

    function changeSelection(change:Int = 0, array:Array<Dynamic>):Void
    {
        _curSelection = FlxMath.wrap(_curSelection + change, 0, array.length - 1);
        updateStateText();
    }

    function selectChartFile()
    {
        #if sys
        _fileDialog = new FileDialog();
        _fileDialog.onSelect.add(onChartFileSelected);
        _fileDialog.onCancel.add(onDialogueCancel);
        _fileDialog.browse(OPEN, "json", Sys.getCwd(), "Browse for the CHART file");
        #else
        state = Failed;
        #end
    }

    function selectMetaFile()
    {
        #if sys
        _fileDialog = new FileDialog();
        _fileDialog.onSelect.add(onMetaFileSelected);
        _fileDialog.onCancel.add(onDialogueCancel);
        _fileDialog.browse(OPEN, "json", Sys.getCwd(), "Browse for the METADATA file");
        #else
        state = Failed;
        #end
    }

    function startConversion()
    {
        try
        {
            state = Converting;
            new FlxTimer().start(0.1, (_) ->
            {
                _conversionResult = Chart.convert(format, chartPath, difficulty, metaPath);
                state = SavingChart;
                saveChartFile();
            });
        }
        catch (e:Dynamic){
            state = Failed;
        }
    }

    function saveChartFile()
    {
        #if sys
        _fileDialog = new FileDialog();
        _fileDialog.onSave.add(onChartFileSaved);
        _fileDialog.onCancel.add(onDialogueCancel);
        _fileDialog.save(_conversionResult.chartJson, "json", Sys.getCwd(), "Save your converted CHART file");
        #else
        state = Failed;
        #end
    }

    function saveEventsFile()
    {
        #if sys
        _fileDialog = new FileDialog();
        _fileDialog.onSave.add(onEventsFileSaved);
        _fileDialog.onCancel.add(onDialogueCancel);
        _fileDialog.save(_conversionResult.eventsJson, "json", Sys.getCwd(), "Save your converted EVENTS file");
        #else
        state = Failed;
        #end
    }

    // --- Callbacks ---
    function onChartFileSelected(path:String)
    {
        _fileDialog = null;
        chartPath = path;
        state = DifficultySelect;
    }

    function onMetaFileSelected(path:String)
    {
        _fileDialog = null;
        metaPath = path;
        startConversion();
    }

    function onChartFileSaved(path:String)
    {
        _fileDialog = null;
        try
        {
            //Paths.saveFileContent(path, _conversionResult.chartJson);
            _savedChartPath = path;
            state = SavingEvents;
            saveEventsFile();
        }
        catch (e:Dynamic){
            state = Failed;
        }
    }

    function onEventsFileSaved(path:String)
    {
        _fileDialog = null;
        //Paths.saveFileContent(path, _conversionResult.eventsJson);
        _savedEventsPath = path;
        finishConversion();
    }

    function onDialogueCancel()
    {
        _fileDialog = null;
        state = Failed;
    }

    function finishConversion()
    {
        state = Done;
        _conversionResult = null;
        _savedChartPath = null;
        _savedEventsPath = null;
    }

    // --- UI Updates ---
    // hate this shit btw, but whatev
    function updateStateText()
    {
        switch(state)
        {
            case FormatSelect:
                changeTXT("Select the format of the chart you want to convert:");
                changeStatus('< ${Chart.SUPPORTED_FORMATS[_curSelection]} >', FlxColor.CYAN);

            case ChartFileSelect:
                changeTXT("Select your chart file...");
                changeStatus('(Format: $format)', FlxColor.YELLOW);

            case DifficultySelect:
                changeTXT('Select the difficulty to convert:\n(Chart: ${haxe.io.Path.directory(chartPath)})');
                changeStatus('< ${difficulties[_curSelection]} >', FlxColor.CYAN);

            case MetaFileSelect:
                changeTXT('This format requires a metadata file.\nPress Enter to select the metadata file...');
                changeStatus('(Chart: ${haxe.io.Path.directory(chartPath)}-$difficulty)', FlxColor.YELLOW);

            case Converting:
                changeTXT('Please wait...');
                changeStatus('');

            case SavingChart: changeTXT('Conversion done! Now save your chart file...');
            case SavingEvents: changeTXT('Conversion done! Now save your events file...');
            case Done: changeTXT('Conversion done! Enjoy :3', FlxColor.LIME); reset();
            case Failed:
                changeTXT('Operation either failed or cancelled.', FlxColor.ORANGE);
                changeStatus('Press Enter or Escape to return. (or just wait)');
                reset();
        }
    }
    
    private function changeStatus(txt:String, color:FlxColor = FlxColor.WHITE)
    {
        _statusText.text = txt;
        _statusText.color = color;
        _statusText.screenCenter(X);
        _statusText.y = _text.y + _text.height + 20;
    }

    private function changeTXT(txt:String, ?color:FlxColor = FlxColor.WHITE)
    {
        _text.text = txt;
        _text.color = color;
        _text.screenCenter(X);
    }

    function reset()
        new FlxTimer().start(5, (_) -> FlxG.resetState());

    @:noCompletion public function set_state(state:ConvertState):ConvertState
    {
        this.state = state;
        updateStateText();
        return this.state;
    }
}

enum ConvertState
{
    FormatSelect;
    ChartFileSelect;
    SavingChart;
    SavingEvents;
    DifficultySelect;
    MetaFileSelect;
    Converting;
    Done;
    Failed;
}