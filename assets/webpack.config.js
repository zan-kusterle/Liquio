/* eslint-disable */

var path = require('path')
var CopyWebpackPlugin = require('copy-webpack-plugin')
var webpack = require('webpack')
const { CheckerPlugin } = require('awesome-typescript-loader')

let publicUrl = process.env.NODE_ENV === 'production' ? 'https://liqu.io' : 'http://localhost:4000'

let baseConfig = {
	mode: 'development',
	output: {
		path: path.resolve(__dirname, '../priv/static'),
		filename: '[name].js',
		publicPath: publicUrl
	},
	devtool: process.env.NODE_ENV === 'production' ? false : 'inline-source-map',
	module: {
		rules: [{
			test: /\.vue$/,
			loader: 'vue-loader'
		},
		{
			test: /\.ts$/,
			loader: 'awesome-typescript-loader'
		},
		{
			test: /\.js$/,
			exclude: /node_modules/,
			loader: 'babel-loader',
			query: {
				presets: ['es2015']
			}
		}, {
			test: /\.less$/,
			use: [{
				loader: 'css-loader'
			}, {
				loader: 'less-loader'
			}]
		}, {
			test: /\.(eot|svg|ttf|woff|woff2|png)(\?\S*)?$/,
			use: 'base64-inline-loader?limit=1000&name=[name].[ext]'
		}]
	},
	resolve: {
		extensions: ['.ts', '.js'],
		modules: ['node_modules', __dirname, __dirname + '/src'],
		alias: {
			'vue$': 'vue/dist/vue.common.js'
		}
	},
	optimization: {
		minimize: false
	},
	plugins: [
		new CheckerPlugin(),
		new webpack.DefinePlugin({
			'process.env': {
				NODE_ENV: JSON.stringify(process.env.NODE_ENV || 'development')
			},
			BUILD_TIMESTAMP: Math.floor(Date.now() / 1000),
			LIQUIO_URL: JSON.stringify(publicUrl),
			PUBLIC_URL: JSON.stringify(process.env.NODE_ENV === 'production' ? 'https://sign.liqu.io' : 'http://localhost:5000'),
			DEFAULT_WHITELIST_URL: JSON.stringify(process.env.NODE_ENV === 'production' ? 'https://sign.liqu.io/whitelist.html' : 'http://localhost:5000/whitelist.html'),
		}),
		new CopyWebpackPlugin([{ from: './static' }]),
		//new BundleAnalyzerPlugin()
	]
}

let config = Object.assign({}, baseConfig)
config.entry = {
	inject: './src/content.js'
}
config.plugins = config.plugins.concat([
	new webpack.DefinePlugin({
		IS_EXTENSION: JSON.stringify(false)
	})
])

let extensionConfig = Object.assign({}, baseConfig)
extensionConfig.entry = {
	background: './src/background.js',
	content: './src/content.js'
}
extensionConfig.plugins = extensionConfig.plugins.concat([
	new webpack.DefinePlugin({
		IS_EXTENSION: JSON.stringify(true)
	})
])

module.exports = [
	config,
	extensionConfig
]