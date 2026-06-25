package moon.backend.data;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.zip.Writer;
import haxe.zip.Entry;
import haxe.zip.Reader;
import haxe.io.BytesInput;
import sys.io.File;

@:publicFields
/**
 * A class that supports zip file reading. I did not use it, but it was a fun experiment!
 */
class MZip
{
	/**
	 * Creates a zipped Moon Char file.
	 * @param fileMap A map containing every file and its bytes.
	 * @param outputPath The path in which the file will be saved.
	 */
	static function create(fileMap:Map<String, Bytes>, outputPath:String):Void
	{
		var output = new BytesOutput();
		var entries = new List<Entry>();

		// we first iterate through the map
		for (name in fileMap.keys())
		{
			// then get the data for the current file
			var data = fileMap.get(name);

			// fetch its entry so we can add it to the list
			var entry:Entry = {
				fileName: name,
				fileSize: data.length,
				fileTime: Date.now(),
				dataSize: data.length,
				data: data,
				compressed: false,
				crc32: haxe.crypto.Crc32.make(data)
			};
			entries.add(entry);
		}

		// then we write all the files on the zip, and save it
		new Writer(output).write(entries);
		File.saveBytes(outputPath, output.getBytes());
	}

	/**
	 * Reads the zip file.
	 * @param path The zip's path.
	 * @return The entry list on the zip.
	 */
	static function read(path:String):List<Entry> return Reader.readZip(new BytesInput(File.getBytes(path)));

	/**
	 * Reads the zip and lists all the files.
	 * @param path The zip's path.
	 * @return an string array of all the files in it.
	 */
	static function listFiles(path:String):Array<String> return[for (e in read(path)) e.fileName];

	/**
	 * Extracts an specific file from the zip.
	 * @param path The zip's path.
	 * @param fileName The file to be extracted.
	 * @return The file's bytes.
	 */
	static function extract(path:String, fileName:String):Bytes
	{
		for (entry in read(path))
		{
			if (entry.fileName == fileName) return Reader.unzip(entry);
		}

		throw 'File not found in .mzip: $fileName';
	}
}
