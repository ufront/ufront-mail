package ufront.mail;

import tink.CoreApi;

/**
An Abstract representing an email address and an optional name.

It is represented underneath by a `String` represented as '$email;$name'
**/
abstract EmailAddress( String ) {

	/**
	Create a new EmailAddress.

	Will throw an error if "email" is null or not valid according to `EmailAddress.validate()`.
	**/
	public function new( email:String, ?name="" ) {
		if ( email==null || !validate(email) )
			throw 'Invalid email address: $email';

		this = '$email;$name';
	}

	/** The email address. **/
	public var email(get,never):String;
	function get_email() {
		return this.substr( 0, this.indexOf(";") );
	}

	/** The username part of the email address (before the @). **/
	public var username(get,never):String;
	inline function get_username() return email.split("@")[0];

	/** The domain part of the email address (after the @). **/
	public var domain(get,never):String;
	inline function get_domain() return email.split("@")[1];

	/**
	The personal name associated with the email address.
	If none is supplied, this will return null.
	**/
	public var name(get,never):Null<String>;
	function get_name() {
		var split = this.indexOf(";");
		return
			if ( this.length==split+1 ) null
			else this.substr( this.indexOf(";")+1 );
	}

	/**
	Convert a string into an email address (with no name).

	The string should only contain the email address, not a name

	Will throw an exception if the address is invalid.
	**/
	@:from static inline function fromString( email:String ):EmailAddress {
		return new EmailAddress( email );
	}

	/**
	A string of the address.

	If "name" is not null, it will display it as `"$name" <$address>`.
	If name is null, it will just display the address.

	This does not escape any quotations or brackets etc. in the name or address.
	**/
	@:to public inline function toString():String {
		return (name!=null && name!="") ? '"$name" <$email>' : email;
	}

	/**
	Validate an address.

	For now all this does is check there's two parts: before the "@" and after the "@", and that neither contain spaces.

	I haven't found a satisfactory regex solution...
	Please send a pull request if you have any suggestions.
	**/
	public static function validate( email:String ) {
		var parts = email.split('@');

		if ( parts.length!=2 ) return false;
		if ( parts[0].length==0 || parts[0].indexOf(" ")>-1 ) return false;
		if ( parts[1].length==0 || parts[1].indexOf(" ")>-1 ) return false;

		return true;
	}
}
