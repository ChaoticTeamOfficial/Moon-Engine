package moon.game;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import moon.backend.gameplay.*;
import moon.menus.*;
import moon.game.obj.results.*;
import moon.backend.gameplay.Timings.RankData;
import moon.dependency.scripting.MoonScript;

class ResultsState extends FlxState
{
	public var stats:PlayerStats;
	public var chartMeta:Chart.MetadataStruct;
	public var diff:String;
	public var newScore:Bool;

	// The order for each text
	final textOrder:Array<String> = [
		'totalNotes',
		'maxCombo',
		'sick',
		'good',
		'bad',
		'shit',
		'miss'
	];
	// Position for each text, representing the orders from the array above ^^
	final posOrder:Array<FlxPoint> = [
		FlxPoint.get(372, 130),
		FlxPoint.get(372, 198),
		FlxPoint.get(200, 255),
		FlxPoint.get(200, 312),
		FlxPoint.get(200, 368),
		FlxPoint.get(200, 426),
		FlxPoint.get(230, 478)
	];
	final borderColors:Array<FlxColor> = [
		0xFF000000,
		0xFF000000,
		0xFF251e6c,
		0xFF1e5b28,
		0xFF5a1638,
		0xFF432d2d,
		0xFF402217
	];

	public var script:MoonScript = new MoonScript();

	public function new(stats:PlayerStats, chartMeta:Chart.MetadataStruct, diff:String, newScore:Bool)
	{
		super();
		this.stats = stats;
		this.chartMeta = chartMeta;
		this.diff = diff;
		this.newScore = newScore;
	}

	var accTemp(default, set):Int = 0;
	var rankData:RankData;
	var rank:String = '';
	var character:String = '';
	var bgTxts:Array<TextScroll> = [];

	public var background:FlxSpriteGroup = new FlxSpriteGroup();

	override public function create()
	{
		super.create();

		// rank = 'PERFECT';
		rankData = Timings.getRank(stats.accuracy);
		rank = rankData.rank;
		character = MoonSettings.callSetting('Game Character');

		Global.registerScript("rankScript", script);

		var tryRank = rank;

		// Look for the rank in thresholds
		for (i in 0...Timings.thresholds.length)
		{
			if (Timings.thresholds[i].rank == rank)
			{
				var prev = i;
				while (prev >= 0)
				{
					final fallback = Timings.thresholds[prev].rank;
					if (Paths.exists('images/ingame/results/$character/$fallback'))
					{
						tryRank = fallback;
						break;
					}
					prev--;
				}
				break;
			}
		}
		script.load('images/ingame/results/$character/$tryRank/script.hx');
		Global.scriptSet('results', this);

		DiscordRPC.updatePresence(OG, "At the Results Screen!", 'Rank: ${Std.int(stats.accuracy)}% ($rank)', false);

		var back = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFECD5C, 0xFFFF9D47]);
		add(back);
		back.alpha = 0.0001;
		back.active = false;
		FlxTween.tween(back, {
			alpha: 1
		}, 0.7);

		add(background);

		for (i in 0...14)
		{
			var dumb = new TextScroll(0, 10 + (64 * i), rank, FlxG.width, 64, true);
			background.add(dumb);
			dumb.angle = -6;
			dumb.speed = 0.25 + (0.04 * i);
			dumb.color = 0xFFfeda6b;
			bgTxts.push(dumb);
			dumb.visible = false;
		}

		var textInfo = new ScrollingText(FlxG.width / 2 - 114, 0, FlxG.width / 2 + 114, 'wawa', 52);
		textInfo.textField.font = Paths.font('tardling/Solid/Tardling-Solid.ttf');
		textInfo.textField.color = 0xFFf9feb1;
		textInfo.antialiasing = true;
		textInfo.angle = -4;
		textInfo.textField.setBorderStyle(OUTLINE, 0xFFf98862, 4);
		textInfo.scrollSpeed = 58;
		add(textInfo);

		var soundBooth = new FlxAnimate();
		soundBooth.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/UI/soundBooth"));
		soundBooth.anim.addBySymbol('drop', 'sound system', 24, false);
		soundBooth.alpha = 0.0001;
		soundBooth.x -= 16;
		soundBooth.y -= 200;
		soundBooth.antialiasing = true;
		add(soundBooth);

		var judges = new FlxAnimate();
		judges.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/UI/judgesDisplay"));
		judges.anim.addBySymbol('show', 'categories', 24, false);
		judges.alpha = 0.0001;
		judges.y += 120;
		judges.x -= 158;
		judges.antialiasing = true;
		add(judges);

		var bb = new MoonSprite().loadGraphic(Paths.image('ingame/results/UI/bb'));
		bb.antialiasing = true;
		bb.active = false;
		add(bb);

		var results = new FlxAnimate();
		results.frames = FlxAnimateFrames.fromAnimate(Paths.getPath("images/ingame/results/UI/resultsTxt"));
		results.anim.addBySymbol("hi", "results", 24, false);
		results.alpha = 0.0001;
		results.x -= 180;
		results.antialiasing = true;
		add(results);

		var scoreNum = new ScoreNumbers(35, 305, 10, 0);
		add(scoreNum);
		scoreNum.visible = false;

		var score = new MoonSprite().loadGraphic(Paths.image('ingame/results/UI/score'));
		add(score);
		score.screenCenter(Y);
		score.x += 28;
		score.y += 216;
		score.antialiasing = true;
		score.active = false;

		var scoreBump = new MoonSprite(score.x, score.y);
		scoreBump.loadGraphicFromSprite(score);
		add(scoreBump);
		scoreBump.visible = false;
		scoreBump.active = false;
		scoreBump.blend = ADD;

		var replay = new SaveReplayNotif(32, 32);
		add(replay);
		replay.onFinish.add(() ->
		{
			replay.parameters = {
				text: PlayState.replaysToSave.length == 1 ? 'Replay saved!\n"${PlayState.replaysToSave[0]}"' : 'Saved ${PlayState.replaysToSave.length} replays.',
				color: 0xFFd98617,
				duration: 4
			}
			PlayState.saveReplays();

			replay.flash();
			Paths.playSFX('ui/replaySaved.wav');
		});

		// trace(newScore);
		if (newScore)
		{
			var hs = new MoonSprite(0, 532);
			hs.frames = Paths.getSparrowAtlas("ingame/results/UI/highscoreNew");
			hs.animation.addByPrefix("new", "highscoreAnim0", 24, false);
			hs.visible = false;
			add(hs);
			new FlxTimer().start(3.7, _ ->
			{
				hs.visible = true;
				hs.playAnim("new", true);
				hs.animation.onFinish.add(_ -> hs.playAnim("new", true, false, 16));
			});
		}

		score.scale.set(1.6, 1.6);
		score.alpha = 0.00001;

		Global.scriptCall('onPostCreate');

		new FlxTimer().start(0.4, (_) ->
		{
			results.alpha = 1;
			results.anim.play('hi', true);

			soundBooth.alpha = 1;
			soundBooth.anim.play('drop');

			new FlxTimer().start(0.4, (_) ->
			{
				judges.anim.play('show');
				judges.alpha = 1;

				for (i in 0...textOrder.length)
				{
					new FlxTimer().start(0.6 + (0.14 * i), (_) ->
					{
						final point = posOrder[i];
						final text = textOrder[i];

						var t = new FlxText(point.x, point.y + 16);
						t.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 56, (i > 1) ? Timings.get(text).color : FlxColor.WHITE);
						t.text = (i == 0) ? '${stats.totalNotes}' : (i == 1) ? '${stats.highestCombo}' : '${stats.judgementsCounter.get(text)}';
						// t.textField.antiAliasType = ADVANCED;
						// t.textField.sharpness = 400;
						t.antialiasing = true;
						t.setBorderStyle(OUTLINE, borderColors[i], 4);
						add(t);
						t.alpha = 0.4;

						t.origin.set(t.width / 2, t.height / 2);
						FlxTween.tween(t, {
							y: t.y - 12,
							alpha: 1
						}, 0.7, {
							ease: FlxEase.expoOut
						});
					});
				}

				var clear = new FlxText(FlxG.width - 128);
				clear.setFormat(Paths.font('phantomuff/difficulty.ttf'), 128, FlxColor.WHITE);
				clear.screenCenter(Y);
				clear.setBorderStyle(SHADOW, FlxColor.BLACK, 12);
				clear.antialiasing = true;
				add(clear);

				replay.parameters = {
					text: 'Hold [TAB] to save ' + (PlayState.replaysToSave.length == 1 ? "a replay!" : "all the replays!"),
					color: 0xFF7117d5,
					duration: 6
				}

				// score.playAnim('boop', true);
				// score.visible = true;

				Paths.playSFX('results/scoreReveal${(rank == "LOSS") ? "-loss" : ""}.wav');
				FlxTween.tween(score, {
					"scale.x": 1,
					"scale.y": 1,
					alpha: 1
				}, 1, {
					ease: FlxEase.expoIn,
					onComplete: _ ->
					{
						scoreBump.visible = true;
						FlxTween.tween(scoreBump, {
							"scale.x": 1.6,
							"scale.y": 1.6,
							alpha: 0
						}, 2.2, {
							ease: FlxEase.expoOut,
							onComplete: _ -> scoreBump.kill()
						});
						scoreNum.scoreShit = stats.score;
						scoreNum.animateNumbers();
						scoreNum.visible = true;
					}
				});
				final pos = 128;
				new FlxTimer().start(1, (_) ->
				{
					FlxTween.tween(this, {
						accTemp: Std.int(stats.accuracy)
					}, 2, {
						ease: FlxEase.quadOut,
						onUpdate: (_) ->
						{
							clear.text = '$accTemp%';
							clear.x = FlxG.width - clear.width - pos;
						},
						onComplete: (_) ->
						{
							clear.text = '${Std.int(stats.accuracy)}%';
							clear.x = FlxG.width - clear.width - pos;

							FlxTween.color(clear, 1, rankData.color, FlxColor.WHITE);
							Paths.playSFX('results/reveal$rank.ogg');

							if (rank != 'LOSS')
							{
								clear.scale.set(1.3, 1.3);
								FlxTween.tween(clear.scale, {
									x: 1,
									y: 1
								}, 1.3, {
									ease: FlxEase.elasticOut
								});
								FlxTween.tween(clear, {
									y: FlxG.height - clear.height - 16
								}, 1.6, {
									ease: FlxEase.expoInOut,
									startDelay: 0.6
								});
							}
							else
							{
								FlxTween.tween(clear, {
									y: clear.y + 300,
									"scale.y": 0.6
								}, 2, {
									ease: FlxEase.bounceOut,
									onComplete: (_) -> FlxTween.tween(clear, {
										alpha: 0
									}, 0.6, {
										startDelay: 0.2
									})
								});
							}

							for (t in bgTxts)
							{
								t.alpha = 0;
								t.visible = true;
							}

							FlxTween.tween(textInfo, {
								y: bb.y + bb.height - 42
							}, 1, {
								ease: FlxEase.backOut
							});
							textInfo.setText('${diff.toUpperCase()}  //  ${stats.accuracy}%  //  ${chartMeta.displayName} by ${chartMeta.artist}');

							Global.scriptCall('onIntroEnd');
						}
					});
				});
			});
		});
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		Global.scriptCall('onUpdate', [elapsed]);

		if (MoonInput.justPressed(ACCEPT) || MoonInput.justPressed(BACK))
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.onComplete = null;
				FlxTween.tween(FlxG.sound.music, {
					pitch: 4
				}, 0.2, {
					onComplete: _ ->
					{
						FlxTween.tween(FlxG.sound.music, {
							pitch: 0,
							volume: 0
						}, 0.4, {
							onComplete: _ -> FlxG.sound.music.kill()
						});
					}
				});
			}
			openSubState(new StickerSubState(new MainMenu()));
		}
	}

	function set_accTemp(a:Int):Int
	{
		if (accTemp != a) Paths.playSFX('ui/scrollMenu.ogg');

		accTemp = a;

		return accTemp;
	}
}
