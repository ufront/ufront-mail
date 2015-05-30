package ufront.mail;

import haxe.io.Bytes;
import tink.CoreApi;
using Lambda;

/**
A representation of an Email Message.

This is simple a data structure, it does not contain logic on how to send the email.
An appropriate `UFMailer` must be used to send the message.

This class uses a "fluent" API (chainable, jQuery style) for quickly putting together an email.
For example:

```haxe
new Email().to("boss@example.org").from("worker@example.org").subject("Where is my pay check?!?");
```
**/
class Email {

	/**
	The headerOrder when `getHeaders()` is called.

	Default:

	```
	"Return-Path","Received","Date","From","Subject","Sender","To",
	"Cc","Bcc","Content-Type","X-Mailer","X-Originating-IP","X-Originating-User"
	```

	You can change this array to influence the order headers are printed.
	**/
	public static var headerOrder = [
		"Return-Path","Received","Date","From","Subject","Sender","To",
		"Cc","Bcc","Content-Type","X-Mailer","X-Originating-IP","X-Originating-User"
	];

	// Addresses

	public var fromAddress(default,null):EmailAddress = null;
	public var replyToAddress(default,null):EmailAddress = null;
	public var toList(default,null):List<EmailAddress>;
	public var ccList(default,null):List<EmailAddress>;
	public var bccList(default,null):List<EmailAddress>;

	// Headers

	public var date:Date;
	public var charset:String;
	public var headers(default,null):Map<String,Array<String>>;

	// Content

	public var subject:String = "";
	public var text:String = null;
	public var html:String = null;
	public var images:List<EmailAttachment>;
	public var attachments:List<EmailAttachment>;

	// Constructor

	public function new() {
		toList = new List();
		ccList = new List();
		bccList = new List();

		headers = new Map();
		date = Date.now();
		charset = EmailConstants.UTF_8;

		images = new List();
		attachments = new List();
	}

	// Fluent API

	/**
	Add an email address (or list of addresses) to the `toList`
	**/
	public function to( ?email:EmailAddress, ?emails:Iterable<EmailAddress> ):Email {
		if ( email!=null ) toList.add( email );
		if ( emails!=null ) for ( e in emails ) toList.add( e );
		return this;
	}

	/**
	Add an email address (or list of addresses) to the `ccList`
	**/
	public function cc( ?email:EmailAddress, ?emails:Iterable<EmailAddress> ):Email {
		if ( email!=null ) ccList.add( email );
		if ( emails!=null ) for ( e in emails ) ccList.add( e );
		return this;
	}

	/**
	Add an email address (or list of addresses) to the `bccList`
	**/
	public function bcc( ?email:EmailAddress, ?emails:Iterable<EmailAddress> ):Email {
		if ( email!=null ) bccList.add( email );
		if ( emails!=null ) for ( e in emails ) bccList.add( e );
		return this;
	}

	/**
	Set the `from` email address
	**/
	public function from( email:EmailAddress ):Email {
		fromAddress = email;
		return this;
	}

	/**
	Set the `reply-to` email address
	**/
	public function replyTo( email:EmailAddress ):Email {
		replyToAddress = email;
		return this;
	}

	/**
	Add a header.

	If a header with the same name already exists, this will be included as well.
	**/
	public function addHeader( name, value ):Email {
		if ( headers.exists(name) )
			headers.get( name ).push( value );
		else
			headers.set( name, [value] );

		return this;
	}

	/**
	Set a header.

	If a header with the same name already exists, this value will replace the existing value.
	**/
	public function setHeader( name, value ):Email {
		headers.set( name, [value] );
		return this;
	}

	/**
	Get a header.

	If more than one header with this name exists, it will use the first header.

	If no such header exists, it will return `null`.
	**/
	public function getHeader( name ):Null<String> {
		if ( headers.exists(name) )
			return headers.get( name )[0];
		else
			return null;
	}

	/**
	Get all headers with the given name as an array of strings.

	If there is only one header with the given name, the array will contain only one item.

	If no such header exists, an empty array will be returned.
	**/
	public function getHeadersNamed( name ):Array<String> {
		if ( headers.exists(name) )
			return headers.get( name );
		else
			return [];
	}

	/**
	Get all the headers set.

	The order of the headers is defined by the static array `headerOrder`.
	You can modify this in order to have the headers appear in a different order.

	Returns an array where each item is an object containing a name and a value.
	**/
	public function getHeaders():Array<Pair<String,String>> {
		var arr = [];

		for ( n in headers.keys() ) {
			for ( v in headers.get(n) ) {
				arr.push( new Pair(n,v) );
			}
		}

		arr.sort( function(h1,h2) return Reflect.compare(headerOrder.indexOf(h1.a), headerOrder.indexOf(h2.a)) );

		return arr;
	}

	/**
	Set the "sent date" for this email
	**/
	public function setDate( date:Date ):Email {
		this.date = date;
		return this;
	}

	/**
	Set the charset for this email.
	**/
	public function setCharset( charset:String ):Email {
		this.charset = charset;
		return this;
	}

	/**
	Set the subject for this email.
	**/
	public function setSubject( ?subject:String="" ):Email {
		this.subject = subject;
		return this;
	}

	/**
	Set the html content for this email.

	If this is null, and there are no attachments, the email will send with a content type of "text/plain".
	**/
	public function setHtml( ?html:String ):Email {
		this.html = html;
		return this;
	}

	/**
	Set the plain text content for this email.

	If this is null, and there are no attachments, the email will send with a content type of "text/html".
	**/
	public function setText( ?text:String ):Email {
		this.text = text;
		return this;
	}

	/**
	Attach a file to this email.
	**/
	public function attach( name:String, type:String, content:Bytes ):Email {
		this.attachments.add( new EmailAttachment(name,type,content) );
		return this;
	}

	/**
	Attach an image to be embedded in this email.
	**/
	public function attachImage( name:String, type:String, content:Bytes ):Email {
		this.images.add( new EmailAttachment(name,type,content) );
		return this;
	}
}
