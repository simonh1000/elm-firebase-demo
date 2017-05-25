const webpack = require('webpack');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var path = require('path');

var elmSource = __dirname + '/src';

module.exports = {
    entry: './src/index.js',

    output: {
        path: path.join(__dirname, "dist"),
        filename: 'index.js'
    },

    resolve: {
        modules: [
            path.join(__dirname, "src"),
            "node_modules"
        ],
        extensions: ['.js', '.elm', '.scss']
    },
    plugins: [
        new webpack.NoEmitOnErrorsPlugin(),
        new CopyWebpackPlugin([{
            from: 'src/assets/',
            to: 'assets/'
        }])
    ],
    module: {
        rules: [{
                test: /\.html$/,
                exclude: /node_modules/,
                loader: 'file-loader?name=[name].[ext]'
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [{
                        loader: "elm-hot-loader"
                    },
                    {
                        loader: "elm-webpack-loader",
                        options: {
                            debug: true
                        }
                    }
                ]
            },
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['env']
                    }
                }
            }, {
                test: /\.scss$/,
                exclude: [/elm-stuff/, /node_modules/],
                loaders: ["style-loader", "css-loader", "sass-loader"]
            },
            {
                test: /\.css$/,
                exclude: [/elm-stuff/, /node_modules/],
                loaders: ["style-loader", "css-loader"]
            },
            // {
            //     test: /\.(jpg|png|gif|svg|ico)$/,
            //     exclude: [/elm-stuff/, /node_modules/],
            //     loaders: ["url-loader"]
            // },
            {
                test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "url-loader",
                options: {
                    limit: 10000,
                    mimetype: "application/font-woff"
                }
            },
            {
                test: /\.(ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
                exclude: [/elm-stuff/, /node_modules/],
                loader: "file-loader"
            }
        ]
    },

    devServer: {
        //   proxy: {
        //       "/": "http://localhost:9779"
        //   },
        inline: true,
        stats: 'errors-only',
        setup(app) {
			// firebase messaging script needs to be able to find this route
			app.get('/firebase-messaging-sw.js', (req, res) => {
				res.sendFile(path.join(__dirname, 'src/firebase-messaging-sw.js'));
			})
			app.get('/assets/:fname', (req, res) => {
				res.sendFile(path.join(__dirname, 'src/assets/', req.params.fname));
			})
		}
    }
};
