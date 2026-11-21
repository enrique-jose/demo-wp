<?php
/**
 * Plugin Name: demo-wp build header
 * Description: Pipeline test. Adds an X-Demo-WP response header so a deploy of this fork is verifiable with curl.
 */

defined( 'ABSPATH' ) || exit;

add_action(
	'send_headers',
	static function () {
		header( 'X-Demo-WP: fork' );
	}
);
