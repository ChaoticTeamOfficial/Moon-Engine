package moon.backend.gameplay;

import flixel.util.FlxColor;

/**
 * Data for a single judgement tier.
 */
typedef JudgementData =
{
	var maxMs:Float;
	var score:Int;
	var healthGain:Float;
	var color:FlxColor;
}

enum abstract TimingProfile(String) to String from String
{
	var CLASSIC = "Classic";
	var STRICT = "Strict";
	// TODO: add more later.
}

enum abstract AccuracySystem(String) to String from String
{
	var WEIGHTED = "Weighted";
	var OSU_MANIA = "Osu Mania";
	var QUAVER = "Quaver";
	// TODO: more?
}

/**
 * Data for a single rank.
 */
typedef RankData =
{
	var limit:Float;
	var rank:String;
	var short:String;
	var color:FlxColor;
}

/**
 * All valid judgement names.
 */
enum abstract Judgement(String) to String from String
{
	var SICK = 'sick';
	var GOOD = 'good';
	var BAD = 'bad';
	var SHIT = 'shit';
	var MISS = 'miss';
}

@:publicFields
/**
 * The class that handles timings and everything related to them.
 */
class Timings
{
	static var currentProfile:TimingProfile = CLASSIC;
	static var currentAccuracy:AccuracySystem = WEIGHTED;
	// TODO: make this less redundant. I kinda hate that I have to copy paste some stuff.
	// so maybe separate some helpers. idk.
	static final profiles:Map<TimingProfile, Map<Judgement, JudgementData>> = [
		CLASSIC => [
			SICK => {
				maxMs: 50,
				score: 350,
				healthGain: 2.0,
				color: 0xFF2883ff
			},
			GOOD => {
				maxMs: 100,
				score: 150,
				healthGain: 1.0,
				color: 0xFF44cd4d
			},
			BAD => {
				maxMs: 135,
				score: 0,
				healthGain: 0.5,
				color: 0xFFa8738a
			},
			SHIT => {
				maxMs: 160,
				score: -50,
				healthGain: -1.0,
				color: 0xFF59443f
			},
			MISS => {
				maxMs: 180,
				score: -600,
				healthGain: -4.5,
				color: 0xFF894331
			}
		],
		STRICT => [
			SICK => {
				maxMs: 30,
				score: 350,
				healthGain: 2.0,
				color: 0xFF2883ff
			},
			GOOD => {
				maxMs: 60,
				score: 150,
				healthGain: 1.0,
				color: 0xFF44cd4d
			},
			BAD => {
				maxMs: 110,
				score: 0,
				healthGain: 0.5,
				color: 0xFFa8738a
			},
			SHIT => {
				maxMs: 120,
				score: -50,
				healthGain: -1.0,
				color: 0xFF59443f
			},
			MISS => {
				maxMs: 160,
				score: -600,
				healthGain: -4.5,
				color: 0xFF894331
			}
		]
	];

	/**
	 * All ranks and their thresholds.
	 */
	static final thresholds:Array<RankData> = [
		{
			limit: 60,
			rank: 'LOSS',
			short: 'L',
			color: 0xFF6044FF
		},
		{
			limit: 80,
			rank: 'GOOD',
			short: 'G',
			color: 0xFFEF8764
		},
		{
			limit: 90,
			rank: 'GREAT',
			short: 'G',
			color: 0xFFEAF6FF
		},
		{
			limit: 98,
			rank: 'EXCELLENT',
			short: 'E',
			color: 0xFFC9A33B
		},
		{
			limit: 100,
			rank: 'PERFECT',
			short: 'P',
			color: 0xFFFF58B4
		},
		{
			limit: 101,
			rank: 'PERFECT-GOLD',
			short: 'P',
			color: 0xFFFFB619
		}
	];

	static final values:Array<Judgement> = [
		SICK,
		GOOD,
		BAD,
		SHIT,
		MISS
	];

	/**
	 * Returns rank data for a given accuracy value.
	 */
	static function getRank(accuracy:Float):RankData
	{
		for (t in thresholds) if (accuracy < t.limit) return t;

		return {
			limit: 0,
			rank: 'NOT FOUND.',
			short: 'N',
			color: FlxColor.WHITE
		};
	}

	/**
	 * Returns typed judgement data for a given judgement.
	 */
	static function get(j:Judgement):JudgementData return profiles.get(currentProfile).get(j);

	static function getAccuracyWeight(j:Judgement):Float
	{
		return switch (currentAccuracy)
		{
			case WEIGHTED:
				switch (j)
				{
					case SICK:
						1.0;
					case GOOD:
						0.5;
					case BAD:
						-0.02;
					case SHIT:
						-0.5;
					case MISS:
						-1.0;
				}

			case OSU_MANIA:
				switch (j)
				{
					case SICK:
						1.0;
					case GOOD:
						1.0;
					case BAD:
						2 / 3;
					case SHIT:
						1 / 3;
					case MISS:
						0;
				}

			case QUAVER:
				switch (j)
				{
					case SICK:
						1.0;
					case GOOD:
						0.9825;
					case BAD:
						0.65;
					case SHIT:
						0.25;
					case MISS:
						-0.5;
				}
		}
	}
}
