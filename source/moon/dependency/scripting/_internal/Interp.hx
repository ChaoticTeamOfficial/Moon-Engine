package moon.dependency.scripting._internal;

import haxe.iterators.ArrayIterator;
import moon.dependency.scripting._internal.Expr;
import moon.dependency.scripting._internal.Reference;
import haxe.PosInfos;
import haxe.Constraints.IMap;

/**
 * Based on code by Ian Harrigan
 * @see https://github.com/ianharrigan/hscript-ex
 */
@:access(polymod.hscript._internal.PolymodAbstractScriptClass)
@:access(polymod.hscript._internal.PolymodScriptClass)
@:access(polymod.hscript._internal.PolymodEnum)
class Interp
{
	var _propTrack:Map<String, Bool> = [];
	var _references:Array<Reference<Dynamic>> = [];

	static var defaultVariables:Map<String, Dynamic>;

	public var variables:Map<String, Dynamic>;

	/**
	 * The classes imported by the scripted class
	 * This gets resolved at interpretation time to save performance and improve sandboxing
	 */
	public var imports:Map<String, ClassImport>;

	/**
	 * The static extensions used by the scripted class
	 * For example, `using StringTools` lets you call `String.replace` on a string directly.
	 */
	public var usings:Map<String, ClassImport>;

	var locals:Map<String,
		{r:Dynamic, ?isfinal:Bool}>;
	var binops:Map<String, Expr->Expr->Dynamic>;
	var depth:Int;
	var inTry:Bool;
	var declared:Array<
		{
			n:String,
			old:
				{r:Dynamic, ?isfinal:Bool}
		}>;
	var returnValue:Dynamic;
	var curExpr:Expr;

	function getClassDecl():Null<ClassDecl>
	{
		// TODO: implement this
		return null;
	}

	function getClassFullyQualifiedName():Null<String>
	{
		return null;
	}

	public function new()
	{
		locals = new Map();
		declared = [];
		depth = 0;
		inTry = false;
		resetVariables();
		initOps();

		imports = [];
		usings = [];
	}

	function cnew(cl:String, args:Array<Dynamic>):Dynamic
	{
		final reference:Null<Reference<Dynamic>> = fetchReference(resolve(cl));

		if (reference != null && Std.isOfType(reference, ConstructibleReference))
		{
			final constrRef:ConstructibleReference<Dynamic> = cast reference;
			return constrRef.construct(args);
		}

		return error(EInvalidModule(cl));
	}

	private var _nextCallObject:Dynamic = null;

	/**
	 * Call a given function on a given target with the given arguments.
	 * @param target The object to call the function on.
	 *   If null, defaults to `this`.
	 * @param fun The function to call.
	 * @param args The arguments to apply to that function.
	 * @return The result of the function call.
	 */
	function call(target:Dynamic, fun:Dynamic, args:Array<Dynamic>):Null<Dynamic>
	{
		// Calling fn() in hscript won't resolve an object first. Thus, we need to change it to use this.fn() instead.
		if (target == null && _nextCallObject != null)
		{
			target = _nextCallObject;
		}

		if (fun == null)
		{
			error(EInvalidAccess(fun));
		}

		/*if (target != null && target == _proxy)
			{
				// If we are calling this.fn(), special handling is needed to prevent the local scope from being destroyed.
				// By checking `target == _proxy`, we handle BOTH fn() and this.fn().
				// super.fn() is exempt since it is not scripted.
				return callThis(fun, args);
			}
			else */
		{
			try
			{
				var result = Reflect.callMethod(target, fun, args);
				_nextCallObject = null;
				return result;
			}
			catch (e:Dynamic)
			{
				_nextCallObject = null;

				if (Std.isOfType(e, Error))
				{
					throw e;
				}
				return error(EScriptCallThrow(e));
			}
			return null;
		}
	}

	/**
	 * Note to self: Calls to `this.xyz()` will have the type of `o` as `polymod.hscript.PolymodScriptClass`.
	 * Calls to `super.xyz()` will have the type of `o` as `stage.ScriptedStage`.
	 */
	function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic
	{
		// TODO: fix infinite recursion for using `this`
		final reference:Null<Reference<Dynamic>> = fetchReference(o);
		if (reference != null) return reference.call(f, args);

		return error(EInvalidAccess(f));
	}

	/**
	 * Call a given function on the current proxy with the given arguments.
	 * Ensures that the local scope is not destroyed.
	 * @param fun The function to call.
	 * @param args The arguments to apply to that function.
	 * @return The result of the function call.
	 */
	/*function callThis(fun:Dynamic, args:Array<Dynamic>):Dynamic
		{
			// If we are calling this.fn(), special handling is needed to prevent the local scope from being destroyed.
			// Store the local scope.
			var capturedLocals = this.duplicate(locals);
			var capturedDeclared = this.declared;
			var capturedDepth = this.depth;

			this.depth++;

			// Call the function.
			try
			{
				var result = Reflect.callMethod(_proxy, fun, args);

				// Restore the local scope.
				this.locals = capturedLocals;
				this.declared = capturedDeclared;
				this.depth = capturedDepth;

				return result;
			}
			catch (e:Dynamic)
			{
				// Restore the local scope.
				this.locals = capturedLocals;
				this.declared = capturedDeclared;
				this.depth = capturedDepth;

				if (Std.isOfType(e, Error))
				{
					throw e;
				}

				return error(EScriptCallThrow(e));
			}
	}*/
	private function resetVariables()
	{
		variables = new Map<String, Dynamic>();
		variables.set("null", null);
		variables.set("true", true);
		variables.set("false", false);
		variables.set("trace", Reflect.makeVarArgs(function(el)
		{
			var inf = posInfos();
			var v = el.shift();
			if (el.length > 0) inf.customParams = el;
			haxe.Log.trace(Std.string(v), inf);
		}));

		variables.set("Math", #if hl polymod.hscript._internal.HLWrapperMacro.HLMath #else Math #end);
		variables.set("Std", #if hl polymod.hscript._internal.HLWrapperMacro.HLStd #else Std #end);

		variables.set("Array", Array);
		variables.set("Bool", Bool);
		variables.set("Dynamic", Dynamic);
		variables.set("Float", Float);
		variables.set("Int", Int);
		variables.set("String", String);

		if (defaultVariables == null)
		{
			defaultVariables = variables.copy();
		}
	}

	public function clearScriptClassDescriptors():Void
	{
		/*// Clear the script class descriptors.
			_scriptClassDescriptors.clear();

			// Also clear the imports from the import.hx files.
			_scriptClassImports.clear();
			_scriptClassUsings.clear();
		 */

		// Also destroy local variable scope.
		this.resetVariables();
	}

	public function clearScriptEnumDescriptors():Void
	{
		// Clear the script enum descriptors.
		// _scriptEnumDescriptors.clear();

		// Also destroy local variable scope.
		this.resetVariables();
	}

	public function posInfos():PosInfos
	{
		if (curExpr != null) return cast {
			fileName: curExpr.origin,
			lineNumber: curExpr.line
		};

		return cast {
			fileName: "hscript",
			lineNumber: 0
		};
	}

	function initOps()
	{
		var me = this;
		binops = new Map();
		binops.set("+", function(e1, e2) return me.expr(e1) + me.expr(e2));
		binops.set("-", function(e1, e2) return me.expr(e1) - me.expr(e2));
		binops.set("*", function(e1, e2) return me.expr(e1) * me.expr(e2));
		binops.set("/", function(e1, e2) return me.expr(e1) / me.expr(e2));
		binops.set("%", function(e1, e2) return me.expr(e1) % me.expr(e2));
		binops.set("&", function(e1, e2) return me.expr(e1) & me.expr(e2));
		binops.set("|", function(e1, e2) return me.expr(e1) | me.expr(e2));
		binops.set("^", function(e1, e2) return me.expr(e1) ^ me.expr(e2));
		binops.set("<<", function(e1, e2) return me.expr(e1) << me.expr(e2));
		binops.set(">>", function(e1, e2) return me.expr(e1) >> me.expr(e2));
		binops.set(">>>", function(e1, e2) return me.expr(e1) >>> me.expr(e2));
		binops.set("==", function(e1, e2) return me.expr(e1) == me.expr(e2));
		binops.set("!=", function(e1, e2) return me.expr(e1) != me.expr(e2));
		binops.set(">=", function(e1, e2) return me.expr(e1) >= me.expr(e2));
		binops.set("<=", function(e1, e2) return me.expr(e1) <= me.expr(e2));
		binops.set(">", function(e1, e2) return me.expr(e1) > me.expr(e2));
		binops.set("<", function(e1, e2) return me.expr(e1) < me.expr(e2));
		binops.set("||", function(e1, e2) return me.expr(e1) == true || me.expr(e2) == true);
		binops.set("&&", function(e1, e2) return me.expr(e1) == true && me.expr(e2) == true);
		binops.set("=", assign);
		binops.set("...", function(e1, e2) return new IntIterator(me.expr(e1), me.expr(e2)));
		binops.set("is", function(e1, e2) return Std.isOfType(me.expr(e1), me.expr(e2)));
		binops.set("??", function(e1, e2) return me.expr(e1) ?? me.expr(e2));
		assignOp("+=", function(v1:Dynamic, v2:Dynamic) return v1 + v2);
		assignOp("-=", function(v1:Float, v2:Float) return v1 - v2);
		assignOp("*=", function(v1:Float, v2:Float) return v1 * v2);
		assignOp("/=", function(v1:Float, v2:Float) return v1 / v2);
		assignOp("%=", function(v1:Float, v2:Float) return v1 % v2);
		assignOp("&=", function(v1, v2) return v1 & v2);
		assignOp("|=", function(v1, v2) return v1 | v2);
		assignOp("^=", function(v1, v2) return v1 ^ v2);
		assignOp("<<=", function(v1, v2) return v1 << v2);
		assignOp(">>=", function(v1, v2) return v1 >> v2);
		assignOp(">>>=", function(v1, v2) return v1 >>> v2);
		assignOp("??" + "=", function(v1, v2) return v1 ?? v2);
	}

	function setVar(id:String, v:Dynamic):Dynamic
	{
		/*if (_proxy != null && _proxy.superHasField(id))
			{
				if (Std.isOfType(_proxy.superClass, PolymodScriptClass))
				{
					var superClass:PolymodAbstractScriptClass = cast(_proxy.superClass, PolymodScriptClass);
					return superClass.fieldWrite(id, v);
				}
				else
				{
					set(_proxy.superClass, id, v);
					return v;
				}
		}*/

		// Fallback to setting in local scope.
		variables.set(id, v);
		return v;
	}

	/**
	 * Initializes function arguments within the interpreter scope.
	 *
	 * @param fn The function declaration to extract arguments from.
	 * @param args The arguments to pass to the function.
	 * @param name The function's name
	 * @return The Map containing the variable values before they are shadowed in the local scope.
	 */
	public function setFunctionValues(fn:Null<FunctionDecl>, args:Array<Dynamic> = null, name:String = "Unknown"):Map<String, Dynamic>
	{
		var previousValues:Map<String, Dynamic> = [];
		if (fn == null) return previousValues;

		validateArgumentCount(fn.args, args, name);

		var i = 0;
		for (a in fn.args)
		{
			var value:Dynamic = null;

			// Uses the passed value if provided and not null, if not fall back to the default value defined in the function argument.
			if (args != null && i < args.length && args[i] != null)
			{
				value = args[i];
			}
			else if (a.value != null)
			{
				value = this.expr(a.value);
			}

			// NOTE: We assign these as variables rather than locals because those get wiped when we enter the function.
			if (this.variables.exists(a.name))
			{
				previousValues.set(a.name, this.variables.get(a.name));
			}
			this.variables.set(a.name, value);
			i++;
		}

		return previousValues;
	}

	function assign(e1:Expr, e2:Expr):Dynamic
	{
		return assignValue(e1, expr(e2));
	}

	function assignValue(e1:Expr, v:Dynamic, _abstractInlineAssign:Bool = false):Null<Dynamic>
	{
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				// Make sure setting superclass fields directly works.
				// Also ensures property functions are accounted for.
				/*if (_proxy != null && _proxy.superHasField(id))
					{
						if (Std.isOfType(_proxy.superClass, PolymodScriptClass))
						{
							var superClass:PolymodAbstractScriptClass = cast(_proxy.superClass, PolymodScriptClass);
							return superClass.fieldWrite(id, v);
						}

						// Directly assign the value.
						// This is needed because `assignValue` may sometimes be called from the constructor.
						PolymodAbstractScriptClass.setClassObjectField(_proxy.superClass, id, v);
						return v;
				}*/
				/*@:privateAccess
					{
						if (_proxy != null)
						{
							var decl = _proxy.findVar(id);
							switch (decl?.set)
							{
								case "set":
									// Allow assigning to "null" only for local fields.
									final setName = 'set_$id';
									if (!_propTrack.exists(setName))
									{
										_propTrack.set(setName, true);
										var out = _proxy.callFunction(setName, [v]);
										_propTrack.remove(setName);
										return (out == null) ? v : out;
									}

								case "never":
									error(EInvalidPropSet(id));
									return null;

								case "null":
									// If the property setter is "null", it can only be assigned on local fields.
									// Thankfully, this is a local field!
									// So we can just fallthrough to the default case.
							}

							if ((decl?.isfinal ?? false) && decl?.expr != null)
							{
								error(EInvalidFinalSet(id));
								return null;
							}
						}
				}*/

				var l = locals.get(id);
				if (l != null && l.isfinal && l.r != null) return error(EInvalidAccess(id));
				if (l == null) setVar(id, v);
				else
					l.r = v;
			case EField(e0, id):
				// Make sure setting superclass fields works when using this.
				// Also ensures property functions are accounted for.
				/*switch (Tools.expr(e0))
					{
						case EIdent(id0):
							if (id0 == "this")
							{
								if (_proxy != null && _proxy.superHasField(id))
								{
									if (Std.isOfType(_proxy.superClass, PolymodScriptClass))
									{
										var superClass:PolymodAbstractScriptClass = cast(_proxy.superClass, PolymodScriptClass);
										return superClass.fieldWrite(id, v);
									}

									// Directly assign the value.
									// This is needed because `assignValue` may sometimes be called from the constructor.
									PolymodAbstractScriptClass.setClassObjectField(_proxy.superClass, id, v);
									return v;
								}
							}
							else
							{
								@:privateAccess
								{
									// Check if we are setting a final. If so, throw an error.
									if (_proxy != null && _proxy._c != null)
									{
										for (imp in _proxy._c.imports)
										{
											if (imp.name != id0) continue;
											var finals = PolymodFinalMacro.getFinals(imp.fullPath);

											if (finals.contains(id))
											{
												error(EInvalidFinalSet(id));
												return null;
											}

											var privates = PolymodFinalMacro.getPrivateProperties(imp.fullPath);

											if (privates.contains(id))
											{
												error(EInvalidPropSet(id));
												return null;
											}
										}
									}
								}
							}
						default:
							// Do nothing
				}*/

				// Fallback to field set
				v = set(expr(e0), id, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					setMapValue(arr, index, v);
				}
				else
				{
					arr[index] = v;
				}

			default:
				if (!_abstractInlineAssign)
				{
					error(EInvalidOp("="));
				}
		}
		return v;
	}

	function assignOp(op, fop:Dynamic->Dynamic->Dynamic)
	{
		var me = this;
		binops.set(op, function(e1, e2) return me.evalAssignOp(op, fop, e1, e2));
	}

	function evalAssignOp(op, fop, e1, e2):Dynamic
	{
		var v:Dynamic = null;

		switch (Tools.expr(e1))
		{
			case EIdent(id):
				/*@:privateAccess
					{
						if (_proxy != null)
						{
							var decl = _proxy.findVar(id);
							if (decl != null)
							{
								var value = switch (decl.get)
								{
									case "never":
										error(EInvalidPropGet(id));
									default:
										expr(e1);
								}

								v = fop(value, expr(e2));

								switch (decl.set)
								{
									case "set":
										final setName = 'set_$id';
										if (!_propTrack.exists(setName))
										{
											_propTrack.set(setName, true);
											var r = _proxy.callFunction(setName, [v]);
											_propTrack.remove(setName);
											return r;
										}
									// Fallback
									case "never":
										error(EInvalidPropSet(id));
										return v;
								}
							}
						}
				}*/

				// Fallback to local variable
				var l = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l != null && l.isfinal && l.r != null) return error(EInvalidAccess(id));
				if (l == null) setVar(id, v)
				else
					l.r = v;
			case EField(e, f):
				var obj = expr(e);
				v = fop(get(obj, f), expr(e2));
				v = set(obj, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				}
				else
				{
					v = fop(arr[index], expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}

	function increment(e:Expr, prefix:Bool, delta:Int):Dynamic
	{
		curExpr = e;

		switch (Tools.expr(e))
		{
			case EIdent(id):
				/*@:privateAccess
					{
						if (_proxy != null)
						{
							var decl = _proxy.findVar(id);
							if (decl != null)
							{
								var v = switch (decl.get)
								{
									case "never":
										error(EInvalidPropGet(id));
									default:
										expr(e);
								}

								if (prefix) v += delta;

								switch (decl.set)
								{
									case "set":
										final setName = 'set_$id';
										if (!_propTrack.exists(setName))
										{
											_propTrack.set(setName, true);
											var r = _proxy.callFunction(setName, [prefix ? v : (v + delta)]);
											_propTrack.remove(setName);
											return r;
										}
									case "never":
										return error(EInvalidPropSet(id));
								}
							}
						}
				}*/

				var l = locals.get(id);
				var v:Dynamic = (l == null) ? resolve(id) : l.r;
				if (l != null && l.isfinal && l.r != null) return error(EInvalidFinalSet(id));
				if (prefix)
				{
					v += delta;
					if (l == null) setVar(id, v)
					else
						l.r = v;
				}
				else if (l == null) setVar(id, v + delta)
				else
					l.r = v + delta;
				return v;
			case EField(e, f):
				var obj = expr(e);
				var v:Dynamic = get(obj, f);
				if (prefix)
				{
					v += delta;
					set(obj, f, v);
				}
				else
					set(obj, f, v + delta);
				return v;
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					var v = getMapValue(arr, index);
					if (prefix)
					{
						v += delta;
						setMapValue(arr, index, v);
					}
					else
					{
						setMapValue(arr, index, v + delta);
					}
					return v;
				}
				else
				{
					var v = arr[index];
					if (prefix)
					{
						v += delta;
						arr[index] = v;
					}
					else
						arr[index] = v + delta;
					return v;
				}
			default:
				return error(EInvalidOp((delta > 0) ? "++" : "--"));
		}
	}

	public function execute(expr:Expr):Null<Dynamic>
	{
		// If this function is being called (and not executeEx),
		// PolymodScriptClass is not being used to call the expression.
		// This happens during callbacks and in some other niche cases.
		// In this case, we know the parent caller doesn't have error handling!
		// That means we have to do it here.
		try
		{
			return executeEx(expr);
		}
		catch (err:Expr.Error)
		{
			// PolymodScriptClass.reportError(err, getClassFullyQualifiedName());
			return null;
		}
		catch (err:Dynamic)
		{
			throw err;
		}
	}

	public function executeEx(expr:Expr):Dynamic
	{
		// Directly call execute (assume error handling happens higher).
		depth = 0;
		locals = new Map();
		declared = new Array();
		return exprReturn(expr);
	}

	function exprReturn(e):Null<Dynamic>
	{
		try
		{
			return expr(e);
		}
		catch (e:Stop)
		{
			switch (e)
			{
				case SBreak:
					throw "Invalid break";
				case SContinue:
					throw "Invalid continue";
				case SReturn:
					var v = returnValue;
					returnValue = null;
					return v;
			}
		}
		return null;
	}

	function duplicate<T>(h:Map<String, T>)
	{
		var h2 = new Map();
		for (k in h.keys()) h2.set(k, h.get(k));
		return h2;
	}

	function restore(old:Int)
	{
		while (declared.length > old)
		{
			var d = declared.pop();
			locals.set(d.n, d.old);
		}
	}

	public inline function error(e:ErrorDef, rethrow = false):Null<Dynamic>
	{
		var e = new Error(e, curExpr?.pmin ?? 0, curExpr?.pmax ?? 0, curExpr?.origin ?? 'unknown', curExpr?.line ?? 0);
		trace(e);
		/*if (rethrow) this.rethrow(e)
			else
				throw e; */
		return null;
	}

	inline function rethrow(e:Dynamic)
	{
		#if hl
		hl.Api.rethrow(e);
		#else
		throw e;
		#end
	}

	function resolve(id:String):Null<Dynamic>
	{
		_nextCallObject = null;
		/*if (id == "super")
			{
				if (_proxy == null)
				{
					error(EInvalidInStaticContext("super"));
				}
				else if (_proxy.superClass == null)
				{
					if (_proxy._c.extend == null) error(EClassInvalidSuper);
					return Reflect.makeVarArgs(_proxy.createSuperClass);
				}
				else
				{
					return _proxy.superClass;
				}
			}
			else if (id == "this")
			{
				if (_proxy != null)
				{
					return _proxy;
				}
				else
				{
					error(EInvalidInStaticContext("this"));
				}
			}
			else */
		if (id == "null")
		{
			return null;
		}

		if (variables.exists(id))
		{
			// NOTE: id may exist but be null
			return variables.get(id);
		}

		if (imports.exists(id))
		{
			var importedClass:ClassImport = imports.get(id);
			if (importedClass.ref != null) return importedClass.ref.object;

			// If we are here, there is an imported class whose value is null, and it isn't a scripted class.
			// This means that we are attempting to access a BLACKLISTED module.
			error(EBlacklistedModule(importedClass.fullPath));
		}

		// TODO: usings
		// TODO: look through scripted classes for static functions

		// If we're here, the field definitely doesn't exist.
		error(EUnknownVariable(id));

		return null;
	}

	function fetchReference(object:Dynamic):Null<Reference<Dynamic>>
	{
		if (Std.isOfType(object, Reference))
		{
			trace('i just got asked to return a reference for a reference. thats not good');
			return object;
		}

		for (reference in _references)
		{
			if (reference.object == object) return reference;
		}

		final reference:Reference<Dynamic> = Tools.objectRef(object);
		if (reference != null) _references.push(reference);
		return reference;
	}

	/**
	 * Tries to resolve the type of an imported class, which will end up in `cls`, `enm` or `abs`.
	 * @param importedClass The import to resolve.
	 * @param ignoreEnums Whether to skip resolving enums. Used when resolving a `using` import.
	 * @return `false` if this import was blacklisted, otherwise always `true`.
	 */
	function resolveImportedClass(importedClass:ClassImport, ignoreEnums:Bool = false):Bool
	{
		// The path without the possibly included module name, which resolve methods disregard.
		final modulelessPath:String = importedClass.pkg.slice(0, -1).concat([importedClass.name]).join('.');
		for (fullPath in [importedClass.fullPath, modulelessPath])
		{
			var result:Null<Dynamic> = null;

			/*if (PolymodScriptClass.importOverrides.exists(fullPath))
				{
					// importOverrides can exist but be null (if it was set to null).
					// If so, that means the class is blacklisted.
					importedClass.cls = PolymodScriptClass.importOverrides.get(fullPath) ?? return false;
					break;
				}
				else if (PolymodScriptClass.abstractClassImpls.exists(fullPath))
				{
					// We used a macro to map each abstract to its implementation.
					importedClass.abs = PolymodScriptClass.abstractClassImpls.get(fullPath);
					break;
				}
				else if (PolymodScriptClass.typedefs.exists(fullPath))
				{
					importedClass.cls = PolymodScriptClass.typedefs.get(fullPath);
					break;
			}*/

			if (result == null) result = Type.resolveClass(fullPath);
			if (!ignoreEnums && result == null) result = Type.resolveEnum(fullPath);

			final reference:Null<Reference<Dynamic>> = result != null ? fetchReference(result) : null;
			if (reference != null)
			{
				importedClass.ref = reference;
				break;
			}
		}

		return true;
	}

	public function expr(e:Expr):Null<Dynamic>
	{
		curExpr = e;

		switch (Tools.expr(e))
		{
			case EConst(c):
				switch (c)
				{
					case CInt(v):
						return v;
					case CFloat(f):
						return f;
					case CString(s):
						return s;
				}
			case EIdent(id):
				// When resolving a variable, check if it is a property with a getter, and call it if necessary.
				/*@:privateAccess
					{
						if (_proxy != null)
						{
							var decl = _proxy.findVar(id);
							switch (decl?.get)
							{
								case "get":
									final getName = 'get_$id';
									if (_propTrack.exists(getName))
									{
										switch (decl.set)
										{
											case 'set', 'never':
												var field = _proxy.findField(id);
												var hasIsVar = false;
												for (m in field?.meta ?? []) if (m.name == ':isVar')
												{
													hasIsVar = true;
													break;
												}
												if (!hasIsVar) return error(EPropVarNotReal(id));
											default:
										}
									}
									else
									{
										_propTrack.set(getName, true);
										var result = _proxy.callFunction(getName);
										_propTrack.remove(getName);
										return result;
									}
							}
						}
				}*/

				var l = locals.get(id);
				if (l != null) return l.r;
				return resolve(id);
			case EVar(name, type, expression):
				declared.push({
					n: name,
					old: locals.get(name)
				});

				// Evaluate the expression before assigning, applying typing if possible.
				var result = (expression != null) ? exprWithType(expression, type) : null;

				locals.set(name, {
					r: result,
					isfinal: false
				});

				return null;
			case EFinal(name, type, expression):
				declared.push({
					n: name,
					old: locals.get(name)
				});

				// Evaluate the expression before assigning, applying typing if possible.
				var result = (expression != null) ? exprWithType(expression, type) : null;

				locals.set(name, {
					r: result,
					isfinal: true
				});

				return null;
			case EParent(e0):
				return expr(e0);
			case EBlock(exprs):
				var old = declared.length;
				var v = null;
				for (e in exprs) v = expr(e);
				restore(old);
				return v;
			case EField(e, f):
				/*var name = getIdent(e);
					name = getClassDecl().imports.get(name)?.fullPath ?? name;
					if (name != null && _scriptEnumDescriptors.exists(name))
					{
						return new PolymodEnum(_scriptEnumDescriptors.get(name), f, []);
				}*/
				return get(expr(e), f);
			case EBinop(op, e1, e2):
				var fop = binops.get(op);
				if (fop == null) error(EInvalidOp(op));
				return fop(e1, e2);
			case EUnop(op, prefix, e):
				switch (op)
				{
					case "!":
						return expr(e) != true;
					case "-":
						return -expr(e);
					case "++":
						return increment(e, prefix, 1);
					case "--":
						return increment(e, prefix, -1);
					case "~":
						return ~expr(e);
					default:
						error(EInvalidOp(op));
				}
			case ECall(e, params):
				switch (Tools.expr(e))
				{
					case EField(e, f):
						var name = getIdent(e);
						if (name != null)
						{
							/*var imp = getClassDecl().imports.get(name);
								if (imp != null)
								{
									if (_scriptEnumDescriptors.exists(imp.fullPath))
									{
										var args = new Array();
										for (p in params) args.push(expr(p));

										return new PolymodEnum(_scriptEnumDescriptors.get(imp.fullPath), f, args);
									}
									else if (imp.abs != null && imp.abs.hasInlineFunction(f))
									{
										var args = new Array();
										for (p in params) args.push(expr(p));

										return imp.abs.callInlineFunction(this, params[0], f, args);
									}
							}*/
						}
					default:
				}

				var args = new Array();
				for (p in params) args.push(expr(p));

				switch (Tools.expr(e))
				{
					case EField(e, f):
						var obj = expr(e);
						if (obj == null) error(ENullObjectReference(f));
						return fcall(obj, f, args);
					default:
						return call(null, expr(e), args);
				}
			case EIf(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else if (e2 == null) null else expr(e2);
			case EWhile(econd, e):
				whileLoop(econd, e);
				return null;
			case EDoWhile(econd, e):
				doWhileLoop(econd, e);
				return null;
			case EFor(v, it, e):
				forLoop(v, it, e);
				return null;
			case EForGen(it, e):
				Tools.getKeyIterator(it, function(vk, vv, it)
				{
					if (vk == null)
					{
						curExpr = it;
						error(ECustom("Invalid for expression"));
						return;
					}
					forKeyValueLoop(vk, vv, it, e);
				});
				return null;
			case EBreak:
				throw SBreak;
			case EContinue:
				throw SContinue;
			case ECast(e, t):
				return expr(e);
			case EReturn(e):
				returnValue = e == null ? null : expr(e);
				throw SReturn;
			case EFunction(params, fexpr, name, _):
				var capturedLocals = duplicate(this.locals);
				var capturedVariables:Map<String, Dynamic> = [];
				var capturedCallObject = this._nextCallObject;
				// var capturedClassDeclOverride = this._classDeclOverride;
				var me = this;

				// Retrieve only the non-default variables
				for (k => v in variables)
				{
					if (!defaultVariables.exists(k))
					{
						capturedVariables.set(k, v);
					}
				}

				// This CREATES a new function in memory, that we call later.
				var newFun:Dynamic = function(args:Array<Dynamic>)
				{
					if (args == null) args = [];

					validateArgumentCount(params, args, name);

					// make sure mandatory args are forced
					var args2 = [];
					var pos = 0;
					for (p in params)
					{
						if (pos < args.length)
						{
							var arg = args[pos++];
							if (arg == null && p.value != null)
							{
								args2.push(expr(p.value));
							}
							else
							{
								args2.push(arg);
							}
						}
						else
						{
							if (p.value != null)
							{
								args2.push(expr(p.value));
							}
							else
							{
								args2.push(null);
							}
						}
					}
					args = args2;

					var old = me.locals;
					var depth = me.depth;
					var oldCallObject = me._nextCallObject;
					// var oldClsDeclOverride = me._classDeclOverride;
					me.depth++;
					me.locals = duplicate(capturedLocals);
					me._nextCallObject = capturedCallObject;
					// me._classDeclOverride = capturedClassDeclOverride;

					// Restore removed variables (those are usually arguments)
					for (k => v in capturedVariables)
					{
						if (me.variables.exists(k))
						{
							capturedVariables.remove(k);
							continue;
						}
						me.variables.set(k, v);
					}

					for (i in 0...params.length)
					{
						me.locals.set(params[i].name, {
							r: args[i]
						});
					}
					var oldDecl = declared.length;
					var r = null;

					inline function restoreContext()
					{
						// Remove the restored arguments again
						for (k in capturedVariables.keys())
						{
							me.variables.remove(k);
						}

						restore(oldDecl);
						me.locals = old;
						me.depth = depth;
						me._nextCallObject = oldCallObject;
						// me._classDeclOverride = oldClsDeclOverride;
					}

					if (inTry)
					{
						// True if the SCRIPT wraps the function in a try/catch block.
						try
						{
							r = me.exprReturn(fexpr);
						}
						catch (e:Dynamic)
						{
							restoreContext();
							#if neko
							neko.Lib.rethrow(e);
							#else
							throw e;
							#end
						}
					}
					else
					{
						// There is no try/catch block. We can add some custom error handling.
						try
						{
							r = me.exprReturn(fexpr);
						}
						catch (err:Expr.Error)
						{
							// PolymodScriptClass.reportError(err, getClassFullyQualifiedName(), name);
							r = null;
						}
						catch (err:Dynamic)
						{
							restoreContext();
							throw err;
						}
					}

					restoreContext();
					return r;
				};

				newFun = Reflect.makeVarArgs(newFun);
				if (name != null)
				{
					// function-in-function is a local function
					declared.push({
						n: name,
						old: locals.get(name)
					});
					var ref = {
						r: newFun
					};
					locals.set(name, ref);
					capturedLocals.set(name, ref); // allow self-recursion
				}
				return newFun;
			case EArrayDecl(arr):
				// Initialize an array (or map) from a declaration.
				var hasElements = arr.length > 0;
				var hasMapElements = (hasElements && Tools.expr(arr[0]).match(EBinop("=>", _)));

				if (hasMapElements)
				{
					return exprMap(arr);
				}
				else
				{
					return exprArray(arr);
				}
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr)) return getMapValue(arr, index);
				return arr[index];
			case ENew(cl, params):
				var a = new Array();
				for (e in params) a.push(expr(e));
				return cnew(cl, a);
			case EThrow(e):
				// If there is a try/catch block, the error will be caught.
				// If there is no try/catch block, the error will be reported.
				error(EScriptThrow('${expr(e)}'));
			case ETry(e, n, _, ecatch):
				var old = declared.length;
				var oldTry = inTry;
				try
				{
					inTry = true;
					var v:Dynamic = expr(e);
					restore(old);
					inTry = oldTry;
					return v;
				}
				catch (error:Error)
				{
					var err = error.e;
					// restore vars
					restore(old);
					inTry = oldTry;
					// declare 'v'
					declared.push({
						n: n,
						old: locals.get(n)
					});
					locals.set(n, {
						r: switch (err)
						{
							case EScriptThrow(errValue):
								errValue;
							default:
								error;
						}
					});
					var v:Dynamic = expr(ecatch);
					restore(old);
					return v;
				}
				catch (error:Dynamic)
				{
					var en = Type.getEnum(error);
					if (en != null && StringTools.endsWith(en.getName(), "Interp.Stop"))
					{
						inTry = oldTry;
						throw error;
					}
					// restore vars
					restore(old);
					inTry = oldTry;
					// declare 'v'
					declared.push({
						n: n,
						old: locals.get(n)
					});
					locals.set(n, {
						r: error
					});
					var v:Dynamic = expr(ecatch);
					restore(old);
					return v;
				}
			case EObject(fl):
				var o = {};
				for (f in fl) set(o, f.name, expr(f.e));
				return o;
			case ETernary(econd, e1, e2):
				return if (expr(econd) == true) expr(e1) else expr(e2);
			case ESwitch(e, cases, def):
				var val:Dynamic = expr(e);

				/*if (Std.isOfType(val, PolymodEnum))
					{
						var old:Int = declared.length;
						var match = false;
						for (c in cases)
						{
							for (v in c.values)
							{
								switch (Tools.expr(v))
								{
									case ECall(e, params):
										switch (Tools.expr(e))
										{
											case EField(_, f):
												if (val._value == f)
												{
													for (i => p in params)
													{
														switch (Tools.expr(p))
														{
															case EIdent(n):
																declared.push({
																	n: n,
																	old: {
																		r: locals.get(n)
																	}
																});
																locals.set(n, {
																	r: val._args[i]
																});
															default:
														}
													}
													match = true;
													break;
												}
											default:
										}
									case EField(_, f):
										if (val._value == f)
										{
											match = true;
											break;
										}
									default:
								}
							}
							if (match)
							{
								val = expr(c.expr);
								break;
							}
						}
						if (!match)
						{
							val = def == null ? null : expr(def);
						}
						restore(old);
						return val;
					}
					else */
				{
					var old:Int = declared.length;
					var match = false;
					for (c in cases)
					{
						for (v in c.values)
						{
							switch (Tools.expr(v))
							{
								case ECall(e, params):
									switch (Tools.expr(e))
									{
										case EField(_, f):
											var valStr:String = cast val;
											valStr = valStr.substring(0, valStr.indexOf("("));
											if (valStr == f)
											{
												var valParams = Type.enumParameters(val);
												for (i => p in params)
												{
													switch (Tools.expr(p))
													{
														case EIdent(n):
															declared.push({
																n: n,
																old: {
																	r: locals.get(n)
																}
															});
															locals.set(n, {
																r: valParams[i]
															});
														default:
													}
												}
												match = true;
												break;
											}
										default:
									}
								default:
									if (expr(v) == val)
									{
										match = true;
										break;
									}
							}
						}
						if (match)
						{
							val = expr(c.expr);
							break;
						}
					}
					if (!match) val = def == null ? null : expr(def);
					restore(old);
					return val;
				}
			case EMeta(_, _, e):
				return expr(e);
			case ECheckType(e, _):
				return expr(e);
		}
		return null;
	}

	/**
	 * Parse an expression, but optionally utilizing additional provided type information.
	 * @param e The expression to parse.
	 * @param t The explicit type of the expression, if provided.
	 * @return The parsed expression.
	 */
	public function exprWithType(e:Expr, ?t:CType):Dynamic
	{
		if (t == null)
		{
			return this.expr(e);
		}

		curExpr = e;

		switch (Tools.expr(e))
		{
			case EArrayDecl(arr):
				// Initialize an array (or map) from a declaration.
				var hasElements = arr.length > 0;
				var hasMapElements = (hasElements && Tools.expr(arr[0]).match(EBinop("=>", _)));
				var hasArrayElements = (hasElements && !hasMapElements);

				switch (t)
				{
					case CTPath(path, params):
						if (path.length > 0)
						{
							var last = path[path.length - 1];
							if (last == "Map")
							{
								if (!hasElements)
								{
									// Properly handle maps with no keys.
									return this.makeMapEmpty(params[0]);
								}
								else if (hasMapElements)
								{
									// Properly handle maps with no keys.
									return exprMap(arr);
								}
								else
								{
									curExpr = e;
									var err = 'Invalid expression in map initialization (expected key=>value, got ${Printer.toString(e)})';
									error(ECustom(err));
								}
							}
							else if (last == "Array")
							{
								if (!hasElements)
								{
									// Create an empty Array<Dynamic>.
									return exprArray([]);
								}
								if (hasArrayElements)
								{
									// Create an array of elements.
									return exprArray(arr);
								}
								else
								{
									curExpr = e;
									var err = 'Invalid expression in array initialization (expected no key=>value pairs, got ${Printer.toString(e)})';
									error(ECustom(err));
								}
							}
							else
							{
								// Whatever.
							}
						}
					default:
						// Whatever.
				}

			default:
				// Whatever.
		}

		// Fallthrough.
		return this.expr(e);
	}

	function exprMap(entries:Array<Expr>):Dynamic
	{
		if (entries.length == 0) return makeMap([], []);

		var keys = [];
		var values = [];
		for (e in entries)
		{
			switch (Tools.expr(e))
			{
				case EBinop("=>", eKey, eValue):
					// Look for map entries.
					keys.push(expr(eKey));
					values.push(expr(eValue));
				default:
					// Complain about anything else.
					// This error message has been modified to provide more information.
					curExpr = e;
					var err = 'Invalid expression in map initialization (expected key=>value, got ${Printer.toString(e)})';
					error(ECustom(err));
			}
		}

		return makeMap(keys, values);
	}

	function makeMapEmpty(keyType:CType):Dynamic
	{
		switch (keyType)
		{
			case CTPath(path, params):
				if (path.length > 0)
				{
					var last = path[path.length - 1];
					switch (last)
					{
						case "Int":
							return new Map<Int, Dynamic>();
						case "String":
							return new Map<String, Dynamic>();
						default:
							// TODO: Properly handle distinguishing Enum maps from Object maps.
							return new Map<
								{}, Dynamic>();
					}
				}
			default:
				// Whatever.
				error(ECustom('Invalid key type for empty map initialization (${new Printer().typeToString(keyType)}).'));
		}
		return makeMap([], []);
	}

	function exprArray(entries:Array<Expr>):Dynamic
	{
		// Create an Array<Dynamic>
		var a = new Array();
		for (e in entries) a.push(expr(e));
		return a;
	}

	function getIdent(e:Expr):Null<String>
	{
		switch (Tools.expr(e))
		{
			case EIdent(v):
				return v;
			default:
				return null;
		}
	}

	function doWhileLoop(econd, e)
	{
		var old = declared.length;
		do
		{
			if (!loopRun(() -> expr(e))) break;
		} while (expr(econd) == true);
		restore(old);
	}

	function whileLoop(econd, e)
	{
		var old = declared.length;
		while (expr(econd) == true)
		{
			if (!loopRun(() -> expr(e))) break;
		}
		restore(old);
	}

	function makeIterator(v:Dynamic):Iterator<Dynamic>
	{
		var reference:Null<Reference<Dynamic>> = fetchReference(v);

		if (reference?.exists('iterator') ?? false)
		{
			v = reference.get('iterator');
			reference = fetchReference(v);
		}

		if (reference == null || !reference.exists('hasNext') || !reference.exists('next'))
		{
			return error(EInvalidIterator(v));
		}

		return reference.object;
	}

	function makeKeyValueIterator(v:Dynamic):KeyValueIterator<Dynamic, Dynamic>
	{
		#if js
		// don't use try/catch (very slow)
		if (v is Array) return (v : Array<Dynamic>).keyValueIterator();
		if (v.keyValueIterator != null) v = v.keyValueIterator();
		#else
		try
			v = v.keyValueIterator()
		catch (e:Dynamic)
		{
		};
		#end
		if (v.hasNext == null || v.next == null) error(EInvalidIterator(v));
		return v;
	}

	function forLoop(n, it, e)
	{
		var old = declared.length;
		declared.push({
			n: n,
			old: locals.get(n)
		});
		var it = makeIterator(expr(it));
		while (it?.hasNext() ?? false)
		{
			locals.set(n, {
				r: it.next()
			});
			if (!loopRun(() -> expr(e))) break;
		}
		restore(old);
	}

	function forKeyValueLoop(vk, vv, it, e)
	{
		var old = declared.length;
		declared.push({
			n: vk,
			old: locals.get(vk)
		});
		declared.push({
			n: vv,
			old: locals.get(vv)
		});
		var it = makeKeyValueIterator(expr(it));
		while (it.hasNext())
		{
			var v = it.next();
			locals.set(vk, {
				r: v.key
			});
			locals.set(vv, {
				r: v.value
			});
			if (!loopRun(() -> expr(e))) break;
		}
		restore(old);
	}

	inline function loopRun(f:Void->Void)
	{
		var cont = true;
		try
		{
			f();
		}
		catch (err:Stop)
		{
			switch (err)
			{
				case SContinue:
				case SBreak:
					cont = false;
				case SReturn:
					throw err;
			}
		}
		return cont;
	}

	inline function isMap(o:Dynamic):Bool
	{
		return (o is IMap);
	}

	inline function getMapValue(map:Dynamic, key:Dynamic):Dynamic
	{
		return cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).get(key);
	}

	inline function setMapValue(map:Dynamic, key:Dynamic, value:Dynamic):Void
	{
		cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).set(key, value);
	}

	function makeMap(keys:Array<Dynamic>, values:Array<Dynamic>):Null<Dynamic>
	{
		var isAllString:Bool = true;
		var isAllInt:Bool = true;
		var isAllObject:Bool = true;
		var isAllEnum:Bool = true;
		for (key in keys)
		{
			isAllString = isAllString && (key is String);
			isAllInt = isAllInt && (key is Int);
			isAllObject = isAllObject && Reflect.isObject(key);
			isAllEnum = isAllEnum && Reflect.isEnumValue(key);
		}
		if (isAllInt)
		{
			var m = new Map<Int, Dynamic>();
			for (i => key in keys) m.set(key, values[i]);
			return m;
		}
		if (isAllString)
		{
			var m = new Map<String, Dynamic>();
			for (i => key in keys) m.set(key, values[i]);
			return m;
		}
		if (isAllEnum)
		{
			var m = new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
			for (i => key in keys) m.set(key, values[i]);
			return m;
		}
		if (isAllObject)
		{
			var m = new Map<
				{}, Dynamic>();
			for (i => key in keys) m.set(key, values[i]);
			return m;
		}
		error(ECustom("Invalid map keys " + keys));
		return null;
	}

	function get(o:Dynamic, f:String):Null<Dynamic>
	{
		if (o == null) error(ENullObjectReference(f));

		var reference:Null<Reference<Dynamic>> = fetchReference(o);
		if (reference != null)
		{
			if (!reference.exists(f)) return error(EUnknownVariable(f));

			try
			{
				return reference.get(f);
			}
			catch (e:ErrorDef)
			{
				return error(e);
			}
			catch (e:Dynamic)
			{
				throw e;
			}
		}

		return error(EInvalidAccess(f));
	}

	function set(o:Dynamic, f:String, v:Dynamic):Null<Dynamic>
	{
		if (o == null) error(ENullObjectReference(f));

		var reference:Null<Reference<Dynamic>> = fetchReference(o);
		if (reference != null)
		{
			try
			{
				return reference.set(f, v);
			}
			catch (e:ErrorDef)
			{
				return error(e);
			}
			catch (e:Dynamic)
			{
				throw e;
			}
		}

		return error(EInvalidAccess(f));
	}

	public function registerModules(module:Array<ModuleDecl>, ?origin:String = "hscript"):Void
	{
		// var isImportFile:Bool = (new haxe.io.Path(origin).file == "import");

		var pkg:Array<String> = null;

		imports = [];
		usings = [];

		// Don't add the default imports to import.hx since they're added to other script classes anyway.
		/*if (!isImportFile)
			{
				for (importPath in PolymodScriptClass.defaultImports.keys())
				{
					var splitPath = importPath.split(".");
					var clsName = splitPath[splitPath.length - 1];

					imports.set(clsName, {
						name: clsName,
						pkg: splitPath.slice(0, splitPath.length - 1),
						fullPath: importPath,
						cls: PolymodScriptClass.defaultImports.get(importPath),
					});
				}
		}*/

		for (decl in module)
		{
			switch (decl)
			{
				case DPackage(path):
					pkg = path;
				case DImport(path, _, name):
					var clsName:String = name != null ? name : path[path.length - 1];

					if (imports.exists(clsName))
					{
						trace('[SCRIPT-INTERP] Scripted class ${clsName} has already been imported.', 'WARNING');
						continue;
					}

					var importedClass:ClassImport = {
						name: clsName,
						pkg: path.slice(0, path.length - 1),
						fullPath: path.join("."),
						ref: null
					};

					var validImport:Bool = resolveImportedClass(importedClass, true);
					if (validImport && importedClass.ref == null) continue;

					/*if (isImportFile)
						{
							registerImportForPackage(pkg, importedClass);
							continue;
					}*/

					trace('[SCRIPT-INTERP] Imported class ${importedClass.name} from ${importedClass.fullPath}');
					imports.set(importedClass.name, importedClass);
				case DUsing(path):
					var clsName = path[path.length - 1];

					if (usings.exists(clsName))
					{
						trace('[SCRIPT-INTERP] Scripted class ${clsName} has already been used.', 'WARNING');
						continue;
					}

					var importedClass:ClassImport = {
						name: clsName,
						pkg: path.slice(0, path.length - 1),
						fullPath: path.join("."),
						ref: null
					};

					var validImport:Bool = resolveImportedClass(importedClass, true);
					if (validImport && importedClass.ref == null) continue;

					/*if (isImportFile)
						{
							registerImportForPackage(pkg, importedClass, true);
							continue;
					}*/
					usings.set(importedClass.name, importedClass);
				case DClass(c):
					// if (isImportFile) continue;

					var instanceFields = [];
					var staticFields = [];
					for (f in c.fields)
					{
						if (f.access.contains(AStatic))
						{
							staticFields.push(f);
						}
						else
						{
							instanceFields.push(f);
						}
					}

					var classDecl:ClassDecl = {
						pkg: pkg,
						name: c.name,
						params: c.params,
						meta: c.meta,
						isPrivate: c.isPrivate,
						extend: c.extend,
						implement: c.implement,
						fields: instanceFields,
						isExtern: c.isExtern,
						staticFields: staticFields,
					};
				// registerScriptClass(classDecl); // TODO: register script classes
				case DEnum(e):
					// if (isImportFile) continue;

					if (pkg != null)
					{
						imports.set(e.name, {
							name: e.name,
							pkg: pkg,
							fullPath: pkg.join(".") + "." + e.name,
							ref: null
						});
					}

					var enumDecl:EnumDecl = {
						pkg: pkg,
						name: e.name,
						meta: e.meta,
						params: e.params,
						isPrivate: e.isPrivate,
						fields: e.fields,
					};

				// registerScriptEnum(enumDecl); // TODO: register script enums
				case DTypedef(_):
				case DInterface(_):
				case DField(field):
					var value:Dynamic = switch (field.kind)
					{
						case KFunction(func):
							Reflect.makeVarArgs((args:Array<Dynamic>) ->
							{
								var previousValues:Map<String, Dynamic> = setFunctionValues(func, args, field.name);
								var r:Dynamic = null;

								try
								{
									r = func?.expr != null ? exprReturn(func.expr) : null;
								}
								catch (e:Error)
								{
									error(e.e);
								}

								for (a in func.args)
								{
									if (previousValues.exists(a.name))
									{
										variables.set(a.name, previousValues.get(a.name));
									}
									else
									{
										variables.remove(a.name);
									}
								}

								return r;
							});
						case KVar(v):
							v.expr != null ? exprWithType(v.expr, v.type) : null;
					}

					this.variables.set(field.name, value);
			}
		}
	}

	/**
	 * Validates the minimum argument requirement by using the rightmost required argument index
	 * and ensures the param count is matching the actual length of the given arguments.
	 * Throws an error if validation fails.
	 *
	 * @param param The function parameters
	 * @param args The given arguments
	 * @param name The function name
	 */
	public function validateArgumentCount(params:Array<Argument>, args:Array<Dynamic>, name:Null<String>):Void
	{
		// getters/setters have null given arguments it seems, so we return early
		if (args == null) return;

		var minParams = 0;
		//    var maxAllowed = params.length;

		for (i in 0...params.length)
		{
			var p = params[i];
			if (!p.opt && p.value == null) minParams = i + 1;
		}

		final funcName:String = (name != null) ? " for function '" + name + "'" : "";
		if (args.length < minParams)
		{
			error(EInvalidArgCount(funcName, minParams, args.length));
		}
		//    else if (args.length > maxAllowed)
		//    {
		//      // Manual return for `new` as parameter count shouldn't matter here
		//      if (name == "new") return;
		//      error(EExceedArgsCount(funcName, maxAllowed, args.length));
		//    }
	}
}

private enum Stop
{
	SBreak;
	SContinue;
	SReturn;
}
