package love;

import lua.Table;
import love.Love;

class LoveProgram {
	public var args:Table<Dynamic, Dynamic>;
	public var unfilteredArgs:Table<Dynamic, Dynamic>;

	public function new() {
		Love.load = ___load;
		Love.draw = draw;
		Love.update = update;
	}

	private function ___load(args:Table<Dynamic, Dynamic>, unfilteredArgs:Table<Dynamic, Dynamic>):Dynamic {
		this.args = args;
		this.unfilteredArgs = unfilteredArgs;
		load();
		return null;
	}

	public function load() {}

	public function update(dt:Float) {}

	public function draw() {}
}
