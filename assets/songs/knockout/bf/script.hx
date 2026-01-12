import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;

import moon.dependency.MoonSprite;
import moon.dependency.user.MoonSettings;
import moon.dependency.MoonUtils;
import moon.game.obj.Character;

//////////////////////////////////////////////

final p = 'ingame/stages/rain/';
var opp:Character;
var plyr:Character;

var bullets:Array<MoonSprite> = [];
var hasParry:Bool = false;
var shootTrack:Int = 0;
var cupStatus:String;
var inDodgeSection:Bool = false;
var pressedDodge:Bool = false;
var isCupGreen:Bool = false;
var luisIsHere:Bool = true;

var cupAttack:MoonSprite;

var readyWallop:MoonSprite;
var knockout:MoonSprite;
var parryOverlay:MoonSprite;
var dodgeOverlay:MoonSprite;
var luis:MoonSprite;
var coolCard:MoonSprite;
var dodgeSign:MoonSprite;
//var debugTxt:FlxText;
function onPostCreate()
{
	//game.add(bullets);
	
	opp = game.stage.opponents.members[0];
	plyr = game.stage.players.members[0];
	
	coolCard = new MoonSprite();
	coolCard.frames = Paths.getSparrowAtlas(p + 'Cardcrap');
	coolCard.animation.addByPrefix('pop', 'PARRY Card Pop out  instance 1', 28, false);
	coolCard.animation.addByPrefix('spin', 'Card Filled instance 1', 28, true);
	coolCard.animation.onFinish.add((anim) -> {
		if(anim == 'pop') coolCard.playAnim('spin', true);
	});
	coolCard.addOffset('spin', 12, 51);
	coolCard.addOffset('pop', 16, 63);
	
	//coolCard.centerAnimations = true;
	coolCard.antialiasing = true;
	coolCard.camera = game.camHUD;
	coolCard.playAnim('pop', true);
	coolCard.alpha = 0.0001;
	game.add(coolCard);
	
	coolCard.scale.set(0.7, 0.7);
	coolCard.updateHitbox();
	
	//bullets.setPosition(opp.x, opp.y);
	//trace("Hellooo!");
	readyWallop = new MoonSprite();
	readyWallop.frames = Paths.getSparrowAtlas(p + 'ready_wallop');
	readyWallop.animation.addByPrefix('go!', 'Ready? WALLOP!', 32, false);
	readyWallop.animation.onFinish.add(_ -> readyWallop.alpha = 0.0001);
	readyWallop.antialiasing = true;
	readyWallop.camera = game.camHUD;
	readyWallop.screenCenter();
	readyWallop.scale.set(0.8, 0.8);
	game.add(readyWallop);
	
	knockout = new MoonSprite();
	knockout.frames = Paths.getSparrowAtlas(p + 'knock');
	knockout.animation.addByPrefix('spawn', 'A KNOCKOUT!', 24, false);
	knockout.animation.onFinish.add(_ -> FlxTween.tween(knockout, {alpha: 0.0001}, 1));
	knockout.antialiasing = true;
	knockout.camera = game.camHUD;
	knockout.screenCenter();
	knockout.scale.set(0.8, 0.8);
	knockout.alpha = 0.0001;
	game.add(knockout);
	
	parryOverlay = new MoonSprite().loadGraphic(Paths.image(p + 'lightOverlay'));
	parryOverlay.blend = 0;
	parryOverlay.alpha = 0.0001;
	parryOverlay.camera = game.camALT;
	parryOverlay.setGraphicSize(FlxG.width, FlxG.height);
	parryOverlay.screenCenter();
	game.add(parryOverlay);
	
	dodgeOverlay = new MoonSprite().loadGraphic(Paths.image(p + 'dodgeOverlay'));
	dodgeOverlay.blend = 0;
	dodgeOverlay.alpha = 0.0001;
	dodgeOverlay.camera = game.camALT;
	dodgeOverlay.setGraphicSize(FlxG.width, FlxG.height);
	dodgeOverlay.screenCenter();
	game.add(dodgeOverlay);
	
	dodgeSign = new MoonSprite().loadGraphic(Paths.image(p + 'dodge'));
	dodgeSign.alpha = 0.0001;
	dodgeSign.camera = game.camALT;
	dodgeSign.screenCenter();
	game.add(dodgeSign);
	dodgeSign.angle = -15;
	FlxTween.tween(dodgeSign, {angle: 15}, 0.5, {ease:FlxEase.quadInOut, type: 4});
	
	luis = new MoonSprite().loadGraphic(Paths.image(p + 'luisPhew'));
	luis.alpha = 0.0001;
	game.add(luis);
	
	/*debugTxt = new FlxText();
	debugTxt.fieldWidth = FlxG.width;
	debugTxt.camera = game.camALT;
	game.add(debugTxt);
	debugTxt.size = 28;
	debugTxt.antialiasing = false;*/
	
	// this is for preloading!! I still have to add a way to add custom preloads to the loading screen, soo..
	var bul = generateBullet();
	game.add(bul);
	bul.destroy();
	
	var	gs = new MoonSprite();
	gs.frames = Paths.getSparrowAtlas(p + 'cupBullets/GreenShit');
	gs.animation.addByPrefix('g1', 'GreenShit01 instance 1', 24, false);
	gs.playAnim('g1', true);
	game.add(gs);
	gs.destroy();
	
	cupAttack = new MoonSprite();
	cupAttack.frames = Paths.getSparrowAtlas(p + 'cupBullets/Cuphead Hadoken');
	cupAttack.animation.addByPrefix('go!', 'Hadolen instance 1', 24, true);
	cupAttack.animation.addByPrefix('boom', 'BurstFX instance 1', 24, false);
	cupAttack.animation.onFinish.add((anim) -> if(anim == 'boom') cupAttack.alpha = 0.0001);
	
	cupAttack.antialiasing = true;
	cupAttack.centerAnimations = true;
	cupAttack.playAnim('go!', true);
	game.add(cupAttack);
	cupAttack.alpha = 0.0001;
	cupAttack.blend = 0;
	
	resetLuis();
	doThingy();
}

function onSongRestart()
{
	setParry(false);
	setCupheadStatus('none');
	clearBullets();
	inDodgeSection = pressedDodge = false;
	resetLuis();
	doThingy();
}

function resetLuis()
{
	luisIsHere = true;
	luis.loadGraphic(Paths.image(p + 'luisOHNO'));
	luis.alpha = 0.0001;
	luis.angle = 0;
	luis.setPosition(plyr.x + 664, plyr.y + 164);
}

function doThingy()
{
	game.playField.conductor.time = -(game.playField.conductor.crochet * 2);
	readyWallop.playAnim('go!', true);
	readyWallop.alpha = 1;
	FlxG.sound.play(Paths.sound(p + 'sfx/intros/angry/' + FlxG.random.int(0, 1) + '.ogg', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
}

function onUpdate(elapsed)
{
	parryOverlay.alpha = FlxMath.lerp(parryOverlay.alpha, 0.0001, elapsed * 3);
	dodgeOverlay.alpha = FlxMath.lerp(dodgeOverlay.alpha, 0.0001, elapsed * 6);
	
	final plyrStrum = game.playField.playerStrum;
	coolCard.setPosition(plyrStrum.x - 278, plyrStrum.y - 16);
	
	// -- DEBUGS!! (well kinda, some will be adapted to the 
	// huh
	if(FlxG.keys.justPressed.SHIFT && hasParry)
	{
		setParry(false);
		setCupheadStatus('none');
		plyr.playAnim('attack', true);
		
		FlxG.sound.play(Paths.sound(p + 'sfx/bfAttack.wav', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
		new FlxTimer().start(0.35, _ -> {
			game.playField.inputHandlers.get('p1').stats.health += 30;
			opp.forcePlayAnim('hit', true);
			FlxG.sound.play(Paths.sound(p + 'sfx/hurtCup.wav', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
		});
	}
		
	if(FlxG.keys.justPressed.SPACE && inDodgeSection && !pressedDodge)
	{
		pressedDodge = true;
		//new FlxTimer().start(0.4, _-> plyr.playAnim('dodge', true));
		//opp.playAnim('attack2', true);
	}
		
	// dont forget to remove this l8r u silly
	//if(FlxG.keys.justPressed.P) setCupheadStatus('none');
	
	//debugTxt.text = 'Beat: ' + game.conductor.curBeat + '\nStep: ' + game.conductor.curStep + '\nTime: ' + game.conductor.time;
}

function onNoteHit(playerID, note, timing, isSustain)
{
	if(note.type == 'parry')
		setParry(true);
		
	if(isCupGreen && playerID == 'opponent' && !isSustain)
	{
		generateGreenBullet();
		
		if(game.playField.inputHandlers.get('p1').stats.health > 20) game.playField.inputHandlers.get('p1').stats.health -= 1;
		FlxG.sound.play(Paths.sound(p + 'sfx/attacks/chaser' + FlxG.random.int(0, 4) + '.ogg', 'images'), MoonSettings.callSetting('SFX Volume') / 100 - 0.25);
	}
}

var yeah:Int = 0;
var events:Int = 0;
function onBeat(beat)
{
	/**
	* DODGE BEATS:
	* 36, 100, 150, 162, 194, 228, 292 (cuphead plays anim 'regret'), 400
	*
	* CUPHEAD SHOOTS BEATS:
	* 77, 181, 205, 321, 354
	*
	* CUPHEAD SHOOTING GREEN BULLET BEATS: (stops inside parenthesis)
	* 68 (78), 163 (181), 195 (205), 219 (225), 259 (323), 360
	*/
	switch(beat)
	{
		case 77, 181, 205, 321, 354: setCupheadStatus('normal-bullets');
		case 34, 98, 148, 160, 192, 226, 290, 398: setCupheadStatus('hadoken');
		case 293: opp.forcePlayAnim('regret', true);
	}
	
	yeah = beat;
	events = beat;
	
	switch(yeah)
	{
		case 68, 163, 195, 205, 219, 259, 360: cupheadGreen(true);
		case 78, 181, 205, 225, 323: cupheadGreen(false);
	}
	
	final sz = game.stage.cameraSettings.zoom;
	switch(events)
	{
		case 20: game.setCameraZoom(sz + 0.3, 0.8, {ease: FlxEase.expoOut});
		case 28: game.setCameraZoom(sz + 0.45, 0.8, {ease: FlxEase.expoOut});
		case 32:
			game.setCameraZoom(sz - 0.03, 0.5, {ease: FlxEase.expoOut});
			game.setCameraFocus("player", [0, 0], 0.5, {ease: FlxEase.expoOut});
		case 36: game.setCameraZoom(sz, 1.5, {ease: FlxEase.expoOut});
	
		case 92: game.setCameraZoom(sz + 0.2, 1.5, {ease: FlxEase.expoOut});
		case 98: 
			game.setCameraZoom(sz, 1.5, {ease: FlxEase.expoOut});
		case 220: 
			game.setCameraZoom(sz + 0.1, 0.2, {ease: FlxEase.expoOut});
			game.setCameraFocus("opponent", [0, 0], 0.5, null, true);
		case 222: 
			game.setCameraZoom(sz + 0.2, 0.2, {ease: FlxEase.expoOut});
			game.setCameraFocus("player", [0, 0], 0.5, null, true);
		case 224:
			game.setCameraZoom(sz + 0.3, 0.2, {ease: FlxEase.expoOut});
			game.setCameraFocus("opponent", [0, 0], 0.5, null, true);
		case 226: 
			game.setCameraZoom(sz, 0.2, {ease: FlxEase.expoOut});
			game.setCameraFocus("player", [0, 0], 0.5, null, true);
			
		/////
		case 276: game.setCameraFocus("opponent", [0, 0], 0.5, null, true);
		game.setCameraZoom(sz + 0.1, 1.5, {ease: FlxEase.expoOut});
		case 280: game.setCameraFocus("player", [0, 0], 0.5, null, true);
		game.setCameraZoom(sz + 0.2, 1.5, {ease: FlxEase.expoOut});
		case 284: game.setCameraFocus("opponent", [0, 0], 0.5, null, true);
		game.setCameraZoom(sz + 0.3, 1.5, {ease: FlxEase.expoOut});
		case 291: luis.alpha = 1;
		game.setCameraFocus("player", [300, 0], 1, {ease: FlxEase.expoInOut});
		game.setCameraZoom(sz, 1.5, {ease: FlxEase.expoOut, startDelay: 0.5});
		case 302: game.setCameraZoom(sz + 0.2, 0.1, {ease: FlxEase.expoOut});
		case 303: game.setCameraZoom(sz + 0.4, 0.1, {ease: FlxEase.expoOut});
		luis.alpha = 0.0001;
		case 304: game.setCameraZoom(sz, 0.1, {ease: FlxEase.expoOut});
		
	}
}

var aa:Int = 0;
function onStep(step)
{
	if(cupStatus == 'normal-bullets'){
		FlxG.sound.play(Paths.sound(p + 'sfx/attacks/pea' + FlxG.random.int(0, 5) + '.ogg', 'images'), MoonSettings.callSetting('SFX Volume') / 100 - 0.2);
		
		game.playField.inputHandlers.get('p1').stats.health -= 4;
		var particle = generateBullet();
		particle.animation.play('bullet' + FlxG.random.int(1, 3), true);
		game.add(particle);
		particle.setPosition(opp.x - 80, opp.y - 432);
		particle.animation.onFinish.add(_->{
			bullets.remove(particle);
			particle.destroy();
		});
	}
}

function setCupheadStatus(status:String)
{
	cupStatus = status;
	switch(status)
	{
		case 'normal-bullets':
			var particle = generateBullet();
			game.add(particle);
			particle.setPosition(opp.x - 70, opp.y - 216);
			opp.playAnim('attack1', true);
		
		case 'hadoken': 
		inDodgeSection = true;
		cupAttack.playAnim('go!', true);
		dodgeOverlay.alpha = 1;
		dodgeSign.alpha = 1;
		dodgeSign.y = (MoonSettings.callSetting('Downscroll')) ? FlxG.height - dodgeSign.height - 78 : 78;
		FlxFlicker.flicker(dodgeSign, game.conductor.crochet / 2000, 0.05, true, true);
		
		dodgeSign.scale.set(0.8, 0.8);
		dodgeSign.y += 10;
		FlxTween.tween(dodgeSign, {y: dodgeSign.alpha - 10}, 0.2);
		
		FlxG.sound.play(Paths.sound(p + 'sfx/warn1.wav', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
		new FlxTimer().start(game.conductor.crochet / 1000, _ -> {
			opp.forcePlayAnim('attack2', true);
			dodgeOverlay.alpha = 0.6;
			FlxFlicker.flicker(dodgeSign, game.conductor.crochet / 2000, 0.05, true, true);
			dodgeSign.scale.set(1, 1);
			
			FlxG.sound.play(Paths.sound(p + 'sfx/warn2.wav', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
			new FlxTimer().start(game.conductor.crochet / 1000, _->{
				FlxG.sound.play(Paths.sound(p + 'sfx/shoot.ogg', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
				cupAttack.setPosition(opp.x - 390, opp.y - 478);
				cupAttack.alpha = 0.8;
				cupAttack.velocity.x = 1600;
				FlxTween.tween(dodgeSign, {"scale.x": 0, "scale.y": 0}, 0.45, {ease: FlxEase.backIn, onComplete: _-> dodgeSign.alpha = 0.0001});
				
				new FlxTimer().start(0.45, _->
				{
					inDodgeSection = false;
					if(pressedDodge)
					{
						plyr.playAnim('dodge', true);
						FlxG.sound.play(Paths.sound(p + 'sfx/dodge.ogg', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
						pressedDodge = false;
						
						if(game.conductor.curBeat > 284 && luisIsHere)
						{
							new FlxTimer().start(0.2, _-> {
								knockout.playAnim('spawn', true);
								knockout.alpha = 1;
								FlxG.sound.play(Paths.sound(p + 'sfx/knockout.ogg', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
								luisIsHere = false;
								
								FlxTween.tween(luis, {x: luis.x + 1200, y: luis.y - 600, angle: 1000}, 1);
								FlxG.sound.play(Paths.sound(p + 'sfx/luisSeFudeu.wav', 'images'), MoonSettings.callSetting('SFX Volume') / 100);
								cupAttack.velocity.x = 0;
								cupAttack.playAnim('boom', true);
								cupAttack.x += 340;
							});
						}
					}
					else
					{
						if(game.conductor.curBeat > 284 && luisIsHere)
						{
							luisIsHere = false;
							luis.loadGraphic(Paths.image(p + 'luisPhew'));
							FlxTween.tween(luis, {"scale.x": 1.2, "scale.y": 0.8}, 1, {ease: FlxEase.expoOut});
						}
						
						FlxFlicker.flicker(plyr, 1.3, 0.05, true, true);
						game.playField.inputHandlers.get('p1').stats.health -= 90;
						cupAttack.velocity.x = 0;
						cupAttack.playAnim('boom', true);
						cupAttack.x += 200;
					}
				});
			});
		});

		case 'none': opp.forcePlayAnim('idle-0', true);
		clearBullets();
	}
}

function cupheadGreen(cupGreen:Bool)
{
	isCupGreen = cupGreen;
	opp.animationSuffix = cupGreen ? 'pew' : '';
}

var cardTwn:FlxTween;
function setParry(has:Bool)
{
	if(!hasParry && has) coolCard.playAnim('pop', true);
	
	hasParry = has;
	MoonUtils.cancelActiveTwn(cardTwn);
	coolCard.alpha = 1;
	
	if(hasParry)
	{
		FlxG.sound.play(Paths.sound(p + 'sfx/parry.wav', 'images'));
		parryOverlay.alpha = 0.85;
	}
	else
	{
		cardTwn = FlxTween.tween(coolCard, {alpha: 0.00001}, 0.8, {ease: FlxEase.expoOut});
	}
}

function clearBullets()
{
	for(bullet in bullets)
		FlxTween.tween(bullet, {alpha: 0}, 0.9, {startDelay: 0.1, onComplete: _->bullet.destroy()});
		
	bullets = [];
}

function generateBullet():MoonSprite
{
	var bullet = new MoonSprite();
	bullet.frames = Paths.getSparrowAtlas(p + 'cupBullets/Cupheadshoot');
	bullet.animation.addByPrefix('bullet1', 'BulletFX_H-Tween_02 instance 1', 24, false);
	bullet.animation.addByPrefix('bullet2', 'BulletFX_H-Tween_02 instance 2', 24, false);
	bullet.animation.addByPrefix('bullet3', 'BulletFX_H-Tween_03 instance 1', 24, false);
	bullet.animation.addByPrefix('bulletFlash', 'BulletFlashFX instance 1', 24, true);
	bullet.centerAnimations = true;
	bullet.playAnim('bulletFlash');
	bullet.antialiasing = true;
	bullets.push(bullet);
	bullet.blend = 0;
	return bullet;
}

function generateGreenBullet()
{
	var	gs = new MoonSprite();
	gs.frames = Paths.getSparrowAtlas(p + 'cupBullets/GreenShit');
	gs.animation.addByPrefix('g1', 'GreenShit01 instance 1', 24, false);
	gs.animation.addByPrefix('g2', 'GreenShit02 instance 1', 24, false);
	gs.animation.addByPrefix('g3', 'Greenshit03 instance 1', 24, false);
	gs.antialiasing = true;
	gs.centerAnimations = true;
	gs.playAnim('g' + FlxG.random.int(1, 3), true);
	game.add(gs);
	gs.blend = 0;
	gs.setPosition(opp.x + 384, opp.y);
	gs.animation.onFinish.add(_ -> gs.destroy());
}