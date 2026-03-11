package moon.toolkit.level_editor;

import moon.backend.data.Chart.NoteStruct;
import moon.backend.data.Chart.EventStruct;

/**
 * Handles synchronization between the level editor and miniplayer
 * Ensures changes made in the editor are reflected in real-time in the miniplayer
 */
class EditorSync
{
    public static var miniPlayer:MiniPlayer;
    
    /**
     * Call this when a note is added in the editor
     */
    public static function onNoteAdded(note:NoteStruct):Void
    {
        if (miniPlayer == null) return;
    }
    
    /**
     * Call this when a note is deleted in the editor
     */
    public static function onNoteDeleted(note:NoteStruct):Void
    {
        if (miniPlayer == null) return;
    }
    
    public static function onEventAdded(event:EventStruct):Void
    {
        if (miniPlayer == null) return;
    }
    
    public static function onEventDeleted(event:EventStruct):Void
    {
        if (miniPlayer == null) return;
    }
    
    /**
     * Call this when the BPM changes
     */
    public static function onBPMChange(time:Float, newBPM:Float, numerator:Float, denominator:Float):Void
    {
        if (miniPlayer == null) return;
    }
    
    /**
     * Force complete resync (useful after major changes)
     */
    public static function forceResync():Void
    {
        if (miniPlayer == null) return;
        miniPlayer.refreshChart();
    }
}
