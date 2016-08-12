package ufront.mailer;

import ufront.mail.*;
using tink.CoreApi;

/**
A UFMailer implementation that just stores the messages in memory, making it easy to run unit tests.
**/
class TestMailer implements UFMailer {

	public var emulateFailure:Bool;
	public var messagesSent:Array<Email>;
	public var messagesFailed:Array<Email>;

	public function new( ?emulateFailure=false ) {
		this.emulateFailure = emulateFailure;
		reset();
	}

	public function reset() {
		this.messagesSent = [];
		this.messagesFailed = [];
	}

	public function send( email:Email ) {
		return Future.sync( sendSync(email) );
	}

	public function sendSync( email:Email ) {
		if ( emulateFailure ) {
			messagesFailed.push( email );
			return Failure( new Error("TestMailer is emulating a fail to email.") );
		}
		else {
			messagesSent.push( email );
			return Success( Noise );
		}
	}
}
