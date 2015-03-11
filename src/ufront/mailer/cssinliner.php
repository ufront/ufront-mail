<?php

// Load the CssToInlineStyles class

require_once __DIR__ . '/vendor/autoload.php';
use TijsVerkoyen\CssToInlineStyles\CssToInlineStyles;

// Read the HTML from Std in

$html = "";
$f = fopen( 'php://stdin', 'r' );
while( $line = fgets( $f ) ) {
  $html = $html . $line;
}
fclose( $f );

// Extract the CSS from the <style> tag

$dom = new DOMDocument();
$dom->loadHTML( $html );
$dom->preserveWhiteSpace = false;
$elements = $dom->getElementsByTagName( "style" );
$css = "";
foreach($elements as $element) {
	$css = $css . $element->firstChild->textContent;
}

// Run the conversion

$cssToInlineStyles = new CssToInlineStyles();
$cssToInlineStyles->setHTML($html);
$cssToInlineStyles->setCSS($css);
$inlineHTML = $cssToInlineStyles->convert();

// Write the output to STDOUT

echo $inlineHTML;