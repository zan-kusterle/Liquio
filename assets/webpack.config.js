/* eslint-disable */

var path = require('path')
var CopyWebpackPlugin = require('copy-webpack-plugin')
var webpack = require('webpack')

let publicUrl = process.env.NODE_ENV === 'production' ? 'https://liqu.io' : 'http://localhost:4000'

module.exports = {
	mode: 'development',
	entry: {
		background: './src/background.js',
		content: './src/main.js'
	},
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
		}, {
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
		modules: ['node_modules', __dirname, __dirname + '/src'],
		alias: {
			'vue$': 'vue/dist/vue.common.js'
		}
	},
	optimization: {
		minimize: false
	},
	plugins: [
		new webpack.DefinePlugin({
			'process.env': {
				NODE_ENV: JSON.stringify(process.env.NODE_ENV || 'development')
			},
			BUILD_TIMESTAMP: Math.floor(Date.now() / 1000),
			LIQUIO_URL: JSON.stringify(publicUrl),
			IS_EXTENSION: JSON.stringify(true)
		}),
		new CopyWebpackPlugin([{ from: './static' }]),
		//new BundleAnalyzerPlugin()
	]
}
