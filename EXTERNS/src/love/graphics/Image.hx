package love.graphics;
import love.image.ImageData;
import haxe.extern.Rest;
import lua.Table;
import lua.UserData;

extern class Image extends Texture
{

	public function isCompressed() : Bool;

	public function isFormatLinear() : Bool;

	public function replacePixels(data:ImageData, ?slice:Float, ?mipmap:Float, ?x:Float, ?y:Float, ?reloadmipmaps:Bool) : Void;
}