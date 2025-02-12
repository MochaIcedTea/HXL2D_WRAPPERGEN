package love;

import lua.Table;
import love.Love;
import love.keyboard.KeyConstant;
import love.keyboard.Scancode;

class LoveProgram {
	public var args:Table<Dynamic, Dynamic>;
	public var unfilteredArgs:Table<Dynamic, Dynamic>;

	public function new() {
		Love.load = function(args:Table<Dynamic, Dynamic>, unfilteredArgs:Table<Dynamic, Dynamic>):Dynamic {
			this.args = args;
			this.unfilteredArgs = unfilteredArgs;
			load();
			return null;
		}
		Love.draw = draw;
		Love.update = update;
		Love.keypressed = function(k:String, c:String, ir:Bool) {
			this.keyPressed(cast k, cast c, ir);
		}
	}

	public function load() {}

	public function update(dt:Float) {}

	public function draw() {}

	public function keyPressed(keyCode:KeyConstant, scancode:Scancode, isRepeat:Bool) {}
}
