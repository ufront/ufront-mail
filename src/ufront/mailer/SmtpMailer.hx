package ufront.mailer;

import mtwin.mail.Part;
import mtwin.mail.Tools;
import ufront.mail.*;
using tink.CoreApi;

#if sys

import sys.net.Socket;
import sys.net.Host;
import mtwin.mail.Exception;

/**
A `UFMailer` that sends messages by SMTP.

This relies on the `mtwin` haxelib for SMTP support.
It currently only supports sending emails over unsecured SMTP.

It is only supported on SYS platforms and runs synchronously.
**/
class SmtpMailer implements UFMailer {

	var host:String;
	var port:Int;
	var authUser:String;
	var authPassword:String;

	public function new( server:{ host:String, ?port:Int, user:String, pass:String } ) {
		this.host = server.host;
		this.port = (server.port!=null) ? server.port : 25;
		this.authUser = server.user;
		this.authPassword = server.pass;
	}

	public function send( email:Email ) {
		return Future.sync( sendSync(email) );
	}

	public function sendSync( email:Email ) {

		var p:Part = null;
		var numAttachments = email.images.length+email.attachments.length;

		if ( email.text!=null && email.html!=null ) {
			// text & html (& possibly attachments)
			p = new Part( "multipart/alternative", false, email.charset );
			var t = p.newPart( "text/plain" );
			var h = p.newPart( "text/html" );
			t.setContent( email.text );
			h.setContent( email.html );
		}
		else if ( email.text!=null && numAttachments>0 ) {
			// text & attachments
			p = new Part( "multipart/alternative", false, email.charset );
			var t = p.newPart( "text/plain" );
			t.setContent( email.text );
		}
		else if ( email.text!=null ) {
			// simple text
			p = new Part( "text/plain", false, email.charset );
			p.setContent( email.text );
		}
		else if ( email.html!=null && numAttachments>0 ) {
			// html & attachments
			p = new Part( "multipart/alternative", false, email.charset );
			var h = p.newPart( "text/html" );
			h.setContent( email.html );
		}
		else if ( email.html!=null ) {
			// simple text
			p = new Part( "text/html", false, email.charset );
			p.setContent( email.html );
		}
		else if ( email.text==null && email.html==null && numAttachments>0 ) {
			// attachments only, no content
			p = new Part( "multipart/alternative", false, email.charset );
			var t = p.newPart( "text/plain" );
			t.setContent( "" );
		}
		else if ( email.text==null && email.html==null && numAttachments==0 ) {
			// completely empty message
			p = new Part( "text/plain", false, email.charset );
			p.setContent( "" );
		}

		// Set subject, date

		p.setHeader( "Subject", email.subject );
		p.setDate( email.date );

		// Add other headers

		for ( header in email.getHeaders() ) {
			p.addHeader( header.a, header.b );
		}

		// Add attachments

		function addAttachments( list:List<EmailAttachment> ) {
			for ( a in list ) {
				var aPart = p.newPart( a.type );
				aPart.content = a.contentBase64;
				aPart.setHeader("Content-Type",a.type+"; name=\""+a.name+"\"");
				aPart.setHeader("Content-Disposition","attachment; filename=\""+a.name+"\"");
				aPart.setHeader("Content-Transfer-Encoding","base64");
			}
		}
		addAttachments( email.images );
		addAttachments( email.attachments );

		// Add Addresses to headers

		function printList( l:List<EmailAddress> ) {
			return [ for (a in l) if (a!=null) a.toString() ].join(",");
		}
		p.setHeader( "From", email.fromAddress.toString() );
		if (email.replyToAddress!=null) p.setHeader( "Reply-To", email.replyToAddress.toString() );
		if (email.toList.length>0) p.setHeader( "To", printList(email.toList) );
		if (email.ccList.length>0) p.setHeader( "Cc", printList(email.ccList) );

		var toList = [ for (list in [email.toList, email.ccList, email.bccList]) for (address in list) if (address!=null) address.email ];

		sendSmtp( host, email.fromAddress.email, toList, p.get(), port, authUser, authPassword );

		return Success(Noise);
	}

	/**
		A copy of `mtwin.mail.Smtp`, except it can send to multiple addresses at once
	**/
	public static function sendSmtp( host : String, from : String, toList : Iterable<String>, data : String, ?port: Int, ?user: String, ?password: String ){
		if( port == null ) port = 25;

		var cnx = new Socket();

		try {
			cnx.connect(new Host(host),port);
		}catch( e : Dynamic ){
			cnx.close();
			throw ConnectionError(host,port);
		}

		var supportLoginAuth = false;

		// get server init line
		var ret = StringTools.trim(cnx.input.readLine());
		var esmtp = ret.indexOf("ESMTP") >= 0;


		while (StringTools.startsWith(ret, "220-")) {
			ret = StringTools.trim(cnx.input.readLine());
		}

		if ( esmtp ) { //if server support extensions
			//EHLO
			cnx.write( "EHLO " + Host.localhost() + "\r\n");
			ret = "";

			do {
				ret = StringTools.trim(cnx.input.readLine());
				if( ret.substr(0,3) != "250" ){
					cnx.close();
					throw BadResponse(ret);
				} else if ( ret.substr(4, 4) == "AUTH" && ret.indexOf("LOGIN") != -1) {
					supportLoginAuth = true;
				}
			} while(ret.substr(0,4) != "250 ");
		} else {
			//HELO
			cnx.write( "HELO " + Host.localhost() + "\r\n");
			ret = StringTools.trim(cnx.input.readLine());
			if( ret.substr(0,3) != "250" ){
				cnx.close();
				throw BadResponse(ret);
			}
		}

		if ( user != null ) { //if we were asked to login
			if ( supportLoginAuth ) { //if server support AUTH LOGIN
				cnx.write( "AUTH LOGIN\r\n" );
				ret = StringTools.trim(cnx.input.readLine());
				if( ret.substr(0,3) != "334" ){
					cnx.close();
					throw SmtpAuthError(ret);
				}

				cnx.write( Tools.encodeBase64(user) + "\r\n" );
				ret = StringTools.trim(cnx.input.readLine());
				if( ret.substr(0,3) != "334" ){
					cnx.close();
					throw SmtpAuthError(ret);
				}
				cnx.write( Tools.encodeBase64(password) + "\r\n" );
				ret = StringTools.trim(cnx.input.readLine());
				if( ret.substr(0,3) != "235" ){
					cnx.close();
					throw SmtpAuthError(ret);
				}
			} else {
				throw SmtpAuthError("Authorization with 'login' method not supported by server");
			}
		}

		cnx.write( "MAIL FROM:<" + from + ">\r\n" );
		ret = StringTools.trim(cnx.input.readLine());
		if( ret.substr(0,3) != "250" ){
			cnx.close();
			throw SmtpMailFromError(ret);
		}

		for ( to in toList ) {
			cnx.write( "RCPT TO:<" + to + ">\r\n" );
			ret = StringTools.trim(cnx.input.readLine());
			if( ret.substr(0,3) != "250" ){
				cnx.close();
				throw SmtpRcptToError(ret);
			}
		}

		cnx.write( "DATA\r\n" );
		ret = StringTools.trim(cnx.input.readLine());
		if( ret.substr(0,3) != "354" ){
			cnx.close();
			throw SmtpDataError(ret);
		}

		var a = ~/\r?\n/g.split(data);
		var lastEmpty = false;
		for( l in a ){
			if( l.substr(0,1) == "." )
				l = "."+l;
			cnx.write(l);
			cnx.write("\r\n");
		}
		if( a[a.length-1] != "" )
			cnx.write("\r\n");
		cnx.write( ".\r\n" );

		ret = StringTools.trim(cnx.input.readLine());
		if( ret.substr(0,3) != "250" ){
			cnx.close();
			throw SmtpSendDataError;
		}

		cnx.write( "QUIT\r\n" );
		cnx.close();
	}
}
#end
