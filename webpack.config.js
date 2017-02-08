var ExtractTextPlugin = require("extract-text-webpack-plugin");
var CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
	entry: ["./web/static/css/app.less", "./web/static/js/app.js"],
	output: {
		path: "./priv/static",
		filename: "js/app.js"
	},
	module: {
		loaders: [{
			test: /\.js$/,
			exclude: /node_modules/,
			loader: "babel-loader",
			include: __dirname,
			query: {
				presets: ["es2015"]
			}
		}, {
			test: /\.less$/,
			loader: ExtractTextPlugin.extract({fallback: 'style', use: 'css'})
		}],
		rules: [{
			test: /\.less$/,
			use: [
				'style-loader',
				{ loader: 'css-loader', options: { importLoaders: 1 } },
				'less-loader'
			]
		}]
	},
	resolve: {
		modules: [ "node_modules", __dirname + "/web/static/js" ],
		alias: {
			'vue$': 'vue/dist/vue.common.js'
		}
	},
	plugins: [
		new ExtractTextPlugin("css/app.css"),
		new CopyWebpackPlugin([{ from: "./web/static/assets" }])
	]
};
