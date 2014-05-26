package ufront.mailer;

import ufront.mail.*;
import ufront.db.Object;
import sys.db.Types;
import ufront.web.Controller;
using tink.CoreApi;

/**
	A Mailer that records all sent emails to the database.

	You can optionally wrap another mailer (such as SMTPMailer), so that real mail is sent, AND we log all messages sent.

	If DBMailer is wrapping another mailer, the outcomes (telling whether it worked or not) will be based on the mailer we are wrapping, not the DB saving.
**/
class DBMailer<T:UFMailer> implements UFMailer {
	
	var mailer:UFMailer;

	/**
		@param wrapMailer: An existing mailer to use.  
		                   All calls to send() and sendSync() will save the message to the DB, and also call the same method on the mailer you are wrapping.
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

class UFMailLog extends Object {
	public var to:SString<255>;
	public var from:SString<255>;
	public var subject:SString<255>;
	public var date:SDate;
	public var email:SData<Email>;
	public var numAttachments:Int;
}

#if server
	class UFMailLogViewController extends Controller {
		@:route("/")
		public function doDefault() {
			var q = 'SELECT to, date, COUNT(to) AS numMessages FROM UFMailLog GROUP BY to ORDER BY date DESC';
			var rs = sys.db.Manager.cnx.request( q );
			for ( row in rs ) {
				var to:String = row.to;
				var count:Int = row.numMessages;
				var date:Date = row.date;
				trace ( '<a href="viewaddress/$to">$to</a>' );
			}
		}

		@:route("/viewaddress/$emailAddress/")
		public function doViewAddress( emailAddress:String ) {
			var emails = UFMailLog.manager.search( $to==emailAddress );
			for ( e in emails ) {
				trace ( '<a href="viewmessage/${e.id}"><strong>$e.from</strong> $e.subject <small>($e.date)</small></a>' );
			}
		}

		@:route("/viewmessage/$msgID/")
		public function doViewMessage( msgID:Int ) {
			var email = UFMailLog.manager.get( msgID );
			trace ( 'toList: ' + email.email.toList );
			trace ( 'ccList: ' + email.email.ccList );
			trace ( 'bccList: ' + email.email.bccList );
			trace ( 'from: ' + email.email.from );
			trace ( 'replyTo: ' + email.email.replyTo );
			trace ( 'subject: ' + email.email.subject );
			trace ( 'html: ' + email.email.html );
			trace ( 'text: ' + email.email.text );
			for ( img in email.email.images ) {
				trace ( 'img: ${img.type} ${img.name}' );
			}
			for ( att in email.email.attachments ) {
				trace ( 'attachment: ${att.type} ${att.name}' );
			}
		}
	}
#end