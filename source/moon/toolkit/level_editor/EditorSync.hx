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
        miniPlayer.chart.content.notes.push(note);
        miniPlayer.chart.content.notes.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
        miniPlayer.refreshChart();
    }
    
    /**
     * Call this when a note is deleted in the editor
     */
    public static function onNoteDeleted(note:NoteStruct):Void
    {
        if (miniPlayer == null) return;
        
        miniPlayer.chart.content.notes.remove(note);
        miniPlayer.refreshChart();
    }
    
    public static function onEventAdded(event:EventStruct):Void
    {
        if (miniPlayer == null) return;
        
        miniPlayer.chart.events.push(event);
        miniPlayer.chart.events.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
        miniPlayer.refreshChart();
    }
    
    public static function onEventDeleted(event:EventStruct):Void
    {
        if (miniPlayer == null) return;
        
        // Remove the event from miniplayer's chart
        miniPlayer.chart.events.remove(event);
        
        // Refresh
        miniPlayer.refreshChart();
    }
    
    /**
     * Call this when the BPM changes
     */
    public static function onBPMChange(time:Float, newBPM:Float, numerator:Float, denominator:Float):Void
    {
        if (miniPlayer == null || miniPlayer.conductor == null) return;
        
        miniPlayer.conductor.changeBpmAt(time, newBPM, numerator, denominator);
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
