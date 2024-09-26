const defaultConfig = require( '@wordpress/scripts/config/webpack.config' );
const path = require( 'path' );

module.exports = {
	...defaultConfig,
	entry: {
		...defaultConfig.entry(),
		'multi-block-editor': [
			path.resolve( __dirname, 'src/scripts/multi-block-editor.js' ),
		],
		'multi-block-admin': [
			path.resolve( __dirname, 'src/scripts/multi-block-admin.js' ),
		],
		'multi-block-frontend': [
			path.resolve( __dirname, 'src/scripts/multi-block-frontend.js' ),
		],
	},
};
