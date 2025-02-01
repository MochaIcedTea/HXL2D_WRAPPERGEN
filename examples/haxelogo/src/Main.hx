import love.window.WindowModule;
import lua.Table;
import love.graphics.Image;
import love.Love;
import love.graphics.GraphicsModule;
import love.graphics.GraphicsModule.GraphicsModuleGetDimensionsResult;
import love.graphics.DrawMode;
import love.LoveProgram;

class Main extends LoveProgram {
	var haxeLogo:Image;
	var windowSize:GraphicsModuleGetDimensionsResult;

	public static function main() {
		new Main();
	}

	public function new() {
		super();
	}

	// this stuff is WEIRD.
	override public function load() {
		windowSize = GraphicsModule.getDimensions();
		haxeLogo = GraphicsModule.newImage("haxe-logo-vertical.png");
	}

	override public function draw() {
		GraphicsModule.clear(0, 0, 0);
		var halfwindowX = (windowSize.width / 2) - (haxeLogo.getWidth() / 2);
		var halfwindowY = (windowSize.height / 2) - (haxeLogo.getHeight() / 2);
		GraphicsModule.draw(haxeLogo, halfwindowX, halfwindowY);
	}

	override public function update(dt:Float) {}
}
