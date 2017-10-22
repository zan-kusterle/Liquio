var ExtractTextPlugin = require("extract-text-webpack-plugin");
var CopyWebpackPlugin = require("copy-webpack-plugin");
var webpack = require("webpack");

module.exports = {
    entry: ["./src/main.js"],
    output: {
        path: __dirname,
        filename: "../static/inject.js"
    },
    module: {
        loaders: [{
            test: /\.js$/,
            loader: "babel-loader",
            query: {
                presets: ["es2015"]
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
        modules: ["node_modules", __dirname + "/src"]
    },
    plugins: [
        new webpack.DefinePlugin({
            'process.env': {
                NODE_ENV: JSON.stringify(process.env.NODE_ENV || 'development')
            },
            BUILD_TIMESTAMP: Math.floor(Date.now() / 1000),
            LIQUIO_URL: JSON.stringify(process.env.NODE_ENV === 'production' ? "https://liqu.io" : "http://localhost:4000")
        })
    ].concat(process.env.NODE_ENV === 'production' ? [
        new webpack.optimize.UglifyJsPlugin({ output: { comments: false } })
    ] : [])
};