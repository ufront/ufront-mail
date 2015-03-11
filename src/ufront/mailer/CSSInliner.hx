package ufront.mailer;

import ufront.mail.*;
import ufront.db.Object;
import sys.db.Types;
import ufront.web.Controller;
using tink.CoreApi;

/**
	A Mailer that will just call a different mailer, but will inline CSS styles as it goes.

	It uses a configurable CSS Inlining service.

	For now, an implementation which calls the [CssToInlineStyles](https://github.com/tijsverkoyen/CssToInlineStyles/) PHP script is provided.
	In future hopefully we'll have less platform dependant
**/
class CSSInliner<T:UFMailer> implements UFMailer {

	var mailer:UFMailer;
	var inliner:CSSInlinerTool;

	/**
		@param inliner: The inliner tool to use. See implementations of `CSSInlinerTool`.
		@param wrapMailer: An existing mailer to use to actually send the emails after we've done our inlining.
	**/
	public function new( inliner:CSSInlinerTool, wrapMailer:UFMailer ) {
		this.mailer = wrapMailer;
		this.inliner = inliner;
	}

	public function send( email:Email ) {
		email.html = inliner.inlineStyles( email.html );
		return mailer.send(email);
	}

	public function sendSync( email:Email ) {
		email.html = inliner.inlineStyles( email.html );
		return mailer.sendSync(email);
	}
}

interface CSSInlinerTool {
	/**
		A function which will take HTML and inline any styles.
		Each inliner should inline the `<style>` tags in the head.
		Whether or not we inline `<link type="text/css" rel="stylesheet">` is up to the inliner.
	**/
	public function inlineStyles( html:String ):String;

	// TODO: Decide if we should we allow for an async implementation? If you wanted to use the premailer web service etc, or load remote stylesheets asynchronously etc.
}

#if sys
	/**
		This uses the [CssToInlineStyles](https://github.com/tijsverkoyen/CssToInlineStyles/) PHP script to inline styles.
		Your server must have PHP installed, but we call this using the `sys.io.Process` api and the `php` command line, so your app doesn't need to be targetting PHP.
		You must have the PHP file and it's dependencies installed on your system.
		You can set the path to the PHP script with the string passed to the constructor.
		If using dependency injection it will look for a String "pathForCssToInlineStylesScript".
	**/
	class PHPCssToInlineStyles implements CSSInlinerTool {

		public static function setupInlinerScript( scriptPath:String ) {
			var directory = haxe.io.Path.directory( scriptPath );
			var filename = haxe.io.Path.withoutDirectory( scriptPath );
			var oldCwd = Sys.getCwd();

			try {
				trace('Create the script directory');
				sys.FileSystem.createDirectory( directory );
				Sys.setCwd( directory );

				trace('Run `curl -sS https://getcomposer.org/installer | php`');
				var curl = new sys.io.Process( "curl", ["-sS","https://getcomposer.org/installer"] );
				var php = new sys.io.Process( "php", [] );
				php.stdin.writeInput( curl.stdout );
				php.stdin.close();
				curl.exitCode();
				php.exitCode();

				trace('Run `composer require tijsverkoyen/css-to-inline-styles "~1.5"`');
				Sys.command('php', ['composer.phar','require','tijsverkoyen/css-to-inline-styles', '~1.5']);

				trace('Save our wrapper PHP Script to $filename');
				sys.io.File.saveContent( filename, CompileTime.readFile("ufront/mailer/cssinliner.php") );

				// Move back to the old DIR
				Sys.setCwd( oldCwd );
				trace('Done');
			}
			catch ( e:Dynamic ) {
				Sys.setCwd( oldCwd );
				throw 'Failed to set up inliner script: $e';
			}
		}

		var scriptPath:String;

		@inject("pathForCssToInlineStylesScript")
		public function new( scriptPath:String ) {
			this.scriptPath = scriptPath;
		}

		public function inlineStyles( html:String ) {
			var p = new sys.io.Process( "php", [scriptPath] );
			p.stdin.writeString( html );
			p.stdin.close();
			p.exitCode();
			return p.stdout.readAll().toString();
		}
	}
#end