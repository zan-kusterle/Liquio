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
			query: {
				presets: ["es2016"]
			}
		}, {
			test: /\.less$/,
			use: [
				'style-loader',
				{ loader: 'css-loader', options: { importLoaders: 1 } },
				'less-loader'
			]
		}, {
			test: /\.scss$/,
			use: [
				'style-loader',
				{ loader: 'css-loader', options: { importLoaders: 1 } },
				'sass-loader'
			]
		}, {
			test: /\.css$/,
			loader: ExtractTextPlugin.extract({fallback: "style-loader", use: "css-loader"})
		}]
	},
	resolve: {
		modules: [ "node_modules", __dirname + "/web/static/js" ],
		alias: {
			'vue$': 'vue/dist/vue.common.js'
		}
	},
	plugins: [
		new ExtractTextPlugin("./web/static/css/app.css"),
		new CopyWebpackPlugin([{from: "./web/static/assets"}])
	]
};
