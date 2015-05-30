package ufront.mailer;

import ufront.mail.*;
using tink.CoreApi;

/**
A UFMailer implementation that does not send any email.
**/
class NullMailer implements UFMailer {

	public var emulateFailure:Bool;

	public function new( ?emulateFailure=false ) {
		this.emulateFailure = emulateFailure;
	}

	public function send( email:Email ) {
		return Future.sync( sendSync(email) );
	}

	public function sendSync( email:Email ) {
		return emulateFailure ? Failure( new Error("NullMailer is emulating a fail to email.") ) : Success(Noise);
	}
}
