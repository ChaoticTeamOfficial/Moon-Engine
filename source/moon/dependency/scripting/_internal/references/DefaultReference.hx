package moon.dependency.scripting._internal.references;

class DefaultReference implements Reference<Dynamic>
{
	public final object:Dynamic;

	var fields:Array<String>;

	public function new(object:Dynamic)
	{
		this.object = object;
		fields = Reflect.fields(object);
	}

	public function get(field:String):Dynamic
	{
		return Reflect.getProperty(object, field);
	}

	public function set(field:String, value:Dynamic):Dynamic
	{
		Reflect.setProperty(object, field, value);
		if (!fields.contains(field)) fields.push(field);

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
}

class ClassReference extends DefaultReference
{
	public function new(object:Dynamic)
	{
		super(object);

		final cls:Class<Dynamic> = Type.getClass(object);
		fields = fields.concat(Type.getInstanceFields(cls));
	}
}
