package moon.toolkit.level_editor.pages;

import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.core.Screen;

//TODO
// its broken :P
@:dox(hide)
class PanelPage
{
    public var title:String;

    public var panel:LeftPanel;

    public var root:ScrollView;
    public var content:VBox;

    public function new(title:String = 'Page')
    {
        this.title = title;

        root = new ScrollView();
        root.styleString = "background-color: #0b0b0b; border: none; padding: 0;";
        root.visible = false;

        content = new VBox();
        content.styleString = "background-color: null; border: none; padding: 8px; spacing: 6px;";
        root.addComponent(content);

        Screen.instance.addComponent(root);

        build();
    }

    public function build():Void {}

    public function onOpen():Void {}

    public function onClose():Void {}

    public inline function push(page:PanelPage):Void
        if (panel != null) panel.push(page);

    public inline function pop():Void
        if (panel != null) panel.pop();

    public function show(x:Float, y:Float, w:Float, h:Float):Void
    {
        root.left = x;
        root.top = y;
        root.width = w;
        root.height = h;
        content.width = w;
        root.visible = true;
        onOpen();
    }

    public function hide():Void
    {
        root.visible = false;
        onClose();
    }

    public function destroy():Void
    {
        if (root != null)
        {
            root.visible = false;
            Screen.instance.removeComponent(root);
            root = null;
            content = null;
        }
    }
}
