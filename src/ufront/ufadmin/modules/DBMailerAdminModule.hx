package ufront.ufadmin.modules;

#if ufront_ufadmin
import ufront.ufadmin.UFAdminModule;
import ufront.mailer.DBMailer;
import ufront.mail.*;
import ufront.web.result.ViewResult;
using DateTools;

class DBMailerAdminModule extends UFAdminModule {
	public function new() {
		super( "dbmailer", "DB Mailer" );
	}

	@:route("/")
	public function index() {
		return listByDate( Date.now() );
	}

	function displayEmailList( emailsList:Iterable<UFMailLog>, title:String ) {
		var emails = Lambda.array( emailsList );
		emails.sort( function(e1,e2) return Reflect.compare(e1.date,e2.date) );
		var template = CompileTime.readFile( "/ufront/ufadmin/view/dbmailer-list.html" );
		return UFAdminModule.wrapInLayout( title, template, {
			emails:emails,
			baseUri:baseUri,
			title:title,
		});
	}

	@:route("/date/$date/")
	public function listByDate( date:Date ) {
		var dateSnappedDown = new Date( date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0 );
		var dateSnappedUp = DateTools.delta( dateSnappedDown, 24*60*60*1000 );
		var dateStr = date.toString();
		var emails = UFMailLog.manager.search( $date>=dateSnappedDown && $date<=dateSnappedUp, { orderBy: -date } );
		return displayEmailList( emails, 'Emails sent on $dateStr' );
	}

	@:route("/to/$address/")
	public function listAllEmailsToAddress( address:String ) {
		var emails = UFMailLog.manager.search( $to==address );
		return displayEmailList( emails, 'Emails sent to $address' );
	}

	@:route("/from/$address/")
	public function listAllEmailsFromAddress( address:String ) {
		var emails = UFMailLog.manager.search( $from==address );
		return displayEmailList( emails, 'Emails sent from $address' );
	}

	@:route("/email/$id/")
	public function showEmail( id:Int ) {
		var mailLog = UFMailLog.manager.get( id );
		var template = CompileTime.readFile( "/ufront/ufadmin/view/dbmailer-view.html" );
		return UFAdminModule.wrapInLayout( title, template, {
			id: mailLog.id,
			to: mailLog.to,
			from: mailLog.from,
			subject: mailLog.subject,
			html: mailLog.email.html,
			text: mailLog.email.text,
			numAttachments: mailLog.numAttachments,
			baseUri: baseUri,
		} );
	}

	@:route("/email/$id/html/")
	public function showEmailHTMLContent( id:Int ) {
		var mailLog = UFMailLog.manager.get( id );
		return mailLog.email.html;
	}
}
#end
