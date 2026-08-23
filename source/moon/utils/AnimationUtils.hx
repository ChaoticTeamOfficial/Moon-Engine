package moon.utils;

import moon.backend.Paths.TextureAtlasAnimType;
import flixel.graphics.frames.FlxFramesCollection;
import animate.FlxAnimate;
import animate.*;

using StringTools;

/**
 * Centralized helpers for registering animations on sprites.
 */
class AnimationUtils
{
	/**
	 * Adds a single animation to any `FlxSprite` using frame-name lookups.
	 * Covers Sparrow (XML) and Sprite Packer (TXT) atlases, both produce
	 * named frames under the hood, as well as plain grid spritesheets
	 * (`NONE`), which use raw frame indices instead of names.
	 *
	 * `ATLAS` (FlxAnimate texture atlas) animations are NOT handled here, as
	 * those use a different controller and target type, see
	 * `addTextureAtlasAnimation`.
	 *
	 * @param target The sprite to add the animation to. Must already have its
	 *               atlas/spritesheet graphic loaded.
	 * @param anim   The animation data to register.
	 * @param type   `SPARROW` (default) or `PACKED` for name-prefixed atlas
	 *               frames, or `NONE` for a uniform grid spritesheet with no atlas.
	 */
	public static function addAtlasAnimation(target:FlxSprite, anim:AnimationData, type:AtlasType = SPARROW):Void
	{
		if (target == null || anim == null) return;

		final frameRate:Int = anim.fps ?? 24;
		final looped:Bool = anim.looped ?? false;
		final flipX:Bool = anim.flipX ?? false;
		final flipY:Bool = anim.flipY ?? false;

		switch (type)
		{
			case NONE:
				// No atlas! frames are referenced by raw index into a uniform grid.
				if (anim.indices == null || anim.indices.length == 0)
				{
					trace('[AnimationUtils] "${anim.name}" needs `indices` to be added as a spritesheet animation!', "WARNING");
					return;
				}
				target.animation.add(anim.name, anim.indices, frameRate, looped, flipX, flipY);

			case ATLAS:
				trace('[AnimationUtils] "${anim.name}" is an ATLAS (texture atlas) animation, so use addTextureAtlasAnimation instead.', "WARNING");
				return;

			default:
				if (anim.prefix == null)
				{
					trace('[AnimationUtils] "${anim.name}" needs a `prefix` to be added as an atlas animation!', "WARNING");
					return;
				}

				if (
					anim.indices != null
					&& anim.indices.length > 0
				) target.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', frameRate, looped, flipX, flipY);
				else
					target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
		}

		rememberAnimData(target, anim);
	}

	/**
	 * Merges any extra spritesheets referenced by individual animations
	 * into a sprite's existing frame collection.
	 * Extra sheets are expected to live in the same folder as `basePath`,
	 * just under a different filename.
	 *
	 * @param target      The sprite whose `.frames` will receive the merged frames.
	 * @param animations  The animation list to scan for `sheet` references.
	 * @param basePath    Folder path each bare sheet name is appended to.
	 * @param from        Sub-folder inside `assets/` (`'characters'`, `'stages'`, etc).
	 * @param defaultType Fallback atlas format when an animation omits `type`.
	 */
	public static function mergeExtraSheets(target:FlxSprite, animations:Array<Paths.AnimationData>, basePath:String, from:String, defaultType:AtlasType):Void
	{
		if (target == null || target.frames == null || animations == null) return;

		var seen:Map<String, Bool> = [];
		for (anim in animations)
		{
			if (anim.sheet == null || seen.exists(anim.sheet)) continue;
			seen.set(anim.sheet, true);

			final animType = anim.type ?? defaultType;
			final sheetKey = (anim.sheet.indexOf('/') != -1) ? anim.sheet : '$basePath/${anim.sheet}';

			switch (animType)
			{
				case SPARROW:
					final extraFrames = Paths.getSparrowAtlas(sheetKey, from);
					if (extraFrames == null)
					{
						trace('[AnimationUtils] Extra sheet "$sheetKey" for anim "${anim.name}" could not be loaded!', "WARNING");
						continue;
					}
					for (frame in extraFrames.frames) target.frames.pushFrame(frame);

				case PACKED:
					final extraFrames = Paths.getPackerAtlas(sheetKey, from);
					if (extraFrames == null)
					{
						trace('[AnimationUtils] Extra sheet "$sheetKey" for anim "${anim.name}" could not be loaded!', "WARNING");
						continue;
					}

					for (frame in extraFrames.frames) target.frames.pushFrame(frame);

				case ATLAS:
					mergeExtraAtlas(target, sheetKey, from, anim.name);

				default:
					trace('[AnimationUtils] Extra sheet "$sheetKey" for anim "${anim.name}" uses unsupported type "$animType".', "WARNING");
			}
		}
	}

	private static function mergeExtraAtlas(target:FlxSprite, sheetKey:String, from:String, animName:String):Void
	{
		if (!Std.isOfType(target.frames, FlxAnimateFrames))
		{
			trace('[AnimationUtils] Cannot merge ATLAS sheet "$sheetKey"! target\'s frames aren\'t a FlxAnimateFrames collection!', "WARNING");
			return;
		}

		final baseAtlas:FlxAnimateFrames = cast target.frames;
		final extraAtlas:FlxAnimateFrames = FlxAnimateFrames.fromAnimate(Paths.getPath('$from/$sheetKey'));
		if (extraAtlas == null)
		{
			trace('[AnimationUtils] Extra atlas "$sheetKey" for anim "$animName" could not be loaded!', "WARNING");
			return;
		}

		baseAtlas.addAtlas(extraAtlas);
	}

	/** Adds a batch of atlas/spritesheet animations via `addAtlasAnimation`. */
	public static function addAtlasAnimations(target:FlxSprite, animations:Array<AnimationData>, type:AtlasType = SPARROW):Void
	{
		for (anim in animations) addAtlasAnimation(target, anim, type);
	}

	/**
	 * Adds a single animation to a `FlxAnimate` sprite.
	 */
	public static function addTextureAtlasAnimation(target:FlxAnimate, anim:AnimationData):Void
	{
		if (target == null || anim == null || anim.prefix == null) return;

		final frameRate:Int = anim?.fps ?? 24;
		final looped:Bool = anim?.looped ?? false;
		final animType:TextureAtlasAnimType = anim?.animType ?? FRAMELABEL;
		final controller:FlxAnimateController = cast target.animation;

		if (anim.indices != null && anim.indices.length > 0)
		{
			switch (animType)
			{
				case FRAMELABEL:
					controller.addByFrameLabelIndices(anim.name, anim.prefix, anim.indices, frameRate, looped);
				case SYMBOL:
					controller.addBySymbolIndices(anim.name, anim.prefix, anim.indices, frameRate, looped);
			}
		}
		else
		{
			switch (animType)
			{
				case FRAMELABEL:
					controller.addByFrameLabel(anim.name, anim.prefix, frameRate, looped);
				case SYMBOL:
					controller.addBySymbol(anim.name, anim.prefix, frameRate, looped);
			}
		}

		rememberAnimData(target, anim);
	}

	/** Adds a batch of texture-atlas animations via `addTextureAtlasAnimation`. */
	public static function addTextureAtlasAnimations(target:FlxAnimate, animations:Array<AnimationData>):Void
	{
		for (anim in animations) addTextureAtlasAnimation(target, anim);
	}

	/**
	 * If `target` is a `MoonSprite`, records the raw `AnimationData` used to
	 * register this animation so it can be looked up later via
	 * `MoonSprite.animDataMap` / `getAnimData`.
	 */
	private static function rememberAnimData(target:FlxSprite, anim:AnimationData):Void
	{
		if (Std.isOfType(target, MoonSprite)) cast(target, MoonSprite).animDataMap.set(anim.name, anim);
	}

	/**
	 * Combines two `FlxFramesCollection`s into one.
	 */
	public static function combineFramesCollections(a:FlxFramesCollection, b:FlxFramesCollection):FlxFramesCollection
	{
		var result:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);

		for (frame in a.frames) result.pushFrame(frame);
		for (frame in b.frames) result.pushFrame(frame);

		return result;
	}

	/**
	 * Loads a graphic onto a sprite as a uniform grid spritesheet.
	 */
	public static function loadSpritesheetGraphic(target:FlxSprite, key:String, frameWidth:Int, frameHeight:Int, from:String = 'images', ?library:String):FlxSprite
		return target.loadGraphic(
		Paths.image(key, from, library),
		true,
		frameWidth,
		frameHeight
	);

	/**
	 * Registers idle/dance grouping and "on finish" chaining for one animation on a `MoonSprite`.
	 */
	public static function registerDances(target:MoonSprite, anim:AnimationData):Void
	{
		if (anim.name.startsWith("idle-"))
		{
			final parts = anim.name.split('-');
			final suffix = (parts.length > 2) ? parts[parts.length - 1] : "";

			if (!target.idleAnimsMap.exists(suffix)) target.idleAnimsMap.set(suffix, []);

			target.idleAnimsMap.get(suffix).push(anim.name);
		}

		if (anim.finishAnim != null)
		{
			target.animation.onFinish.add(finishedName ->
			{
				final cur = target.animation.curAnim != null ? target.animation.curAnim.name : "";
				final playedName = (target.animationSuffix != "" && cur.endsWith('-${target.animationSuffix}')) ? cur.substring(0, cur.lastIndexOf('-')) : cur;

				if (playedName == anim.name)
				{
					if (anim.finishAnim == "idle" || anim.finishAnim.startsWith("idle-"))
					{
						target.dance(true);
						target.animation.curAnim.curFrame = target.animation.curAnim.frames[target.animation.curAnim.frames.length - 1];
					}
					else
					{
						// Idle/dance finished into a non-idle anim whichhh usually is a looped hold.
						if (anim.name.startsWith("idle") || anim.name.startsWith("dance")) target.idleHold = true;

						target.playAnim(anim.finishAnim, true);
					}
				}
			});
		}
	}

	/**
	 * Registers every animation, plus offsets, idle grouping, and finish-animation chaining.
	 * Each animation may override the atlas format via its own `type` field.
	 * @return The base (no-suffix) idle animation names, for chaining convenience.
	 */
	public static function loadAnimations(target:MoonSprite, animations:Array<AnimationData>, type:AtlasType = SPARROW):Array<String>
	{
		target.idleAnimsMap.clear();

		for (anim in animations)
		{
			final animType = anim.type ?? type;
			if (animType == ATLAS) addTextureAtlasAnimation(target, anim);
			else
				addAtlasAnimation(target, anim, animType);

			target.addOffset(anim.name, anim?.x ?? 0, anim?.y ?? 0);
			registerDances(target, anim);
		}

		if (!target.idleAnimsMap.exists("")) target.idleAnimsMap.set("", []);

		return target.idleAnims;
	}
}
