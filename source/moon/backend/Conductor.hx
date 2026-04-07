package moon.backend;

import lime.app.Event;

/**
 * Conductor made entirely by [SomeGuyWhoLovesCoding](https://github.com/SomeGuyWhoLovesCoding)
 * Revamped math by [sword_352](https://github.com/Sword352).
 * All I made here was to make some few changes that I am comfortable with, so all credits goes to them.
 */
@:publicFields
class Conductor
{
	// - Conductor's events.
	var onStep:Event<Float->Void> = new Event<Float->Void>();
	var onBeat:Event<Float->Void> = new Event<Float->Void>();
	var onMeasure:Event<Float->Void> = new Event<Float->Void>();

	// - Crochet values.
	var stepCrochet(default, null):Float = 150;
	var crochet(default, null):Float = 600;
	var measureCrochet(default, null):Float = 2400;

	// - Beats per Minute.
	var bpm(default, null):Float = 100;

	//- Whenever the conductor's active.
	var active:Bool;

	// - And the time (usually based on song position.)
	var time(default, set):Float = 0;

	var catchUp:Bool = false;

	function set_time(value:Float):Float
	{
	    time = value;
	    final calc = (time - offsetTime);
	    _stepTracker = Math.ffloor(stepOffset + calc / stepCrochet);
	    _beatTracker = Math.ffloor(beatOffset + calc / crochet);
	    _measureTracker = Math.ffloor(measureOffset + calc / measureCrochet);

	    if (active)
	    {
	        if (curStep != _stepTracker)
	        {
	            final dir = (_stepTracker > curStep) ? 1 : -1;
	            if (Math.abs(_stepTracker - curStep) > 8)
	                catchUp = true;

	            while (curStep != _stepTracker)
	            {
	                curStep += dir;
	                if (!catchUp)
	                    onStep.dispatch(curStep);
	            }
	            catchUp = false;
	        }

	        if (curBeat != _beatTracker)
	        {
	            final dir = (_beatTracker > curBeat) ? 1 : -1;
	            if (Math.abs(_beatTracker - curBeat) > 2)
	                catchUp = true;

	            while (curBeat != _beatTracker)
	            {
	                curBeat += dir;
	                if (!catchUp)
	                    onBeat.dispatch(curBeat);
	            }
	            catchUp = false;
	        }

	        if (curMeasure != _measureTracker)
	        {
	            final dir = (_measureTracker > curMeasure) ? 1 : -1;
	            while (curMeasure != _measureTracker)
	            {
	                curMeasure += dir;
	                onMeasure.dispatch(curMeasure);
	            }
	        }
	    }
	    else
	    {
	        curStep = _stepTracker;
	        curBeat = _beatTracker;
	        curMeasure = _measureTracker;
	    }

	    return value;
	}

	/**
		The step counter.
	**/
	var curStep(default, null):Float = 0;

	/**
		The beat counter.
	**/
	var curBeat(default, null):Float = 0;

	/**
		The measure counter.
	**/
	var curMeasure(default, null):Float = 0;

	/**
		The step tracker.
	**/
	private var _stepTracker(default, null):Float = 0;

	/**
		The beat tracker.
	**/
	private var _beatTracker(default, null):Float = 0;
	private var _measureTracker(default, null):Float = 0;
	var offsetTime(default, null):Float = 0;
	var stepOffset(default, null):Float = 0;
	var beatOffset(default, null):Float = 0;
	var measureOffset(default, null):Float = 0;

	// - These are for time signature's steps/beats.
	var numerator:Float = 4;
	var denominator:Float = 4;

	/**
		Change the conductor's beats per minute.
		This also includes time signatures.
		@param position The position you want to execute the event on.
		@param newBpm The new beats per minute.
		@param newNumerator The new numerator of the time signature.
		@param newDenominator The new denominator of the time signature.
	**/
	inline function changeBpmAt(position:Float, newBpm:Float = 0, newNumerator:Float = 4, newDenominator:Float = 4):Void
	{
		final calc = (position - offsetTime);
		stepOffset += calc / stepCrochet;
		beatOffset += calc / crochet;
		measureOffset += calc / measureCrochet;
		offsetTime = position;

		if (newBpm > 0) 
		{
			bpm = newBpm;
			stepCrochet = 60000 / (bpm * 4);
		}
		
		numerator = newNumerator;
		denominator = newDenominator;
		
		crochet = stepCrochet * numerator;
		measureCrochet = crochet * denominator;
	}

	/**
		Reset the conductor.
	**/
	inline function reset():Void
	{
		offsetTime = stepOffset = beatOffset = measureOffset = time = 0.0;
		curStep = curBeat = curMeasure = 0;
		changeBpmAt(0);
	}

	/**
		Constructs a conductor.
		@param initialBpm The initial beats per minute.
	**/
	inline function new(initialBpm:Float = 100, initialNumerator:Float = 4, initialDenominator:Float = 4):Void
	{
		changeBpmAt(0, initialBpm, initialNumerator, initialDenominator);
		active = true;
	}
}