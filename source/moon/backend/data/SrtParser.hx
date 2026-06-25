package moon.backend.data;

import moon.backend.data.Chart.EventStruct;

using StringTools;

/**
 * Just a class used for converting srt files into a regular event.
 */
class SrtParser
{
	/**
	 * Parses a SRT file's content into an array of events.
	 * @param srtContent The content on the file.
	 * @param conductor The conductor, which will be used to convert duration into steps.
	 */
	public static function parse(srtContent:String, conductor:Conductor):Array<EventStruct>
	{
		final events:Array<EventStruct> = [];
		final normalized = srtContent.trim().replace('\r\n', '\n').replace('\r', '\n');
		final blocks = normalized.split('\n\n');

		for (block in blocks)
		{
			final lines = block.trim().split('\n');
			if (lines.length < 3) continue;

			// lines[0] is the index number, skip it
			// oh FUCK
			final timeLine = lines[1].trim();
			final parts = timeLine.split(' --> ');
			if (parts.length < 2) continue;

			// oops
			final startMs = parseTimestamp(parts[0].trim());
			final endMs = parseTimestamp(parts[1].trim());
			if (startMs < 0 || endMs < 0) continue;

			final text = [for (i in 2...lines.length) lines[i].trim()].join('\n');

			events.push({
				tag: 'Show Subtitle',
				values: {
					text: text,
					duration: msToSteps(endMs - startMs, conductor)
				},
				time: startMs,
				lane: 4
			});
		}

		events.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
		return events;
	}

	static function parseTimestamp(ts:String):Float
	{
		final commaIdx = ts.indexOf(',');
		if (commaIdx == -1) return -1;

		final ms = Std.parseFloat(ts.substr(commaIdx + 1));
		final parts = ts.substr(0, commaIdx).split(':');
		if (parts.length < 3) return -1;

		return (Std.parseFloat(parts[0]) * 3600 + Std.parseFloat(parts[1]) * 60 + Std.parseFloat(parts[2])) * 1000 + ms;
	}

	static function msToSteps(ms:Float, conductor:Conductor):Float return ms / conductor.stepCrochet;
}
