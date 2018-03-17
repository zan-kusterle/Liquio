var path = require('path')
var CopyWebpackPlugin = require("copy-webpack-plugin")
var ServiceWorkerWebpackPlugin = require("serviceworker-webpack-plugin")
var ZipPlugin = require("zip-webpack-plugin")
var BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
var webpack = require("webpack")

let publicUrl = process.env.NODE_ENV === 'production' ? "https://liqu.io" : "http://localhost:4000"

module.exports = [{
    mode: 'development',
    entry: {
        background: './inject/background.js',
        content: './inject/main.js'
    },
    output: {
        path: path.resolve(__dirname, "../priv/static/extension"),
        filename: "[name].js",
        publicPath: publicUrl
    },
    devtool: process.env.NODE_ENV === 'production' ? false : 'inline-source-map',
    module: {
        rules: [{
            test: /\.vue$/,
            loader: "vue-loader"
        }, {
            test: /\.js$/,
            exclude: /node_modules/,
            loader: "babel-loader",
            query: {
                presets: ["es2015"]
            }
        }, {
            test: /\.less$/,
            use: [{
                loader: "css-loader"
            }, {
                loader: "less-loader"
            }]
        }, {
            test: /\.(eot|svg|ttf|woff|woff2)(\?\S*)?$/,
            use: 'base64-inline-loader?limit=1000&name=[name].[ext]'
        }]
    },
    resolve: {
        modules: ["node_modules", __dirname, __dirname + "/vue"],
        alias: {
            'vue$': 'vue/dist/vue.common.js'
        }
    },
    optimization: {
        minimize: process.env.NODE_ENV === 'production'
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
        new CopyWebpackPlugin([{ from: "./static/extension" }]),
        new ZipPlugin({
            filename: 'liquio.zip',
            pathPrefix: 'extension'
        })
    ]
},
{
    mode: 'development',
    entry: {
        'app/main.js': "./app/main.js",
        'app/main.css': './app/main.less',
        'inject.js': "./inject/main.js"
    },
    output: {
        path: __dirname + "/../priv/static",
        filename: "[name]"
    },
    devtool: process.env.NODE_ENV === 'production' ? false : 'eval',
    module: {
        rules: [{
            test: /\.vue$/,
            loader: "vue-loader"
        }, {
            test: /\.js$/,
            exclude: /node_modules|serviceworker\.js/,
            loader: "babel-loader",
            query: {
                presets: ["es2015"]
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
            use: [
                'style-loader',
                'css-loader'
            ]
        }, {
            test: /\.(eot|svg|ttf|woff|woff2)(\?\S*)?$/,
            loader: 'file-loader',
            query: {
                name: '/fonts/[name].[ext]?[hash]'
            }
        }, {
            test: /\.(png|jpe?g|gif|svg)(\?\S*)?$/,
            loader: 'file-loader',
            query: {
                name: '/images/[name].[ext]?[hash]'
            }
        }]
    },
    resolve: {
        modules: ["node_modules", __dirname, __dirname + "/vue", __dirname + "/app/vue"],
        alias: {
            'vue$': 'vue/dist/vue.common.js'
        }
    },
    optimization: {
        minimize: process.env.NODE_ENV === 'production'
    },
    plugins: [
        new webpack.DefinePlugin({
            'process.env': {
                NODE_ENV: JSON.stringify(process.env.NODE_ENV || 'development')
            },
            BUILD_TIMESTAMP: Math.floor(Date.now() / 1000),
            LIQUIO_URL: JSON.stringify(process.env.NODE_ENV === 'production' ? "https://liqu.io" : "http://localhost:4000"),
            IS_EXTENSION: JSON.stringify(false)            
        }),
        new CopyWebpackPlugin([{ from: "./static" }]),
        //new BundleAnalyzerPlugin()
    ]
}]
