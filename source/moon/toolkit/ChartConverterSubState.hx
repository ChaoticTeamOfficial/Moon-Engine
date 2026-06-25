package moon.toolkit;

import haxe.ui.containers.*;
import haxe.ui.components.*;
import haxe.ui.core.Screen;
import haxe.io.Path;
import lime.ui.FileDialog;
import moon.backend.data.Chart;
import moon.backend.data.SongLibrary;
import moon.backend.data.SrtParser;
import moon.backend.Conductor;

using StringTools;

class ChartConverterSubState extends FlxSubState
{
	var root:HBox;
	var sidebar:VBox;
	var contentArea:VBox;
	var formatDropdown:DropDown;
	var diffDropdown:DropDown;
	var chartPathField:TextField;
	var metaPathField:TextField;
	var srtPathField:TextField;
	var mixField:TextField;
	var statusLabel:Label;
	var noteEditorBox:VBox;
	var noteRulesContainer:VBox;
	var noteRules:Array<NoteRule> = [];
	var _chartPath:String;
	var _metaPath:String;
	var _srtPath:String;
	var _format:String = 'legacy';

	override public function create()
	{
		super.create();
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		var overlay = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, 0xCC000000);
		overlay.scrollFactor.set();
		add(overlay);

		root = new HBox();
		root.percentWidth = 100;
		root.percentHeight = 100;
		root.styleString = "padding: 0; spacing: 0;";
		Screen.instance.addComponent(root);

		buildSidebar();
		buildContent();
	}

	function buildSidebar()
	{
		sidebar = new VBox();
		sidebar.width = 220;
		sidebar.percentHeight = 100;
		sidebar.styleString = "background-color: #111116; padding: 16px; spacing: 12px;";
		root.addComponent(sidebar);

		var logo = new Label();
		logo.text = "Moon Chart\nConverter";
		logo.antialiasing = false;
		logo.styleString = "font-size: 22px; color: #a78bfa; font-weight: bold;";
		sidebar.addComponent(logo);

		addSidebarDivider();

		addSidebarSection("SOURCE");

		formatDropdown = addLabeledDropdown(sidebar, "Format", Chart.SUPPORTED_FORMATS);
		formatDropdown.selectedIndex = 0;
		_format = Chart.SUPPORTED_FORMATS[0];
		formatDropdown.onChange = _ ->
		{
			if (formatDropdown.selectedItem != null) _format = formatDropdown.selectedItem.text;
		};

		var diffNames:Array<String> = [for (d in SongLibrary.getDifficultyList()) d.name];
		if (diffNames.length == 0) diffNames = ["easy", "normal", "hard", "erect"];

		diffNames.push("nightmare");

		diffDropdown = addLabeledDropdown(sidebar, "Difficulty", diffNames);
		var hardIdx = diffNames.indexOf("hard");
		diffDropdown.selectedIndex = hardIdx >= 0 ? hardIdx : 0;

		mixField = addLabeledField(sidebar, "Mix name", "bf");

		addSidebarDivider();
		addSidebarSection("FILES");

		chartPathField = addBrowseRow(sidebar, "Chart JSON", () -> browseFile("json", "Select Chart JSON", p ->
		{
			_chartPath = p;
			chartPathField.text = Path.withoutDirectory(p);

			final companion = Chart.findCompanionFile(p, "meta");
			if (companion != null)
			{
				_metaPath = companion;
				metaPathField.text = Path.withoutDirectory(companion);
			}
		}));

		metaPathField = addBrowseRow(sidebar, "Metadata (opt.)", () -> browseFile("json", "Select Metadata JSON", p ->
		{
			_metaPath = p;
			metaPathField.text = Path.withoutDirectory(p);
		}));

		srtPathField = addBrowseRow(sidebar, "Subtitles (opt.)", () -> browseFile("srt", "Select SRT File", p ->
		{
			_srtPath = p;
			srtPathField.text = Path.withoutDirectory(p);
		}));

		addSidebarDivider();

		var convertBtn = new Button();
		convertBtn.text = "> CONVERT";
		convertBtn.percentWidth = 100;
		convertBtn.styleString = "background-color: #7c3aed; color: #fff; font-size: 15px; font-weight: bold; border-radius: 8px; padding: 10px;";
		convertBtn.onClick = _ -> doConversion();
		sidebar.addComponent(convertBtn);

		statusLabel = new Label();
		statusLabel.antialiasing = false;
		statusLabel.percentWidth = 100;
		statusLabel.wordWrap = true;
		statusLabel.styleString = "font-size: 11px; color: #94a3b8;";
		sidebar.addComponent(statusLabel);
	}

	function buildContent()
	{
		contentArea = new VBox();
		contentArea.percentWidth = 100;
		contentArea.percentHeight = 100;
		contentArea.styleString = "background-color: #0f0f14; padding: 24px; spacing: 20px;";
		root.addComponent(contentArea);

		var header = new Label();
		header.antialiasing = false;
		header.text = "Note Post-Processing Rules";
		header.styleString = "font-size: 18px; color: #e2e8f0; font-weight: bold;";
		contentArea.addComponent(header);

		var subHeader = new Label();
		subHeader.antialiasing = false;
		subHeader.text = "Rules are applied in order after conversion. You can retype, relane, or filter notes.";
		subHeader.styleString = "font-size: 12px; color: #64748b;";
		contentArea.addComponent(subHeader);

		var addRuleRow = new HBox();
		addRuleRow.styleString = "spacing: 8px;";
		contentArea.addComponent(addRuleRow);

		for (ruleType in ["Retype Notes", "Relane Notes", "Remove Note Type", "Remove Lane"])
		{
			var btn = new Button();
			btn.text = '+ $ruleType';
			btn.styleString = "background-color: #1e293b; color: #94a3b8; border: 1px solid #334155; border-radius: 6px; font-size: 11px;";
			btn.onClick = _ -> addRule(ruleType);
			addRuleRow.addComponent(btn);
		}

		var divider = new MoonSprite().makeGraphic(1, 1, 0xFF334155);
		var sep = new Label();
		sep.antialiasing = false;
		sep.percentWidth = 100;
		sep.styleString = "border-top: 1px solid #334155; margin-top: 4px; margin-bottom: 4px;";
		contentArea.addComponent(sep);

		noteRulesContainer = new VBox();
		noteRulesContainer.percentWidth = 100;
		noteRulesContainer.styleString = "spacing: 8px;";
		contentArea.addComponent(noteRulesContainer);

		buildPreviewSection();
	}

	function buildPreviewSection()
	{
		var previewHeader = new Label();
		previewHeader.text = "Conversion Preview";
		previewHeader.antialiasing = false;
		previewHeader.styleString = "font-size: 14px; color: #94a3b8; margin-top: 16px;";
		contentArea.addComponent(previewHeader);

		var previewBox = new VBox();
		previewBox.percentWidth = 100;
		previewBox.styleString = "background-color: #1e293b; border-radius: 8px; padding: 16px; spacing: 6px;";
		contentArea.addComponent(previewBox);

		for (item in [
			"Output path: assets/songs/{name}/{mix}/chart-{diff}.json",
			"Metadata path: assets/songs/{name}/{mix}/meta{suffix}.json",
			"Events path: assets/songs/{name}/{mix}/events{suffix}.json",
			"SRT subtitles -> Show Subtitle events (if provided)",
			"Note rules are applied after base conversion!"
		])
		{
			var lbl = new Label();
			lbl.text = "* " + item;
			lbl.styleString = "font-size: 11px; color: #475569;";
			lbl.antialiasing = false;
			previewBox.addComponent(lbl);
		}
	}

	function addRule(type:String)
	{
		var rule = new NoteRule(type, () ->
		{
			noteRules.remove(noteRules[noteRules.length - 1]);
		});
		noteRules.push(rule);
		noteRulesContainer.addComponent(rule.root);
	}

	function doConversion()
	{
		if (_chartPath == null)
		{
			setStatus("Please select a chart file first.", "#f59e0b");
			return;
		}
		if (_format == null)
		{
			setStatus("Please select a format.", "#f59e0b");
			return;
		}

		setStatus("Converting...", "#94a3b8");

		try
		{
			final diff = diffDropdown.selectedItem?.text ?? 'hard';
			final mix = mixField.text.trim().length > 0 ? mixField.text.trim() : 'bf';
			final songName = Path.withoutDirectory(Path.directory(_chartPath));
			final suffix = Chart.getDifficultySuffix(diff);

			final result = Chart.convert(_format, _chartPath, diff, _metaPath);

			var chartData:Dynamic = haxe.Json.parse(result.chartJson);
			var eventsData:Array<Dynamic> = haxe.Json.parse(result.eventsJson);
			var metaData:Dynamic = result.metaJson != null ? haxe.Json.parse(result.metaJson) : null;

			if (chartData.notes != null)
			{
				var notes:Array<Dynamic> = chartData.notes;
				for (rule in noteRules) notes = rule.apply(notes);
				chartData.notes = notes;
			}

			if (_srtPath != null)
			{
				#if sys
				try
				{
					final srtContent = sys.io.File.getContent(_srtPath);
					final bpm:Float = metaData?.bpm ?? 120.0;
					final timeSig:Array<Dynamic> = metaData?.timeSignature ?? [4, 4];
					final tempConductor = new Conductor(bpm, timeSig[0], timeSig[1]);
					final subtitleEvents = SrtParser.parse(srtContent, tempConductor);
					for (e in subtitleEvents) eventsData.push(e);
					eventsData.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
				}
				catch (e:Dynamic)
				{
					setStatus('SRT parse failed: $e', "#f59e0b");
				}
				#end
			}

			final chartJson = haxe.Json.stringify(chartData, null, "\t");
			final eventsJson = haxe.Json.stringify(eventsData, null, "\t");
			final metaJson = metaData != null ? haxe.Json.stringify(metaData, null, "\t") : null;

			Paths.saveFileContent('songs/$songName/$mix/chart-$diff.json', chartJson);
			Paths.saveFileContent('songs/$songName/$mix/events$suffix.json', eventsJson);

			if (metaJson != null) Paths.saveFileContent('songs/$songName/$mix/meta$suffix.json', metaJson);

			setStatus('Done! Saved to assets/songs/$songName/$mix/', "#4ade80");
		}
		catch (e:Dynamic)
		{
			setStatus('Error: $e', "#f87171");
		}
	}

	function setStatus(msg:String, color:String)
	{
		statusLabel.text = msg;
		statusLabel.styleString = 'font-size: 11px; color: $color;';
	}

	function addSidebarSection(title:String)
	{
		var lbl = new Label();
		lbl.text = title;
		lbl.antialiasing = false;
		lbl.styleString = "font-size: 10px; color: #475569; font-weight: bold; letter-spacing: 2px;";
		sidebar.addComponent(lbl);
	}

	function addSidebarDivider()
	{
		var sep = new Label();
		sep.percentWidth = 100;
		sep.antialiasing = false;
		sep.styleString = "border-top: 1px solid #1e293b; margin-top: 2px; margin-bottom: 2px;";
		sidebar.addComponent(sep);
	}

	function addLabeledDropdown(parent:VBox, label:String, options:Array<String>):DropDown
	{
		var lbl = new Label();
		lbl.text = label;
		lbl.antialiasing = false;
		lbl.styleString = "font-size: 11px; color: #64748b;";
		parent.addComponent(lbl);

		var dd = new DropDown();
		dd.percentWidth = 100;
		for (o in options) dd.dataSource.add({
			text: o
		});
		parent.addComponent(dd);
		return dd;
	}

	function addLabeledField(parent:VBox, label:String, placeholder:String = ""):TextField
	{
		var lbl = new Label();
		lbl.text = label;
		lbl.antialiasing = false;
		lbl.styleString = "font-size: 11px; color: #64748b;";
		parent.addComponent(lbl);

		var tf = new TextField();
		tf.percentWidth = 100;
		tf.text = placeholder;
		parent.addComponent(tf);
		return tf;
	}

	function addBrowseRow(parent:VBox, label:String, onBrowse:Void->Void):TextField
	{
		var lbl = new Label();
		lbl.text = label;
		lbl.antialiasing = false;
		lbl.styleString = "font-size: 11px; color: #64748b;";
		parent.addComponent(lbl);

		var row = new HBox();
		row.percentWidth = 100;
		row.styleString = "spacing: 4px;";
		parent.addComponent(row);

		var tf = new TextField();
		tf.percentWidth = 100;
		tf.placeholder = "None selected";
		row.addComponent(tf);

		var btn = new Button();
		btn.text = "…";
		btn.width = 28;
		btn.styleString = "background-color: #334155; color: #94a3b8; border-radius: 4px;";
		btn.onClick = _ -> onBrowse();
		row.addComponent(btn);

		return tf;
	}

	function browseFile(ext:String, title:String, onSelect:String->Void)
	{
		#if sys
		var dlg = new FileDialog();
		dlg.onSelect.add(onSelect);
		dlg.browse(OPEN, ext, Sys.getCwd(), title);
		#end
	}

	override public function closeSubState()
	{
		if (root != null) Screen.instance.removeComponent(root);
		super.closeSubState();
	}
}

class NoteRule
{
	public var root:HBox;

	var type:String;
	var fromField:TextField;
	var toField:TextField;

	public function new(type:String, onRemove:Void->Void)
	{
		this.type = type;

		root = new HBox();
		root.percentWidth = 100;
		root.styleString = "background-color: #1e293b; border-radius: 6px; padding: 8px; spacing: 8px;";

		var typeLbl = new Label();
		typeLbl.text = type;
		typeLbl.antialiasing = false;
		typeLbl.width = 140;
		typeLbl.styleString = "font-size: 11px; color: #a78bfa; font-weight: bold;";
		root.addComponent(typeLbl);

		switch (type)
		{
			case "Retype Notes":
				addField("From type", "default");
				var arrow = new Label();
				arrow.text = "->";
				arrow.styleString = "color: #475569;";
				arrow.antialiasing = false;
				root.addComponent(arrow);
				addField("To type", "alt");

			case "Relane Notes":
				addField("From lane", "opponent");
				var arrow = new Label();
				arrow.text = "->";
				arrow.styleString = "color: #475569;";
				arrow.antialiasing = false;
				root.addComponent(arrow);
				addField("To lane", "p1");

			case "Remove Note Type":
				addField("Type to remove", "default");

			case "Remove Lane":
				addField("Lane to remove", "opponent");
		}

		var removeBtn = new Button();
		removeBtn.text = "X";
		removeBtn.width = 24;
		removeBtn.styleString = "background-color: #450a0a; color: #f87171; border-radius: 4px; font-size: 11px;";
		removeBtn.onClick = _ ->
		{
			root.parentComponent?.removeComponent(root);
			onRemove();
		};
		root.addComponent(removeBtn);
	}

	function addField(placeholder:String, defaultVal:String):TextField
	{
		var tf = new TextField();
		tf.width = 100;
		tf.text = defaultVal;
		tf.placeholder = placeholder;
		if (fromField == null) fromField = tf;
		else
			toField = tf;
		root.addComponent(tf);
		return tf;
	}

	public function apply(notes:Array<Dynamic>):Array<Dynamic>
	{
		final from = fromField?.text ?? '';
		final to = toField?.text ?? '';

		return switch (type)
		{
			case "Retype Notes":
				[for (n in notes)
				{
					if (n.type == from) n.type = to;
					n;
				}];

			case "Relane Notes":
				[for (n in notes)
				{
					if (n.lane == from) n.lane = to;
					n;
				}];

			case "Remove Note Type":
				notes.filter(n -> n.type != from);

			case "Remove Lane":
				notes.filter(n -> n.lane != from);

			default:
				notes;
		};
	}
}
