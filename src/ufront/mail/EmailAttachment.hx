package ufront.mail;

import haxe.io.Bytes;
import haxe.Serializer;
import haxe.Unserializer;

/**
An abstract describing an email attachment - essentially an attachment file type, a file name, and a set of `Bytes` content.
**/
abstract EmailAttachment({ type:String, name:String, content:Bytes }) {
	inline public function new( type, name, content ) {
		this = { type: type, name: name, content: content };
	}

	public var type(get,set):String;
	public var name(get,set):String;
	public var content(get,set):Bytes;
	public var contentBase64(get,never):String;

	inline function get_type() return this.type;
	inline function set_type(v) return this.type = v;
	inline function get_name() return this.name;
	inline function set_name(v) return this.name = v;
	inline function get_content() return this.content;
	inline function set_content(v) return this.content = v;
	inline function get_contentBase64() return base64Encode( this.content );

	/** Piggy back off of haxe Unserializer **/
	public static function base64Decode( str:String ):Bytes {
		return Unserializer.run( 's'+str.length+':'+str );
	}

	/** Piggy back off of haxe Serializer **/
	public static function base64Encode( b:Bytes ):String {
		var fullStr:String = Serializer.run( b );
		return fullStr.substr( fullStr.indexOf(":")+1 );
	}
}
