package moon.dependency.scripting._internal.references;

import moon.dependency.scripting._internal.Expr;

class EnumReference implements Reference<Enum<Dynamic>>
{
	public final object:Enum<Dynamic>;

	final values:Array<String>;

	public function new(object:Enum<Dynamic>)
	{
		this.object = object;
		values = Type.getEnumConstructs(object);
	}

	public function get(field:String):Dynamic
	{
		return Type.createEnum(object, field);
	}

	public function set(field:String, value:Dynamic):Dynamic
	{
		// You shouldn't be able to set a `Enum`!
		throw ErrorDef.EInvalidOp("=");
	}

	public function exists(field:String):Bool
	{
		return values.contains(field);
	}

	public function call(field:String, args:Array<Dynamic>):Dynamic
	{
		// close enough
		return Type.createEnum(object, field, args);
	}
}
