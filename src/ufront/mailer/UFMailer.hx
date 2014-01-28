package ufront.mailer;

import ufront.mail.Email;
import tink.CoreApi;

/**
	A generic interface for a Mailer - something that sends email.

	The idea is you can use Ufront to inject your preferred mailer, and your app can send emails using it.
	If you change your mind on which mailer to use, or wish to use a different one in different environments, you can. 
	For example, you could use SMTP on one server and a fake Mailer in a development environment.
**/
interface UFMailer {
	/** Send an email, asynchronously **/
	public function send( email:Email ):Surprise<Noise,Error>;

	/** Send an email, synchronously **/
	public function sendSync( email:Email ):Outcome<Noise,Error>;
}