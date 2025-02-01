import love.window.WindowModule;
import lua.Table;
import love.graphics.Image;
import love.Love;
import love.graphics.GraphicsModule;
import love.graphics.GraphicsModule.GraphicsModuleGetDimensionsResult;
import love.graphics.DrawMode;

class Main {
	var haxeLogo:Image;
	var windowSize:GraphicsModuleGetDimensionsResult;

	public static function main() {
		new Main();
	}

	public function new() {
		haxeLogo = GraphicsModule.newImage("haxe-logo-vertical.png");
		windowSize = GraphicsModule.getDimensions();
		Love.load = init;
		Love.draw = draw;
		Love.update = update;
	}

	// this stuff is WEIRD.
	public function init(thing:Table<Dynamic, Dynamic>, thing2:Table<Dynamic, Dynamic>):Dynamic {
		return null;
	}

	public function draw() {
		GraphicsModule.clear(0, 0, 0);
		var halfwindowX = (windowSize.width / 2) - (haxeLogo.getWidth() / 2);
		var halfwindowY = (windowSize.height / 2) - (haxeLogo.getHeight() / 2);
		GraphicsModule.draw(haxeLogo, halfwindowX, halfwindowY);
	}

	public function update(dt:Float) {}
}
