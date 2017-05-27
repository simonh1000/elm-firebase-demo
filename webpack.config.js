const webpack = require('webpack');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var SWPrecacheWebpackPlugin = require('sw-precache-webpack-plugin');
var merge = require('webpack-merge');
var path = require('path');

var elmSource = path.join(__dirname, 'src');

var TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? 'production' : 'development';

var common = {
    entry: './src/index.js',

    output: {
        path: path.join(__dirname, "dist"),
        // filename: '[name]-[hash].js'
        filename: 'index.js'
    },

    resolve: {
        modules: [
            path.join(__dirname, "src"),
            "node_modules"
        ],
        extensions: ['.js', '.elm', '.scss']
    },
    module: {
        rules: [{
                test: /\.html$/,
                exclude: /node_modules/,
                loader: 'file-loader?name=[name].[ext]'
            },
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        // env: automatically determines the Babel plugins you need based on your supported environments
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
    }
}

if (TARGET_ENV === 'development') {
    console.log('Building for dev...');
    module.exports =
        merge(common, {
            plugins: [
                new webpack.NamedModulesPlugin(),
                new webpack.NoEmitOnErrorsPlugin()
            ],
            module: {
                rules: [{
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
                }]
            },
            devServer: {
                //   proxy: {
                //       "/": "http://localhost:9779"
                //   },
                inline: true,
                stats: 'errors-only',
                setup(app) {
                    // app.get('/firebase-messaging-sw.js', (req, res) => {
                    //     res.sendFile(path.join(__dirname, 'src/dist/firebase-messaging-sw.js'));
                    // })
                    // catch all calls for root level files and redirect to src/dist
                    // app.get('/index.js', (req, res) => {
                    //     res.sendFile(path.join(__dirname, 'src/index.js'));
                    // });
                    // serve images,...
                    app.get('/images/:fname', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/assets/images/', req.params.fname));
                    });
                    // Make fbsw.config.js available
                    app.get('/Firebase/:fname', (req, res) => {
                        conole.log("Firebase directory", req.params.fname)
                        res.sendFile(path.join(__dirname, 'src/Firebase/', req.params.fname));
                    })
                    app.get('/firebase-messaging-sw.js', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/dist/firebase-messaging-sw.js'));
                    });
                    app.get('/sw.js', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/dist/sw.js'));
                    });
                    app.get('/manifest.json', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/dist/manifest.json'));
                    });
                }
            }
        });
}

if (TARGET_ENV === 'production') {
    console.log('Building for prod...');
    module.exports =
        merge(common, {
            plugins: [
                new SWPrecacheWebpackPlugin({
                    cacheId: 'presents',
                    filename: 'sw.js',
                    staticFileGlobs: [
                        "dist/index.*",
                        "dist/images/*.png"
                    ],
                    stripPrefix: 'dist/'
                }),
                new CopyWebpackPlugin(
                    [{
                            from: 'src/assets/images',
                            to: 'images/'
                        },
                        {
                            from: 'src/dist'
                        },
                        {
                            from: 'src/Firebase/fbsw.config.js',
                            to: 'Firebase/[name].[ext]'
                        }
                    ]
                ),
                new webpack.optimize.UglifyJsPlugin()
            ],
            module: {
                rules: [{
                    test: /\.elm$/,
                    exclude: [/elm-stuff/, /node_modules/],
                    use: [{
                        loader: "elm-webpack-loader"
                    }]
                }]
            }
        });
}
