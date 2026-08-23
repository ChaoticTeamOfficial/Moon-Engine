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
	var writeSharedBox:CheckBox;
	var overwriteBox:CheckBox;
	var applyNoteRulesBox:CheckBox;
	var statusLabel:Label;
	var logArea:TextArea;
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
		// formatDrop.onChange = function(_) updateFormatHints();

		root.addComponent(pathRow("Song Folder", folderField = makeTextField("path/to/song-folder"), () -> pickFolder()));

		root.addComponent(labeledField("Song Name", songField = makeTextField("auto from folder")));
		root.addComponent(labeledField("Mix Override", mixField = makeTextField("bf (v-slice auto)")));

		final diffHeader = new Label();
		diffHeader.text = "Difficulties to convert";
		diffHeader.styleString = "color: #F2F2F2; margin-top: 8px;";
		root.addComponent(diffHeader);

		selectAllBox = new CheckBox();
		selectAllBox.text = "Select all registered difficulties";
		selectAllBox.selected = true;
		selectAllBox.onChange = function(_) for (d in diffChecks) d.box.selected = selectAllBox.selected;
		root.addComponent(selectAllBox);

		final diffScroll = new ScrollView();
		diffScroll.width = 568;
		diffScroll.height = 110;
		diffScroll.percentContentWidth = 100;
		final diffList = new VBox();
		diffList.percentWidth = 100;

		for (diff in SongLibrary.getDifficultyList())
		{
			final suffixHint = (diff.suffix ?? '') == '' ? " (shared)" : ' (${diff.suffix})';
			final box = new CheckBox();
			box.text = '${diff.displayName ?? diff.name}$suffixHint';
			box.selected = true;
			diffChecks.push({
				name: diff.name,
				box: box
			});
			diffList.addComponent(box);
		}

		diffScroll.addComponent(diffList);
		root.addComponent(diffScroll);

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
		statusLabel.text = "Ready.";
		statusLabel.styleString = "color: #8A8A8F; margin-top: 8px;";
		root.addComponent(statusLabel);

		logArea = new TextArea();
		logArea.width = 568;
		logArea.height = 70;
		logArea.disabled = true;
		logArea.styleString = "margin-top: 4px;";
		root.addComponent(logArea);

		// updateFormatHints();
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
		});
		dialog.onCancel.add(function() setStatus("Folder pick cancelled."));
		if (!dialog.browse(FileDialogType.OPEN_DIRECTORY, null, null, "Select song folder")) setStatus("Folder dialog is not supported on this platform.");
		#else
		setStatus("Folder picking is only available on desktop.");
		#end
	}

	function selectedDifficulties():Array<String>
	{
		final out:Array<String> = [];
		for (d in diffChecks) if (d.box.selected) out.push(d.name);
		return out;
	}

	function runConvert():Void
	{
		#if !sys
		setStatus("Conversion is only available on desktop builds.");
		return;
		#end

		final folder = (folderField.text ?? '').trim();
		final diffs = selectedDifficulties();
		final format = Chart.SUPPORTED_FORMATS[formatDrop.selectedIndex];
		var song = (songField.text ?? '').trim();
		final mixOverride = (mixField.text ?? '').trim();

		if (folder == '' || !FileSystem.exists(folder))
		{
			setStatus("Invalid song folder.");
			return;
		}
		if (diffs.length == 0)
		{
			setStatus("Select at least one difficulty.");
			return;
		}

		try
		{
			setStatus('Converting ($format)…');

			if (format == 'v-slice' || format == 'codename')
			{
				if (!FileSystem.isDirectory(folder))
				{
					setStatus("V-Slice / Codename need a folder, not a single file.");
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

					if (!overwriteBox.selected && Paths.exists(Chart.chartPath(outSong, outMix, entry.batch.results[0].difficulty) + '.json'))
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

					lines.push('$outSong/$outMix → ${entry.batch.results.length} diff(s)');
				}

				logArea.text = lines.join("\n");
				setStatus("Done.");
			}
			else
			{
				if (song == '' || song == 'auto from folder') song = Path.withoutExtension(Path.withoutDirectory(folder));
				final mix = (mixOverride != '' && mixOverride != 'bf (v-slice auto)') ? mixOverride : 'bf';
				final batch = Chart.convertMany(format, folder, diffs, null, applyNoteRulesBox.selected);
				if (batch == null || batch.results.length == 0)
				{
					setStatus("Conversion returned no results.");
					return;
				}
				Chart.writeConvertBatch(batch, song, mix);
				logArea.text = 'Output: songs/$song/$mix/';
				setStatus("Done.");
			}
		}
		catch (e:Dynamic)
		{
			setStatus('Error: $e');
			logArea.text = Std.string(e);
			trace('[CHART-CONVERTER] $e', "ERROR");
		}
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
