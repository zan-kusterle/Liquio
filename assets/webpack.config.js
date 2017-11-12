var ExtractTextPlugin = require("extract-text-webpack-plugin");
var CopyWebpackPlugin = require("copy-webpack-plugin");
var ServiceWorkerWebpackPlugin = require("serviceworker-webpack-plugin");
var webpack = require("webpack");

module.exports = {
    entry: {
        inject: "./inject/main.js",
        app: ["./css/app.less", "./js/app.js"]
    },
    output: {
        path: __dirname + "/../priv/static",
        filename: "[name].js"
    },
    devtool: process.env.NODE_ENV === 'production' ? false : 'eval',
    module: {
        loaders: [{
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
            loader: ExtractTextPlugin.extract({ fallback: "style-loader", use: "css-loader" })
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
        modules: ["node_modules", __dirname + "/js", __dirname + "/vue"],
        alias: {
            'vue$': 'vue/dist/vue.common.js',
            'inject': __dirname + '/inject'
        }
    },
    plugins: [
        new webpack.DefinePlugin({
            'process.env': {
                NODE_ENV: JSON.stringify(process.env.NODE_ENV || 'development')
            },
            BUILD_TIMESTAMP: Math.floor(Date.now() / 1000),
            LIQUIO_URL: JSON.stringify(process.env.NODE_ENV === 'production' ? "https://liqu.io" : "http://localhost:4000")            
        }),
        new ServiceWorkerWebpackPlugin({
            entry: __dirname + '/js/serviceworker.js',
            filename: 'serviceworker.js'
        }),
        new ExtractTextPlugin("css/app.css"),
        new CopyWebpackPlugin([{ from: "./static" }])
    ].concat(process.env.NODE_ENV === 'production' ? [
        new webpack.optimize.UglifyJsPlugin({ output: { comments: false } })
    ] : [])
};