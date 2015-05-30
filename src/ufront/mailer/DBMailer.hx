package ufront.mailer;

#if ufront_orm
import ufront.mail.*;
import ufront.db.Object;
import sys.db.Types;
import ufront.web.Controller;
using tink.CoreApi;

/**
A Mailer that records all sent emails to the database.

You can optionally wrap another mailer (such as `SmtpMailer`), so that real mail is sent, AND we log all messages sent.

If DBMailer is wrapping another mailer, the outcomes (telling whether it worked or not) will be based on the mailer we are wrapping, not the DB saving.
**/
class DBMailer<T:UFMailer> implements UFMailer {

	var mailer:UFMailer;

	/**
	@param wrapMailer: An existing mailer to use. All calls to `send()` and `sendSync()` will save the message to the DB, and also call the same method on the mailer you are wrapping.
	**/
	public function new( ?wrapMailer:UFMailer ) {
		this.mailer = wrapMailer;
	}

	public function send( email:Email ) {
		saveToDB( email );
		return (mailer!=null) ? mailer.send(email) : Future.sync( Success(Noise) );
	}

	public function sendSync( email:Email ) {
		saveToDB( email );
		return (mailer!=null) ? mailer.sendSync(email) : Success(Noise);
	}

	inline function saveToDB( email:Email ) {
		for ( address in allToAddresses(email) ) {
			var o = createEntryForEmail( address, email );
			o.save();
		}
	}

	function allToAddresses( email:Email ) {
		return [ for (list in [email.toList, email.ccList, email.bccList]) for (address in list) if (address!=null) address.email ];
	}

	function createEntryForEmail( to:String, email:Email ) {
		var o = new UFMailLog();
		o.to = to;
		o.from = email.fromAddress.email;
		o.subject = email.subject;
		o.date = email.date;
		o.email = email;
		o.numAttachments = email.images.length+email.attachments.length;
		return o;
	}
}
#end
