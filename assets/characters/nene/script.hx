import moon.dependency.MoonSprite;

var aVisualizer:ABotVisualizer;
var system:MoonSprite;
function onPostStageCreate()
{
	final specs = game.stage.spectators;
	
	var stereobg = new MoonSprite().loadGraphic(Paths.image('abot/stereoBG', 'characters'));
	
	system = new MoonSprite();
	system.frames = Paths.getSparrowAtlas('abot/system', 'characters');
	system.animation.addByPrefix('bop', 'Abot System0', 24, false);
	specs.insert(specs.members.indexOf(char), system);
	specs.insert(specs.members.indexOf(system), stereobg);
	system.x -= 24;
	system.y -= 8;
	
	aVisualizer = new ABotVisualizer();
	specs.insert(specs.members.indexOf(system), aVisualizer);
	aVisualizer.setPosition(char.x + 69, char.y + 388);
	stereobg.setPosition(system.x + 148, system.y + 20);
	
	//system.shader = stereobg.shader = char.shader;
}

//lol+
function onSongStart()
{
	updateVis();
}

function onSongResume()
{
	//it desyncs???
	// btw I'm aware that the visualizer dies when pausing.
	// SELF NOTE:
	// I can just set it to null (the analyzer)
	// and then re-call the create function.
	
	// okayyy acrazytown fixed ittt, awsome
	//trace('Hello! You just killed Nenes Visualizer because I suck');
	updateVis();
}

function onSongRestart()
{
	//updateVis();
	aVisualizer.resetVis();
}

function updateVis()
{
	aVisualizer.analyzer = null;
	aVisualizer.setAudioSource(game.playField.playback.inst[0]);
}

function onBeat(beat)
{
	system.playAnim('bop', true);
}