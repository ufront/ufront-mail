package ufront.mail;

#if ufront_orm
import ufront.db.Object;
import sys.db.Types;

/**
A database record that tracks an email that has been sent.

For use with `DBMailer`.
**/
class UFMailLog extends Object {
	public var to:SString<255>;
	public var from:SString<255>;
	public var subject:SString<255>;
	public var date:SDateTime;
	public var email:SData<Email>;
	public var numAttachments:Int;
}
#end
