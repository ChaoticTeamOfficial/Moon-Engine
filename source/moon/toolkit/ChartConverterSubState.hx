package moon.toolkit;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.TextArea;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.data.ArrayDataSource;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import moon.backend.data.Chart;
import moon.backend.data.SongLibrary;
#if sys
import sys.FileSystem;
#end

using StringTools;

class ChartConverterSubState extends FlxSubState
{
	var dim:FlxSprite;
	var root:VBox;
	var formatDrop:DropDown;
	var folderField:TextField;
	var songField:TextField;
	var mixField:TextField;
	var selectAllBox:CheckBox;
	var autoDetectBox:CheckBox;
	var writeSharedBox:CheckBox;
	var overwriteBox:CheckBox;
	var applyNoteRulesBox:CheckBox;
	var statusLabel:Label;
	var logArea:TextArea;
	var diffScroll:ScrollView;
	var diffList:VBox;
	var diffChecks:Array<
		{name:String, box:CheckBox}> = [];

	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		dim = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
		dim.scrollFactor.set();
		add(dim);

		root = new VBox();
		root.width = 600;
		root.padding = 16;
		root.styleString = "background-color: #141417; border-radius: 8px;";
		root.left = (FlxG.width - 600) / 2;
		root.top = 20;

		final title = new Label();
		title.text = "Chart Converter";
		title.styleString = "font-size: 20px; color: #F2F2F2; font-bold: true;";
		root.addComponent(title);

		root.addComponent(labeledField("Source Format", formatDrop = makeFormatDrop()));
		formatDrop.onChange = function(_) refreshDifficultyList();

		root.addComponent(pathRow("Song Folder", folderField = makeTextField("path/to/song-folder"), () -> pickFolder()));

		root.addComponent(labeledField("Song Name", songField = makeTextField("auto from folder")));
		root.addComponent(labeledField("Mix Override", mixField = makeTextField("bf (v-slice auto)")));

		final diffHeader = new Label();
		diffHeader.text = "Difficulties to convert";
		diffHeader.styleString = "color: #F2F2F2; margin-top: 8px;";
		root.addComponent(diffHeader);

		autoDetectBox = new CheckBox();
		autoDetectBox.text = "Auto-detect from folder (includes custom)";
		autoDetectBox.selected = true;
		autoDetectBox.onChange = function(_)
		{
			final auto = autoDetectBox.selected;
			selectAllBox.disabled = auto;
			for (d in diffChecks) d.box.disabled = auto;
			if (auto) refreshDifficultyList();
		};
		root.addComponent(autoDetectBox);

		selectAllBox = new CheckBox();
		selectAllBox.text = "Select all listed difficulties";
		selectAllBox.selected = true;
		selectAllBox.disabled = true;
		selectAllBox.onChange = function(_) for (d in diffChecks) d.box.selected = selectAllBox.selected;
		root.addComponent(selectAllBox);

		diffScroll = new ScrollView();
		diffScroll.width = 568;
		diffScroll.height = 110;
		diffScroll.percentContentWidth = 100;
		diffList = new VBox();
		diffList.percentWidth = 100;
		diffScroll.addComponent(diffList);
		root.addComponent(diffScroll);

		rebuildDiffs(registeredDifficultyNames(), []);

		writeSharedBox = new CheckBox();
		writeSharedBox.text = "Write shared chart.json for non-suffixed";
		writeSharedBox.selected = true;
		root.addComponent(writeSharedBox);

		overwriteBox = new CheckBox();
		overwriteBox.text = "Overwrite existing files";
		overwriteBox.selected = true;
		root.addComponent(overwriteBox);

		applyNoteRulesBox = new CheckBox();
		applyNoteRulesBox.text = "Apply note type rules";
		applyNoteRulesBox.selected = true;
		root.addComponent(applyNoteRulesBox);

		final buttons = new HBox();
		buttons.styleString = "margin-top: 8px;";

		final scanBtn = new Button();
		scanBtn.text = "Rescan Folder";
		scanBtn.onClick = function(_) refreshDifficultyList();
		buttons.addComponent(scanBtn);

		final convertBtn = new Button();
		convertBtn.text = "Convert & Save";
		convertBtn.onClick = function(_) runConvert();
		buttons.addComponent(convertBtn);

		final closeBtn = new Button();
		closeBtn.text = "Close";
		closeBtn.onClick = function(_) close();
		buttons.addComponent(closeBtn);

		root.addComponent(buttons);

		statusLabel = new Label();
		statusLabel.text = "Ready. Pick a folder to scan difficulties.";
		statusLabel.styleString = "color: #8A8A8F; margin-top: 8px;";
		root.addComponent(statusLabel);

		logArea = new TextArea();
		logArea.width = 568;
		logArea.height = 70;
		logArea.disabled = true;
		logArea.styleString = "margin-top: 4px;";
		root.addComponent(logArea);

		Screen.instance.addComponent(root);
	}

	function makeFormatDrop():DropDown
	{
		final drop = new DropDown();
		drop.width = 360;
		drop.dataSource = ArrayDataSource.fromArray(Chart.SUPPORTED_FORMATS.copy());
		final idx = Chart.SUPPORTED_FORMATS.indexOf('v-slice');
		drop.selectedIndex = idx >= 0 ? idx : 0;
		return drop;
	}

	function makeTextField(placeholder:String):TextField
	{
		final field = new TextField();
		field.width = 320;
		field.placeholder = placeholder;
		return field;
	}

	function labeledField(labelText:String, field:Component):HBox
	{
		final row = new HBox();
		row.percentWidth = 100;
		row.styleString = "margin-top: 4px;";

		final label = new Label();
		label.text = labelText;
		label.width = 130;
		label.styleString = "color: #F2F2F2; vertical-align: center;";
		row.addComponent(label);
		row.addComponent(field);
		return row;
	}

	function pathRow(labelText:String, field:TextField, onBrowse:Void->Void):HBox
	{
		final row = labeledField(labelText, field);
		final browse = new Button();
		browse.text = "Browse…";
		browse.onClick = function(_) onBrowse();
		row.addComponent(browse);
		return row;
	}

	function pickFolder():Void
	{
		#if sys
		final dialog = new FileDialog();
		dialog.onSelect.add(function(path:String)
		{
			if (path == null || path == '') return;
			folderField.text = path;
			if ((songField.text ?? '').trim() == '' || songField.placeholder == songField.text) songField.text = Path.withoutDirectory(path);
			setStatus('Folder: $path');
			refreshDifficultyList();
		});
		dialog.onCancel.add(function() setStatus("Folder pick cancelled."));
		if (!dialog.browse(FileDialogType.OPEN_DIRECTORY, null, null, "Select song folder")) setStatus("Folder dialog is not supported on this platform.");
		#else
		setStatus("Folder picking is only available on desktop.");
		#end
	}

	function registeredDifficultyNames():Array<String>
	{
		final list = SongLibrary.getDifficultyList();
		if (list == null) return [];
		return[for (d in list) if (d != null && d.name != null) d.name];
	}

	function rebuildDiffs(registered:Array<String>, discovered:Array<String>):Void
	{
		final previouslySelected = new Map<String, Bool>();
		for (d in diffChecks) previouslySelected.set(d.name, d.box.selected);

		diffChecks = [];
		diffList.removeAllComponents();

		final seen = new Map<String, Bool>();
		final ordered:Array<
			{name:String, custom:Bool}> = [];

		function add(name:String, custom:Bool):Void
		{
			if (name == null || name == '' || seen.exists(name)) return;
			seen.set(name, true);
			ordered.push({
				name: name,
				custom: custom
			});
		}

		for (n in registered) add(n, false);
		for (n in discovered) add(n, registered.indexOf(n) == -1);

		final auto = autoDetectBox != null && autoDetectBox.selected;

		for (entry in ordered)
		{
			final diff = SongLibrary.getDifficulty(entry.name);
			final display = diff?.displayName ?? entry.name;
			final suffix = diff?.suffix ?? '';
			final suffixHint = suffix == '' ? " (shared)" : ' ($suffix)';
			final customHint = entry.custom ? " [custom]" : "";

			final box = new CheckBox();
			box.text = '$display$suffixHint$customHint';
			box.selected = previouslySelected.exists(entry.name) ? previouslySelected.get(entry.name) : true;
			box.disabled = auto;
			diffChecks.push({
				name: entry.name,
				box: box
			});
			diffList.addComponent(box);
		}

		if (ordered.length == 0)
		{
			final empty = new Label();
			empty.text = "No difficulties listed — pick a folder or disable auto-detect.";
			empty.styleString = "color: #8A8A8F;";
			diffList.addComponent(empty);
		}
	}

	function refreshDifficultyList():Void
	{
		#if sys
		final folder = (folderField.text ?? '').trim();
		final format = currentFormat();
		final registered = registeredDifficultyNames();
		var discovered:Array<String> = [];

		if (folder != '' && FileSystem.exists(folder))
		{
			try
			{
				if (FileSystem.isDirectory(folder)) discovered = Chart.listFolderDifficulties(format, folder);
				else
					discovered = Chart.listChartDifficulties(format, folder);
			}
			catch (e:Dynamic)
			{
				setStatus('Scan error: $e');
				discovered = [];
			}
		}

		rebuildDiffs(registered, discovered);

		if (discovered.length > 0)
		{
			final custom = [for (d in discovered) if (registered.indexOf(d) == -1) d];
			final customHint = custom.length > 0 ? ' (custom: ${custom.join(", ")})' : '';
			setStatus('Found ${discovered.length} diff(s): ${discovered.join(", ")}$customHint');
			logArea.text = 'Detected: ${discovered.join(", ")}';
		}
		else if (folder != '')
		{
			setStatus('No difficulties detected in folder for format "$format". Showing registered list.');
		}
		#else
		rebuildDiffs(registeredDifficultyNames(), []);
		#end
	}

	function currentFormat():String
	{
		final idx = formatDrop.selectedIndex;
		if (idx < 0 || idx >= Chart.SUPPORTED_FORMATS.length) return Chart.SUPPORTED_FORMATS[0];
		return Chart.SUPPORTED_FORMATS[idx];
	}

	function selectedDifficulties():Array<String>
	{
		if (autoDetectBox != null && autoDetectBox.selected) return null;

		final out:Array<String> = [];
		for (d in diffChecks) if (d.box.selected) out.push(d.name);
		return out;
	}

	function runConvert():Void
	{
		#if !sys
		setStatus("Conversion is only available on desktop builds.");
		return;
		#else
		final folder = (folderField.text ?? '').trim();
		final diffs = selectedDifficulties();
		final format = currentFormat();
		var song = (songField.text ?? '').trim();
		final mixOverride = (mixField.text ?? '').trim();

		if (folder == '' || !FileSystem.exists(folder))
		{
			setStatus("Invalid song folder.");
			return;
		}
		if (diffs != null && diffs.length == 0)
		{
			setStatus("Select at least one difficulty, or enable auto-detect.");
			return;
		}

		try
		{
			final diffLabel = diffs == null ? "auto" : diffs.join(", ");
			setStatus('Converting ($format) [$diffLabel]…');

			if (format == 'v-slice' || format == 'codename' || format == 'psych' || format == 'kade' || format == 'legacy' || format == 'fps-plus')
			{
				if (!FileSystem.isDirectory(folder))
				{
					setStatus("This format needs a song folder, not a single file.");
					return;
				}

				final entries = Chart.convertFolder(format, folder, diffs, applyNoteRulesBox.selected);
				if (entries == null || entries.length == 0)
				{
					setStatus("Nothing converted.");
					return;
				}

				final lines:Array<String> = [];
				for (entry in entries)
				{
					final outSong = song != '' && song != 'auto from folder' ? song : entry.song;
					final outMix = (mixOverride != '' && mixOverride != 'bf (v-slice auto)') ? mixOverride : entry.mix;

					if (
						!overwriteBox.selected
						&& entry.batch.results.length > 0
						&& Paths.exists(Chart.chartPath(outSong, outMix, entry.batch.results[0].difficulty) + '.json')
					)
					{
						setStatus('Refusing to overwrite: $outSong/$outMix');
						return;
					}

					if (!writeSharedBox.selected)
					{
						for (r in entry.batch.results)
						{
							final dir = 'songs/$outSong/$outMix';
							final rootPath = Paths.getVanillaPath('');
							Paths.saveFileContentTo(rootPath, '$dir/chart-${r.difficulty}.json', r.chartJson);
							Paths.saveFileContentTo(rootPath, Chart.eventsPath(outSong, outMix, r.difficulty) + '.json', r.eventsJson);
							if (r.metaJson != null) Paths.saveFileContentTo(rootPath, Chart.metaPath(outSong, outMix, r.difficulty) + '.json', r.metaJson);
						}
					}
					else
						Chart.writeConvertBatch(entry.batch, outSong, outMix);

					final names = [for (r in entry.batch.results) r.difficulty];
					lines.push('$outSong/$outMix → ${entry.batch.results.length} diff(s): ${names.join(", ")}');
				}

				logArea.text = lines.join("\n");
				setStatus("Done.");
			}
			else
			{
				if (song == '' || song == 'auto from folder') song = Path.withoutExtension(Path.withoutDirectory(folder));
				final mix = (mixOverride != '' && mixOverride != 'bf (v-slice auto)') ? mixOverride : 'bf';
				final batch = Chart.convertMany(format, folder, diffs ?? [], null, applyNoteRulesBox.selected);
				if (batch == null || batch.results.length == 0)
				{
					setStatus("Conversion returned no results.");
					return;
				}
				Chart.writeConvertBatch(batch, song, mix);
				final names = [for (r in batch.results) r.difficulty];
				logArea.text = 'Output: songs/$song/$mix/ (${names.join(", ")})';
				setStatus("Done.");
			}
		}
		catch (e:Dynamic)
		{
			setStatus('Error: $e');
			logArea.text = Std.string(e);
			trace('[CHART-CONVERTER] $e', "ERROR");
		}
		#end
	}

	function setStatus(msg:String):Void
	{
		statusLabel.text = msg;
		trace('[CHART-CONVERTER] $msg', "DEBUG");
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE) close();
	}

	override public function close():Void
	{
		if (root != null)
		{
			Screen.instance.removeComponent(root);
			root = null;
		}
		FlxG.mouse.visible = false;
		super.close();
	}

	override public function destroy():Void
	{
		if (root != null)
		{
			Screen.instance.removeComponent(root);
			root = null;
		}
		super.destroy();
	}
}
