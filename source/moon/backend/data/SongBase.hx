package moon.backend.data;

/**
 * A typedef that contains basic song data, used in some menus.
 */
typedef SongBase =
{
	/**
	 * The song's name.
	 */
	var song:String;

	/**
	 * The song's difficulty.
	 */
	var difficulty:String;

	/**
	 * The song's mix.
	 */
	var mix:String;

	/**
	 * The song's display name.
	 */
	var ?displayName:String;
};
