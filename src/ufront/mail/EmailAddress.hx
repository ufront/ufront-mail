package ufront.mail;

import tink.CoreApi;

/**
	An Abstract representing an email address and an optional name.

	It is represented underneath by a `tink.core.Pair<String,String>`, which is usually a Vector with 2 items, so performance is quite good.
	The first value in the pair is a `String` representing the email address, the second is a `String` representing an email.
**/
abstract EmailAddress(Pair<String,String>) {

	/**
		Create a new EmailAddress.  Will throw an error if "email" is null or not valid according to `EmailAddress.validate()`
	**/
	public inline function new( email:String, ?name:String ) {
		if ( email==null || !validate(email) ) 
			throw 'Invalid email address $email';

		this = new Pair( email, name );
	}

	/** The email address **/
	public var email(get,null):String;
	inline function get_email() return this.a;

	/** The username part of the email address (before the @) **/
	public var username(get,null):String;
	inline function get_username() return this.a.split("@")[0];

	/** The domain part of the email address (after the @) **/
	public var domain(get,null):String;
	inline function get_domain() return this.a.split("@")[1];
	
	/** The personal name associated with the email address **/
	public var name(get,null):String;
	inline function get_name() return this.b;

	/**
		Convert a string into an email address (with no name). 

		The string should only contain the email address, not a name

		Will throw an exception if the address is invalid. 
	**/
	@:from static inline function fromString( email:String ):EmailAddress {
		return new EmailAddress( email );
	}

	/**
		Convert an array into an email address.  

		It will assume the first String in the array is the email address, and the second is the name.

		If an email address is not provided, or is invalid, an exception will be thrown.

		If a name is not provided, it will be null.

		If there are extra parts in the array, they will be ignored.
	**/
	@:from static function fromArray( parts:Array<String> ):EmailAddress {
		var email = parts[0];
		var name = parts[1];
		
		return new EmailAddress( email, name );
	}

	/** 
		A string of the address.  

		If "name" is not null, it will display it as `"$name" <$address>`.  
		If name is null, it will just display the address. 

		This does not escape any quotations or brackets etc. in the name or address.
	**/
	@:to static inline function toString( email:String ):EmailAddress {
		return (this.b!=null) ? '"${this.b}" <${this.a}>' : this.a;
	}

	/**
		Validate an address using a fairly basic regular expression from http://www.regular-expressions.info/email.html

		I may need to losen this as top-level domains come online, or if support for international characters becomes an issue.

		Please send a pull request if you have any suggestions.
	**/
	public static inline function validate( email:String ) {
		return validationRegex.match( email );
	}

	static var validationRegex = new Ereg( "^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$", "i" );
}
