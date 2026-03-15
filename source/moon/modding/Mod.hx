package moon.modding;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import moon.backend.data.MZip;

using StringTools;
@:publicFields

/**
 * Represents one single mod.
 */
class Mod
{
	var name:String;
	var metadata:ModMetadata = {
		name: "None"
	};
	var root:String = "";

	public function new(name:String, root:String)
	{
		this.name = name;
		this.root = root;
		loadMetadata();
	}

	function loadMetadata()
	{
		#if sys
		final meta = '$root/mod_metadata.json';
		if (FileSystem.exists(meta))
			metadata = Json.parse(File.getContent(meta));
		#end
	}

	/**
	 * Returns a path if this mod contains the certain asset.
	 */
	function getAsset(path:String, ?library:String):Null<String>
	{
		#if sys
		final relative = (library != null ? '$library/' : '') + path;
		final modded = '$root/$relative';
		if (FileSystem.exists(modded)) return modded;
		#end
		return null;
	}
}

typedef ModMetadata = {
	/**
	 * The mod's name.
	 */
	var name:String;

	/**
	 * The mod's description.
	 */
	var ?description:String;

	/**
	 * The mod's team, each array member having a `name` and `role` field.
	 */
	var ?team:Array<{name:String, role:String}>;

	/**
	 * The mod's version.
	 */
	var ?version:String;

	/**
	 * The date this mod got released.
	 */
	var ?releaseDate:String;
};