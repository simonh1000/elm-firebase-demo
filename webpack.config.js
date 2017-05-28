const webpack = require('webpack');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var SWPrecacheWebpackPlugin = require('sw-precache-webpack-plugin');
var HTMLWebpackPlugin = require('html-webpack-plugin');
var merge = require('webpack-merge');
var path = require('path');

var elmSource = path.join(__dirname, 'src');

var TARGET_ENV = process.env.npm_lifecycle_event === 'build' ? 'production' : 'development';
var filename = (TARGET_ENV == 'production') ? '[name]-[hash].js' : 'index.js'

var common = {
    entry: './src/index.js',

    output: {
        path: path.join(__dirname, "dist"),
        filename: filename
    },
    plugins: [
        new HTMLWebpackPlugin({
            template: 'src/index.ejs',
            inject: 'body'
        })
    ],
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
                // Suggested for hot-loading
                new webpack.NamedModulesPlugin(),
                // Prevents compilation errors causing the hot loader to lose state
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
                            // add Elm's debug overlay to output
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
                    // serve images,...
                    app.get('/images/:fname', (req, res) => {
                        res.sendFile(path.join(__dirname, 'src/assets/images/', req.params.fname));
                    });
                    // Make fbsw.config.js available
                    app.get('/Firebase/:fname', (req, res) => {
                        console.log("Firebase directory", req.params.fname)
                        res.sendFile(path.join(__dirname, 'src/Firebase/', req.params.fname));
                    });
                    // catch certain calls for root level files and redirect to src/dist
                    app.get('/:rootFileName', (req, res, next) => {
                        if (['firebase-messaging-sw.js', 'sw.js', 'manifest.json'].includes(req.params.rootFileName)) {
                            console.log("redirecting:", req.params.rootFileName);
                            return res.sendFile(path.join(__dirname, 'src/dist/'+req.params.rootFileName));
                        }
                        next();
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
                new webpack.optimize.UglifyJsPlugin(),
                new SWPrecacheWebpackPlugin({
                    cacheId: 'presents',
                    filename: 'sw.js',
                    staticFileGlobs: [
                        "dist/index.*",
                        "dist/main*.js",
                        "dist/images/*.png"
                    ],
                    stripPrefix: 'dist/'
                })
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
