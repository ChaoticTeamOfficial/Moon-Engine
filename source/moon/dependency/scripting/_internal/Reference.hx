package moon.dependency.scripting._internal;

interface Reference<T>
{
	final object:T;
	function get(field:String):Dynamic;
	function set(field:String, value:Dynamic):Dynamic;
	function exists(field:String):Bool;
	function call(field:String, args:Array<Dynamic>):Dynamic;
}

interface ConstructibleReference<T> extends Reference<T>
{
	function construct(args:Array<Dynamic>):Dynamic;
}
