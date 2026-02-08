import moon.dependency.MoonSprite;

var aVisualizer:ABotVisualizer;
var system:MoonSprite;
function onPostCreate()
{
	final specs = game.stage.spectators;
	
	var stereobg = new MoonSprite(char.x - 348, char.y - 32).loadGraphic(Paths.image('abot/stereoBG', 'characters'));
	
	system = new MoonSprite(char.x - 520, char.y - 66);
	system.frames = Paths.getSparrowAtlas('abot/system', 'characters');
	system.animation.addByPrefix('bop', 'Abot System0', 24, false);
	specs.insert(specs.members.indexOf(char), system);
	specs.insert(specs.members.indexOf(system), stereobg);
	
	aVisualizer = new ABotVisualizer();
	specs.insert(specs.members.indexOf(system), aVisualizer);
	aVisualizer.setPosition(char.x + 58, char.y + 396);
	
	//system.shader = stereobg.shader = char.shader;
}

//lol
function onSongStart()
{
	updateVis();
}

function onSongResume()
{
	//it desyncs???
	// btw I'm aware that the visualizer dies when pausing.
	trace('Hello! You just killed Nenes Visualizer because I suck');
	//updateVis();
}

function onSongRestart()
{
	//updateVis();
}

function updateVis()
{
	aVisualizer.setAudioSource(game.playField.playback.inst[0]);
}

function onBeat(beat)
{
	system.playAnim('bop', true);
}