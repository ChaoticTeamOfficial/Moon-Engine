package moon.dependency.scripting._internal.references;

class StaticClassReference implements ConstructibleReference<Class<Dynamic>>
{
	public final object:Class<Dynamic>;

	var fields:Array<String>;

	public function new(object:Class<Dynamic>)
	{
		this.object = object;
		fields = Type.getClassFields(object);
	}

	public function get(field:String):Dynamic
	{
		return Reflect.getProperty(object, field);
	}

	public function set(field:String, value:Dynamic):Dynamic
	{
		Reflect.setProperty(object, field, value);
		return value;
	}

	public function exists(field:String):Bool
	{
		return fields.contains(field);
	}

	public function call(field:String, args:Array<Dynamic>):Dynamic
	{
		var realFunc:Dynamic = get(field);
		return Reflect.callMethod(object, realFunc, args);
	}

	public function construct(args:Array<Dynamic>):Dynamic
	{
		return Type.createInstance(object, args);
	}
}
