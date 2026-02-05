package moon.toolkit.level_editor;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.game.PlayState;

/**
 * Handles the smooth transition from gameplay to the level editor
 */
class EditorTransition
{
    public static var isTransitioning:Bool = false;
    
    public static function transitionToEditor(playState:PlayState):Void
    {
        if (isTransitioning) return;
        isTransitioning = true;
        
        playState.activeTweens(false);
        playState.playField.playback.state = PAUSE;
        playState.playField.inCutscene = true;
        Global.allowInputs = false;
        
        // Calculate target position and scale for miniplayer
        final targetX:Float = 108 + (MiniPlayer.MINI_WIDTH / 2);
        final targetY:Float = 48 + (MiniPlayer.MINI_HEIGHT / 2);
        final targetZoom:Float = MiniPlayer.SCALE;
        
        // Store original camera values
        final originalZoom = playState.camGAME.zoom;
        final originalX = playState.camGAME.scroll.x;
        final originalY = playState.camGAME.scroll.y;
        
        final centerX = FlxG.width / 2;
        final centerY = FlxG.height / 2;
        final offsetX = targetX - centerX;
        final offsetY = targetY - centerY;
        
        // Fade out HUD first
        FlxTween.tween(playState.camHUD, {alpha: 0}, 0.3, {
            ease: FlxEase.quadOut
        });
        
        // Zoom and move camera simultaneously
        FlxTween.tween(playState.camGAME, {zoom: targetZoom}, 1, {
            ease: FlxEase.expoInOut,
            onUpdate: (twn) -> {
                final progress = twn.percent;
                playState.camGAME.scroll.x = originalX + (offsetX * progress);
                playState.camGAME.scroll.y = originalY + (offsetY * progress);
            },
            onComplete: (_) -> {
                FlxG.switchState(() -> new LevelEditor(
                    PlayState.songData.song,
                    PlayState.songData.difficulty,
                    PlayState.songData.mix
                ));
                isTransitioning = false;
            }
        });
        
        var overlay = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        overlay.alpha = 0;
        overlay.camera = playState.camALT;
        playState.add(overlay);
        
        FlxTween.tween(overlay, {alpha: 1}, 1, {ease: FlxEase.quadOut});
    }

    public static function transitionToGameplay(editor:LevelEditor):Void
    {
        if (isTransitioning) return;
        isTransitioning = true;
        
        //TODO
        FlxG.switchState(() -> new moon.game.PlayState());
        isTransitioning = false;
    }
}
