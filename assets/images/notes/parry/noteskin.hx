import flixel.FlxG;

final scale = 0.6;

function createStaticNote(skin, direction)
{
    staticNote.frames = Paths.getSparrowAtlas('notes/' + skin + '/NOTE_parry');

    staticNote.animation.addByPrefix(direction, direction + ' note alone0', 24, true);
    staticNote.scale.set(scale, scale);
    staticNote.antialiasing = true;
}