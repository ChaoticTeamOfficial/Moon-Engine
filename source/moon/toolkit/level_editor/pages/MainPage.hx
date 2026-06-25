package moon.toolkit.level_editor.pages;

import haxe.ui.components.*;
import haxe.ui.containers.*;

class MainPage extends PanelPage
{
	public function new()
	{
		super("menu");
	}

	override function build()
	{
		var btn = new Button();
		btn.text = "Go deeper";
		btn.onClick = _ -> trace('fuck');
		content.addComponent(btn);
	}
}
