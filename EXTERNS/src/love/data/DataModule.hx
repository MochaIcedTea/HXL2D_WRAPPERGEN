package love.data;
import love.Data;
import haxe.extern.Rest;
import lua.Table;
import lua.UserData;

@:native("love.data")
extern class DataModule
{

	@:overload(function (container:ContainerType, format:CompressedDataFormat, data:Data, ?level:Float) : CompressedData or string {})
	public static function compress(container:ContainerType, format:CompressedDataFormat, rawstring:String, ?level:Float) : CompressedData or string;

	@:overload(function (container:ContainerType, format:EncodeFormat, sourceData:Data) : ByteData or string {})
	public static function decode(container:ContainerType, format:EncodeFormat, sourceString:String) : ByteData or string;

	@:overload(function (container:ContainerType, format:CompressedDataFormat, compressedString:String) : Data or string {})
	@:overload(function (container:ContainerType, format:CompressedDataFormat, data:Data) : Data or string {})
	public static function decompress(container:ContainerType, compressedData:CompressedData) : Data or string;

	@:overload(function (container:ContainerType, format:EncodeFormat, sourceData:Data, ?linelength:Float) : ByteData or string {})
	public static function encode(container:ContainerType, format:EncodeFormat, sourceString:String, ?linelength:Float) : ByteData or string;

	public static function getPackedSize(format:String) : Float;

	@:overload(function (hashFunction:HashFunction, data:Data) : String {})
	public static function hash(hashFunction:HashFunction, string:String) : String;

	@:overload(function (Data:Data, ?offset:Float, ?size:Float) : ByteData {})
	@:overload(function (size:Float) : ByteData {})
	public static function newByteData(datastring:String) : ByteData;

	public static function newDataView(data:Data, offset:Float, size:Float) : Data;

	public static function pack(container:ContainerType, format:String, v1:number or boolean or string, args:Rest<number or boolean or string>) : Data or string;

	@:overload(function (format:String, data:Data, ?pos:Float) : DataModuleUnpackResult {})
	public static function unpack(format:String, datastring:String, ?pos:Float) : DataModuleUnpackResult;
}

@:multiReturn
extern class DataModuleUnpackResult
{
	var v1 : number or boolean or string;
	var index : Float;
}